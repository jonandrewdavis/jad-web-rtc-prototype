extends CanvasLayer

class_name PlayerUI

@export var player: PlayerCharacter
@export_file var default_reticle

@onready var progress_bar = %Health

var RETICLE: Control

func _ready() -> void:
	if not is_multiplayer_authority():
		queue_free()
		return

	DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT

	%Menu.hide()

	if !player:
		player = get_parent()
	
	if default_reticle:
		change_reticle(default_reticle)

	player.health_system.max_health_updated.connect(_on_max_health_updated)
	player.health_system.health_updated.connect(_on_health_updated)
	player.health_system.hurt.connect(_on_hurt)
	
	%HurtTexture.hide()
	%HurtTexture.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	%HurtTimer.timeout.connect(_on_hurt_timer_timeout)

	%AimSlider.value_changed.connect(_on_aim_changed)
	%SenSlider.value_changed.connect(_on_sens_changed)

	await get_tree().create_timer(0.1).timeout
	%SenSlider.value = player.camHolder.XAxisSens
	%AimSlider.value = player.camHolder.aimFactor

	%Respawn.pressed.connect(func(): player.health_system.death.emit())
	%Disconnect.pressed.connect(_on_disconnect)
	%Quit.pressed.connect(func(): get_tree().quit())
	
	
	%ScoreTimer.timeout.connect(update_score)

func _process(_delta: float) -> void:
	if %Menu.visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		%Menu.hide()
	elif %Menu.visible == false and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		%Menu.show()

func _on_hurt():
	%HurtTexture.visible = true
	%HurtTimer.start()

func _on_hurt_timer_timeout():
	%HurtTexture.visible = false

func _on_health_updated(next_health):
	var current = progress_bar.get_current_value()
	if next_health < current:
		progress_bar.decrease_bar_value(current - next_health)
	else:
		var diff = next_health - current
		progress_bar.increase_bar_value(diff)

	%HealthBar.value = next_health

func _on_max_health_updated(new_max):
	progress_bar.set_max_value(new_max)
	progress_bar.set_bar_value(new_max)
	%HealthBar.max_value = new_max
	%HealthBar.value = new_max

func _on_update_ammo(ammo, ammo_reserve, _is_shooting):
	%AmmoLabel.text = str(ammo) + ' / ' + str(ammo_reserve)

func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()

	RETICLE = load(reticle).instantiate()
	RETICLE.character = player
	add_child(RETICLE)

func _on_sens_changed(new_value: float):
	player.camHolder.XAxisSens = new_value
	player.camHolder.YAxisSens = new_value
	%SenVal.text = str("%0.2f" % new_value)

func _on_aim_changed(new_value: float):
	player.camHolder.aimFactor = new_value
	%AimVal.text = str("%0.2f" % new_value)

func _on_disconnect():
	Hub.world.get_parent().show()
	Hub.world.queue_free()
	
func update_score():
	pass
	#var players = get_tree().get_nodes_in_group("Players")
	#for _player in players:
		##add_child()
		#print(_player.name)
