extends Node3D

var player_scene = preload("res://addons/fpc/character.tscn")

@export var player_container: Node3D

func _ready() -> void:
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	
	add_player_to_game(multiplayer.get_unique_id())

func RTCServerConnected():
	print("WORLD: rtc server connected")
	
func RTCPeerConnected(id: int):
	print("WORLD: rtc peer connected " + str(id))
	add_player_to_game(id)

func RTCPeerDisconnected(id):
	print("WORLD: rtc peer disconnected " + str(id))

func _process(_delta: float) -> void:
	pass

func add_player_to_game(id: int):
	var has_id = id in player_container.get_children().map(func(node): int(node.name))
	if has_id == true:
		return
		
	var player_to_add = player_scene.instantiate()
	player_to_add.name = str(id)
	player_to_add.position = Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 4
	player_container.add_child(player_to_add, true)

#func add_player_to_game(network_id: int):
	## NOTE: AD : removed
	##if is_multiplayer_authority(): 
	#print("Adding player to game: %s" % network_id)
#
	#if _players_in_game.get(network_id) == null:
		#var player_to_add = player_scene.instantiate()
#
		#ready_player(network_id, player_to_add)
#
		#_players_in_game[network_id] = player_to_add
		#player_to_add.position = 	Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 4
		#player_spawn_point.add_child(player_to_add)
	#else:
		#print("Warning! Attempted to add existing player to game: %s" % network_id)
#
func remove_player_from_game(id: int):
		var has_id = id in player_container.get_children().map(func(node): int(node.name))
		if has_id == true:
			return

		var player_to_remove = player_container.get_children().filter(func(node): int(node.name))
		if player_to_remove:
			player_to_remove.queue_free()

### Setup initial or reload saved player properties
#func ready_player(network_id: int, player: Player):
	## NOTE: AD Removed in mesh set up
	##if is_multiplayer_authority():
	#player.name = str(network_id)
#
	## Player is always owned by the server 
	## NOTE: NOT IN MESH MODE!! lol....
	#player.set_multiplayer_authority(network_id)
