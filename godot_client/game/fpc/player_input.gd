class_name PlayerInput
extends Node

@export var input_dir : Vector2
@export var is_jumping: bool = false
@export var is_sprinting: bool = false
@export var is_interacting: bool = false
@export var is_crouching: bool = false
@export var mouseInput : Vector2 = Vector2(0,0)

@export var is_weapon_up: bool = false
@export var is_weapon_down: bool = false
@export var is_weapon_shoot: bool = false
@export var is_weapon_melee: bool = false
@export var is_weapon_reload: bool = false
@export var is_weapon_aim: bool = false

@export var is_debug_b: bool = false

func _physics_process(_delta: float) -> void:
	input_dir = Input.get_vector("left", "right", "up", "down")
	is_jumping = Input.is_action_pressed("jump")
	is_sprinting = Input.is_action_pressed("sprint")
	is_interacting = Input.is_action_pressed("interact")
	is_crouching = Input.is_action_pressed("crouch")
	
	is_weapon_up = Input.is_action_pressed("weapon_up")
	is_weapon_down = Input.is_action_pressed("weapon_down")
	is_weapon_shoot = Input.is_action_pressed("weapon_shoot")
	is_weapon_melee = Input.is_action_pressed("weapon_melee")
	is_weapon_reload = Input.is_action_pressed("weapon_reload")
	is_weapon_aim = Input.is_action_pressed("weapon_aim")
	
	is_debug_b = Input.is_action_pressed("debug_b")
	
	if Input.is_action_pressed("weapon_shoot") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y
