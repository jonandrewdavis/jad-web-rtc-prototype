class_name web_rtc_network 
extends BADNetwork

const DEFAULT_PORT = 8080


# TODO: Figure out how to get rpcPeer in here from the Lobby.... kinda can't .new() in here... but can do some other stuff...

func create_server_peer(_network_connection_configs: BADNetworkConnectionConfigs):
	#print('DEBUG: BAD HOSTING:', _network_connection_configs)
	#var rtc_peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	#rtc_peer.create_server()
	#get_tree().get_multiplayer().multiplayer_peer = rtc_peer
	return OK

func create_client_peer(_network_connection_configs: BADNetworkConnectionConfigs):
	#var rtc_peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
	#rtc_peer.create_client(multiplayer.get_unique_id())
	#get_tree().get_multiplayer().multiplayer_peer = rtc_peer
	return OK

func get_port():
	return -1

func terminate_connection():
	pass
