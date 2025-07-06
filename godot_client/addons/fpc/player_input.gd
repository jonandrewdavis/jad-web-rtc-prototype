class_name PlayerInput
extends Node

@export var input_dir : Vector2
@export var is_jumping: bool = false
@export var mouseInput : Vector2 = Vector2(0,0)

func _physics_process(_delta: float) -> void:
	if get_tree().get_multiplayer().multiplayer_peer != null && is_multiplayer_authority():
		input_dir = Input.get_vector("left", "right", "up", "down")
		is_jumping = Input.is_action_pressed("jump")

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y
	# Toggle debug menu
	elif event is InputEventKey:
		if event.is_released():
			# Where we're going, we don't need InputMap
			if event.keycode == 4194338: # F7
				$UserInterface/DebugPanel.visible = !$UserInterface/DebugPanel.visible
