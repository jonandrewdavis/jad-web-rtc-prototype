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
	player.set_collision_layer_value(1, false)
	player.set_collision_layer_value(16, true)
	player.master.bones.physical_bones_start_simulation()
	player.master.animation_player.active = false
	#player.master.%a
	#player.hide()
	player.immobile = true
	await get_tree().create_timer(10.0).timeout
	_respawn()
	
func _respawn():
	player.set_collision_layer_value(1, true)
	player.set_collision_layer_value(16, false)
	player.master.bones.physical_bones_stop_simulation()
	player.master.animation_player.active = true

	health_system.heal(health_system.max_health)
	player.immobile = false
	player.show()
	player.position = Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 8
