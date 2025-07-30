extends Node

var player: Player
var health_system: HealthSystem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent()
	player.add_to_group("targets")
	
	health_system = player.get_node('HealthSystem')
	health_system.death.connect(_on_death)	
	
func _on_death():
	player.hide()
	player.immobile = true
	await get_tree().create_timer(2.0).timeout
	_respawn()
	
func _respawn():
	health_system.heal(health_system.max_health)
	player.immobile = false
	player.show()
	player.position = Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 8
