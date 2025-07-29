extends Node
class_name HealthSystem

signal hurt
signal health_updated
signal max_health_updated
signal death

# TODO: HealthBars, do we want them to show on enemies? 
# Helldivers 2 does not, but there are other indicators (bleeding, fatigue)
# On a related note, could show small white damage numbers too...

# TODO: could emit "MAJOR HURT" and "MINOR HURT" that the parent could react to

@export var max_health : int = 100
@export var health : int = 100

# TODO: Shield system? Halo / Apex, etc? Seperate from Health?
# NOTE: Halo 1's shield regen is about 5 seconds
@export var regen_enabled: bool = true
@export var regen_delay: float = 5.5 # Halo 1
@export var regen_speed: float = 0.15
@export var regen_increment: int = 2

@onready var regen_timer: Timer = Timer.new()
@onready var regen_tick_timer: Timer = Timer.new()

var last_damage_source := 0

# NOTE: If used, could be overriden to be the parent's sync, reducing # of syncronizers
#@onready var sync = $MultiplayerSynchronizer

func _ready() -> void:
	# NOTE: Changed from `is_server()` to `is_multiplayer_authority`y.
	# NOTE: Added health to syncronizer to display to other clients (for health bars to be visible) 

	if is_multiplayer_authority():
		prepare_regen_timer()
		max_health_updated.emit(max_health)
		heal(max_health)

func damage(value: int, source: int = 0) -> bool:
	# Don't allow negative values when damaging
	var next_health = health - abs(value)

	if allow_damage_from_source(source) == false:
		return false

	# Do not allow damage when dead.
	if health == 0:
		return false
	
	# Do not allow overkill. Just die.
	# TODO: Clamp is easier right? Might work here
	if next_health <= 0:
		regen_timer.stop()
		health = 0
		last_damage_source = source
		rpc_update_health.rpc(0)
		hurt.emit()
		death.emit()
		return true
	
	# Valid damage, not dead
	last_damage_source = source
	rpc_update_health.rpc(next_health)
	hurt.emit()

	return true

# Use call_local because heals originate from the local player
# Use any_peer, because damage can come from anywhere. 
@rpc('call_local', 'any_peer')
func rpc_update_health(next_health):
	if is_multiplayer_authority():
		# TODO: Sometimes this prints twice with the same value. It functions, but why? Local bullets hitting at the same time??
		#print('DEBUG: Authourized damage to update: ', next_health)

		# Damage
		if next_health < health and regen_enabled:
			hurt.emit()
			regen_timer.start()
	
		# Death
		if next_health == 0:
			death.emit()

		health = next_health
		health_updated.emit(next_health)


func allow_damage_from_source(_source: int):
	# TODO: More rules. Teams?
	
	# NOTE: Prevent self damage
	if is_multiplayer_authority() and get_multiplayer_authority() == _source:
		return false
		
	return true

func heal(value):

	var next_health = health + abs(value)
	
	# Do not allow overheal
	if next_health > max_health:
		next_health = max_health

	rpc_update_health.rpc(next_health)

func prepare_regen_timer():
	add_child(regen_timer)
	regen_timer.wait_time = regen_delay
	regen_timer.one_shot = true
	regen_timer.timeout.connect(start_regen_health)

	add_child(regen_tick_timer)
	regen_tick_timer.wait_time = regen_speed # regen_speed?
	regen_tick_timer.timeout.connect(regen_health_tick)

func start_regen_health():
	if regen_timer.is_stopped() && health < max_health:
		# "Clears" damage from players
		last_damage_source = 0
		regen_tick_timer.start()

func regen_health_tick():
	if regen_timer.is_stopped() && health < max_health:
		heal(regen_increment)
		regen_tick_timer.start()
	else:
		regen_tick_timer.stop()
