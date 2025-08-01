extends CanvasLayer

class_name PlayerUI

@export var player: Player
@export_file var default_reticle

var RETICLE: Control

func _ready() -> void:
	if !player:
		player = get_parent()
	
	if default_reticle:
		change_reticle(default_reticle)

	player.weapon_manager.update_ammo_signal.connect(_on_update_ammo)
	player.health_system.health_updated.connect(_on_health_updated)
	player.health_system.hurt.connect(_on_hurt)
	
	%HurtTexture.hide()
	%HurtTexture.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	%HurtTimer.timeout.connect(_on_hurt_timer_timeout)

func _on_hurt():
	%HurtTexture.visible = true
	%HurtTimer.start()

func _on_hurt_timer_timeout():
	%HurtTexture.visible = false

func _on_health_updated(next_health):
	%HealthBar.value = next_health

func _on_update_ammo(ammo, ammo_reserve, _is_shooting):
	%AmmoLabel.text = str(ammo) + ' / ' + str(ammo_reserve)

func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()

	RETICLE = load(reticle).instantiate()
	RETICLE.character = player
	add_child(RETICLE)
