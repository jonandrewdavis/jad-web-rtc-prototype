extends Node

var lobby_menu: LobbyMenu
var world: Node3D
var projectile_system: ProjectileSystem
var players = {}



signal hit
signal world_loaded
signal score_updated

func _ready(): 
	# source is player who last damaged
	score_updated.connect(func(source): on_score_updated.rpc(source))

@rpc("any_peer", 'call_local')
func on_score_updated(source):
	players[source].score = players[source].score + 1
