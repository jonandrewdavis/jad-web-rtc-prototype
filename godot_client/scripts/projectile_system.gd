extends Node
class_name ProjectileSystem

@export var container: Node3D
@export var spawner: MultiplayerSpawner

func _ready():
	Hub.projectile_system = self
