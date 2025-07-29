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
	player_to_add.position = Vector3(randi_range(-2, 2), 0.8, randi_range(-2, 2)) * 5
	player_container.add_child(player_to_add, true)

func remove_player_from_game(id: int):
		var has_id = id in player_container.get_children().map(func(node): int(node.name))
		if has_id == true:
			return

		var player_to_remove = player_container.get_children().filter(func(node): int(node.name))
		if player_to_remove:
			player_to_remove.queue_free()
