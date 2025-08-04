extends Node3D

var listSpawners : Array[Node3D] = []
var rng = RandomNumberGenerator.new()

@onready var playChar: PlayerCharacter

func _ready():
	pass
	#setSpawnerList()
	#setPlayCharSpawner()
	
func setSpawnerList():
	for spawner in get_children(): listSpawners.append(spawner)
	
func setPlayCharSpawner():
	if playChar != null: 
		#set play char position at a spawner point randomly chosen
		playChar.global_position = listSpawners[rng.randf_range(0, listSpawners.size())].global_position
	
func respawn():
	setPlayCharSpawner()
	
	

		
