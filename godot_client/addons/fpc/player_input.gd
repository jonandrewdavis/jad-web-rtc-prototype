class_name PlayerInput
extends Node

@export var input_dir : Vector2
@export var is_jumping: bool = false
@export var is_sprinting: bool = false
@export var is_interacting: bool = false
@export var mouseInput : Vector2 = Vector2(0,0)

@export var is_weapon_up: bool = false
@export var is_weapon_down: bool = false
@export var is_weapon_shoot: bool = false
@export var is_weapon_melee: bool = false
@export var is_weapon_reload: bool = false
@export var is_weapon_aim: bool = false

func _physics_process(_delta: float) -> void:
	if get_tree().get_multiplayer().multiplayer_peer != null && is_multiplayer_authority():
		input_dir = Input.get_vector("left", "right", "up", "down")
		is_jumping = Input.is_action_pressed("jump")
		is_sprinting = Input.is_action_pressed("sprint")
		is_interacting = Input.is_action_pressed("interact")
		
		is_weapon_up = Input.is_action_pressed("weapon_up")
		is_weapon_down = Input.is_action_pressed("weapon_down")
		is_weapon_shoot = Input.is_action_pressed("weapon_shoot")
		is_weapon_melee = Input.is_action_pressed("weapon_melee")
		is_weapon_reload = Input.is_action_pressed("weapon_reload")
		is_weapon_aim = Input.is_action_pressed("weapon_aim")

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y
#
#func _unhandled_input(event : InputEvent):
	#if get_tree().get_multiplayer().multiplayer_peer != null && is_multiplayer_authority():
		#if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			#mouseInput.x += event.relative.x
			#mouseInput.y += event.relative.y
		## Toggle debug menu
		#elif event is InputEventKey:
			#if event.is_released():
				## Where we're going, we don't need InputMap
				#if event.keycode == 4194338: # F7
					#$UserInterface/DebugPanel.visible = !$UserInterface/DebugPanel.visible
