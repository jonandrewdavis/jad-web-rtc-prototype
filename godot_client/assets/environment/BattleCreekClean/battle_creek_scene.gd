extends Node3D


func _ready() -> void:
	$StaticBody3D.set_collision_layer_value(1, true)
	$StaticBody3D.set_collision_layer_value(4, true)
	$StaticBody3D.set_collision_layer_value(16, true)
