# TODO: Move these out of weapon manager & into a Projectile System folder
# TODO: OR - move THIS file into a restructed weapon manager area
# TODO: Refactor Projectile "Server" & Weapons Manager together

extends Node
class_name ProjectileSystem

@export var container: Node3D
@export var spawner: MultiplayerSpawner

signal hit_signal

# CRITICAL: These properties should be set for the RigidBody3D 
	#_new_bullet.gravity_scale = 0.0
	#_new_bullet.set_collision_mask(00000000_00000000_00000000_00000000)
	#_new_bullet.set_collision_layer(00000000_00000000_00000000_00000111)
	#_new_bullet.continuous_cd = true
	#_new_bullet.contact_monitor = true
	#_new_bullet.max_contacts_reported = 5
var rifle_round = preload("res://game/weapon_manager/Spawnable_Objects/bullet_scenes/rifle_round.tscn")
var orange_bullet = preload("res://game/weapon_manager/Spawnable_Objects/bullet_scenes/orange_bullet.tscn")
var pink_bullet = preload("res://game/weapon_manager/Spawnable_Objects/bullet_scenes/pink_bullet.tscn")
var rifle_round_decal = preload("res://game/weapon_manager/Spawnable_Objects/bullet_scenes/rifle_round_decal.tscn")

var bullet_list = [orange_bullet, rifle_round, pink_bullet, rifle_round_decal]


# TODO: I do not understand the spawner for mesh set up.
func _ready():
	for bullet in bullet_list:
		spawner.add_spawnable_scene(bullet.get_state().get_path())

	spawner.set_spawn_function(handle_projectile_spawn)

#var projectile_data = { 
	# projectile_name: string 
	#'origin_point': origin_point,
	#'target_point': point,
	#'projectile_velocity': Projectile_Velocity,
	#'normal': norm,
	#'damage': damage,
	#'source': source
#}
func handle_projectile_spawn(data: Variant):
	if data.projectile_name == 'rifle_round_decal':
		var _new_decal = rifle_round_decal.instantiate()
		_new_decal.set_multiplayer_authority(multiplayer.get_remote_sender_id())
		_new_decal.position = data.origin_point
		_new_decal.tree_entered.connect(_on_tree_entered.bind(_new_decal))
		if data.normal.y == 1.0:
			_new_decal.axis = 1
		
		return _new_decal

	# TODO: these 'PinkBullet' string names shoudl match... and be pulled from Resources. loaded...
	var _new_bullet: RigidBody3D 
	match data.projectile_name:
		'PinkBullet':
			_new_bullet = pink_bullet.instantiate()
		'OrangeBullet':
			_new_bullet = orange_bullet.instantiate()
		'RifleRound':
			_new_bullet = rifle_round.instantiate()
		'RigidBodyProjectile':
			_new_bullet = rifle_round.instantiate()

	# CRITICAL
	_new_bullet.set_multiplayer_authority(multiplayer.get_remote_sender_id())
	_new_bullet.position = data.origin_point

	_new_bullet.look_at_from_position(data.origin_point, data.target_point, Vector3.UP)	
	var _direction = (data.target_point - data.origin_point).normalized()
	_new_bullet.set_linear_velocity(_direction * data.projectile_velocity)
	_new_bullet.body_entered.connect(_on_body_entered.bind(_new_bullet, data))
	_new_bullet.tree_entered.connect(_on_tree_entered.bind(_new_bullet))
	# TODO: Can potentially use on `body_shape_entered` or areas for crit damage.
	#_new_bullet.body_shape_entered.connect(_on_body_shape_entered.bind(_new_bullet, data))
		
	return _new_bullet

func _on_body_entered(body, _bullet, data):
	if body.is_in_group("targets"):
		var heath_system: HealthSystem = body.get_node('HealthSystem')
		var damage_successful = heath_system.damage(data.damage, data.source)
		if damage_successful:
			hit_signal.emit(data.source)

	if data.normal and is_multiplayer_authority():
		spawner.spawn({ 
			'projectile_name': 'rifle_round_decal',
			'origin_point': _bullet.get_position(),
			'normal': data.normal,
			'source': data.source
		})

	if is_multiplayer_authority():
		_bullet.queue_free()
	
#func _on_body_shape_entered(_body_rid: RID, _body: Node, _body_shape_index: int, _local_shape_index: int, _bullet, data):
	#print(_body)
	
func _on_tree_entered(_bullet):
	await get_tree().create_timer(3.5).timeout
	if _bullet and is_multiplayer_authority():
		_bullet.queue_free()
