extends Node
class_name ProjectileSystem

@export var container: Node3D
@export var spawner: MultiplayerSpawner

@onready var bulletDecal : PackedScene = preload("res://game/Weapons/Scenes/BulletDecalScene.tscn")
@onready var Rocket: PackedScene = preload("res://game/Weapons/Scenes/RocketScene.tscn")
@onready var RifleRound: PackedScene = preload("res://game/Weapons/Scenes/RifleRound.tscn")

func _ready():
	Hub.projectile_system = self
	
	# NOTE: Since we're using RPCs, now each client just adds. No spawner needed. Interesting.
	#var SPAWNABLES = [bulletDecal]
	#for item in SPAWNABLES:
		#spawner.add_spawnable_scene(item.get_state().get_path())

@rpc('any_peer', 'call_local')
func add_new_decal(colliderPoint : Vector3, colliderNormal : Vector3):
	if colliderNormal == Vector3.ZERO:
		return
		
	var bulletDecalInstance = bulletDecal.instantiate()
	bulletDecalInstance.position = colliderPoint + (Vector3(colliderNormal) * 0.001)
	container.add_child(bulletDecalInstance)
	
	if !colliderNormal.is_equal_approx(Vector3.UP):
		bulletDecalInstance.look_at(colliderPoint - colliderNormal  * 0.01, Vector3.UP)
		bulletDecalInstance.get_node('Sprite3D').axis = 2
	else:
		bulletDecalInstance.get_node('Sprite3D').axis = 1


# TODO: type
# TODO: spawn function.... but it doesn't work in mesh mode that I know of
# TODO: Packedbye array

@rpc('any_peer', 'call_local')
func add_new_projectile(cWArray, projectileDirection, projInstanceName, normal, source = 1):
	var projInstance
	match projInstanceName:
		'Rocket':
			projInstance = Rocket.instantiate()
		'RifleRound':
			projInstance = RifleRound.instantiate()
		
	if !projInstance:
		return

	projInstance.global_transform = cWArray[0]
	projInstance.damage = cWArray[1]
	projInstance.timeBeforeVanish = cWArray[2]
	#projInstance.gravity_scale = cWArray[3]
	projInstance.isExplosive = cWArray[4]

	projInstance.direction = projectileDirection
	projInstance.normal = normal
	projInstance.source = source
	
	projInstance.scale = Vector3.ONE
	
	container.add_child(projInstance)
	projInstance.set_linear_velocity(projectileDirection * cWArray[5])

func add_new_projectile_preload():
	# TODO: iterate over all possible
	await get_tree().create_timer(0.2).timeout

	var projInstance1 = Rocket.instantiate()
	var projInstance2 = RifleRound.instantiate()
	projInstance1.position = Vector3.ONE * -20.0

	add_new_decal.rpc(Vector3.ZERO, Vector3.UP)	
	container.call_deferred('add_child', projInstance1, true)
	container.call_deferred('add_child', projInstance2, true)
	await get_tree().create_timer(0.2).timeout
	projInstance1.explode()
	await get_tree().create_timer(1.0).timeout
	for item in container.get_children():
		item.queue_free()
