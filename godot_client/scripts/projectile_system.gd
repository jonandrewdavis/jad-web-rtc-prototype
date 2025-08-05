extends Node
class_name ProjectileSystem

@export var container: Node3D
@export var spawner: MultiplayerSpawner

@onready var bulletDecal : PackedScene = preload("res://addons/Weapons/Scenes/BulletDecalScene.tscn")
@onready var Rocket: PackedScene = preload("res://addons/Weapons/Scenes/RocketScene.tscn")


func _ready():
	Hub.projectile_system = self
	
	# NOTE: Since we're using RPCs, now each client just adds. No spawner needed. Interesting.
	
	#var SPAWNABLES = [bulletDecal]
	#for item in SPAWNABLES:
		#spawner.add_spawnable_scene(item.get_state().get_path())

@rpc('any_peer', 'call_local')
func add_new_decal(colliderPoint : Vector3, colliderNormal : Vector3):	
	var bulletDecalInstance = bulletDecal.instantiate()
	container.add_child(bulletDecalInstance)
	bulletDecalInstance.global_position = colliderPoint + (Vector3(colliderNormal) * 0.001)
	if !colliderNormal.is_equal_approx(Vector3.UP):
		bulletDecalInstance.look_at(colliderPoint - colliderNormal  * 0.01, Vector3.UP)
		bulletDecalInstance.get_node('Sprite3D').axis = 2
	else:
		bulletDecalInstance.get_node('Sprite3D').axis = 1

# TODO: type
# TODO: spawn function.... but it doesn't work in mesh mode that I know of

# TODO: Packedbye array

@rpc('any_peer', 'call_local')
func add_new_projectile(cWArray, projectileDirection, projInstanceName):
	#set projectile properties 

	var projInstance
	match projInstanceName:
		'Rocket':
			projInstance = Rocket.instantiate()

	projInstance.global_transform = cWArray[0]
	projInstance.damage = cWArray[1]
	projInstance.timeBeforeVanish = cWArray[2]
	projInstance.gravity_scale = cWArray[3]
	projInstance.isExplosive = cWArray[4]

	projInstance.direction = projectileDirection
	
	container.add_child(projInstance)
	projInstance.set_linear_velocity(projectileDirection * cWArray[5])
