class_name web_rtc_network 
extends BADNetwork

const DEFAULT_PORT = 8080

func create_server_peer(_network_connection_configs: BADNetworkConnectionConfigs):
	return OK

func create_client_peer(_network_connection_configs: BADNetworkConnectionConfigs):
	return OK

func get_port():
	return -1

func terminate_connection():
	pass
