extends CharacterBody3D

class_name ShootingRangeTarget

var canDisplayDamageNumber : bool = true
@export var health : float = 100.0
var healthRef : float
var isDisabled : bool = false

@onready var animManager : AnimationPlayer = $AnimationPlayer
@onready var damNumSpawnPoint : Marker3D = $DamageNumberSpawnPoint

func _ready():
	healthRef = health
	animManager.play("idle")
	await get_tree().create_timer(0.5).timeout
	DamageNumberScript.displayNumber(10.0, Vector3.ONE, 110, DamageNumberScript.DamageType.NORMAL)
	
func hitscanHit(damageVal : float, _hitscanDir : Vector3, _hitscanPos : Vector3, _source: int = 1):
	#health -= damageVal

	#About the display of damage number, there are some tremendous errors with it, that i don't understand, and i didn't manage to resolve it, so i've put an option to disable it, so that you don't see theses errors (which don't affect gameplay in any way, i might add, but i preferred to add an option to not trigger them).
	if !isDisabled and canDisplayDamageNumber:
		DamageNumberScript.displayNumber(damageVal, damNumSpawnPoint.global_position, 130, DamageNumberScript.DamageType.NORMAL)
		Hub.hit.emit()
	#if health <= 0.0:
		#isDisabled = true
		#animManager.play("fall")
		
func projectileHit(damageVal : float, _hitscanDir : Vector3, _source: int = 1):
	health -= damageVal
	
	if !isDisabled and canDisplayDamageNumber:
		DamageNumberScript.displayNumber(damageVal, damNumSpawnPoint.global_position, 130, DamageNumberScript.DamageType.NORMAL)
		Hub.hit.emit()

	#if health <= 0.0:
		#isDisabled = true
		#animManager.play("fall")
		
		
		
