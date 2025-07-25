class_name LobbyMenu
extends CanvasLayer

@onready var LobbyItemScene: PackedScene = preload("res://menus/lobby_menu/lobby_list_item.tscn") 

const WEB_SOCKET_SECRET_KEY = "9317e4d6-83b3-4188-94c4-353a2798d3c1"

# Change to your server url, currently set to the localhost
const WEB_SOCKET_SERVER_URL = 'ws://localhost:8787'
#const WEB_SOCKET_SERVER_URL = 'ws-lobby-worker.jonandrewdavis.workers.dev'

var current_username : String = ""
var _client : WebSocketPeer
var webRTCPeer : WebRTCMultiplayerPeer

var current_web_id: int 
var is_lobby_host = false
#var lobby_data = null # Not used

var timer_heartbeat = Timer.new()
var timer_heartbeat_light = Timer.new()

# TODO: Parse for alpha chars
var username_input = ''
var connection_validated = false

#region Signals
signal signal_connection_confirmed(webId: String)
signal signal_disconnect
signal signal_message(text)
signal signal_heartbeat

signal signal_update_user_list(users)
signal signal_player_join(id)
signal signal_player_left(webId)

signal signal_lobby_updated(lobbies) # NOTE: These types don't carry over?
signal signal_lobby_created()
signal signal_lobby_joined()
signal signal_left_lobby()
signal signal_lobby_message
signal signal_lobby_game_started
#signal signal_lobby_get(lobby) # NOT USED

# NOTE: The server will send WebRTC candidates, offers, and answers through this signal
signal signal_new_rtc_peer_connection(id: String)

#endregion


#region Actions
# ACTIONS
const Action_Connect = "Connect"
const Action_GetUsers = "GetUsers"
const Action_PlayerJoin = "PlayerJoin"
const Action_PlayerLeft = "PlayerLeft"
const Action_GetLobbies = "GetLobbies"
const Action_GetOwnLobby = "GetOwnLobby"
const Action_CreateLobby = "CreateLobby"
const Action_JoinLobby = "JoinLobby"
const Action_LeaveLobby = "LeaveLobby"
const Action_LobbyChanged = "LobbyChanged"
const Action_GetUsersInLobby = "GetUsersInLobby"
const Action_MapSelected = "MapSelected"
const Action_GameStarted = "GameStarted"
const Action_MessageToLobby = "MessageToLobby"
const Action_Heartbeat = "Heartbeat"

# WebRTC Actions: 
const Action_NewPeerConnection = "NewPeerConnection"
const Action_Offer = "Offer"
const Action_Answer = "Answer"
const Action_Candidate = "Candidate"
#endregion

func _ready():
	set_process(false)	
	ready_required_connections()
	ready_input_connections()
	ready_render_connections()
	ready_timers()

func ready_required_connections():
	signal_connection_confirmed.emit(_on_ws_connection_confirmed)
	signal_disconnect.connect(_on_ws_disconnect)
	signal_lobby_game_started.connect(_on_game_started)
	tree_exited.connect(_close_ws_connection)

func _on_ws_connection_confirmed(webId: int):
	connection_validated = true
	current_web_id = webId
	send_message_get_lobbies()

func _on_ws_disconnect():
	connection_validated = false
	set_process(false)

func _close_ws_connection():
	if _is_web_socket_connected():
		_client.close(1000, 'User closed the app')

func _on_game_started():
	webRTCPeer = WebRTCMultiplayerPeer.new()
	# Currently, we are using `create_mesh`, but we may want server authority.
	webRTCPeer.create_mesh(current_web_id)
	multiplayer.multiplayer_peer = webRTCPeer	
	
	var configs = BADNetworkConnectionConfigs.new(BADMP.AvailableNetworks.WEB_RTC, '')
	BADMP.join_game(configs)
	hide()

func ready_input_connections():
	%UsernameInput.text_changed.connect(func (text): username_input = text)
	%LobbyServerConnect.pressed.connect(func (): connect_to_server())
	%LobbyServerDisconnect.pressed.connect(on_disconnect_button_pressed)
	%LobbyCreate.pressed.connect(func (): send_message_create_lobby())
	%LobbyInput.text_submitted.connect(send_message_to_lobby)
	%LobbyInputSend.pressed.connect(func (): send_message_to_lobby(%LobbyInput.text))
	%QuickJoin.pressed.connect(quick_join)

func ready_render_connections():
	signal_connection_confirmed.connect(render_connection_confirmed)
	signal_disconnect.connect(render_web_socket_disconnect)
	signal_update_user_list.connect(render_user_list)
	signal_player_left.connect(render_remove_user_from_list)
	signal_message.connect(render_data_recieved_debug)
	signal_lobby_updated.connect(render_lobby_list)
	signal_left_lobby.connect(render_left_lobby)
	signal_lobby_message.connect(render_lobby_message)
	# NOTE: The server will send a candidate, offer, and answer for each peer in the lobby
	signal_new_rtc_peer_connection.connect(create_multiplayer_peer_connection)

func ready_timers():
	timer_heartbeat.one_shot = false
	timer_heartbeat.wait_time = 1.0
	timer_heartbeat.timeout.connect(send_message_heartbeat)
	add_child(timer_heartbeat)
	
	timer_heartbeat_light.one_shot = false
	timer_heartbeat_light.wait_time = 0.1
	timer_heartbeat_light.timeout.connect(on_heartbeat_light)
	add_child(timer_heartbeat_light)

func _process(_delta):
	_client.poll()
	var state: WebSocketPeer.State = _client.get_ready_state()
	match state:
		WebSocketPeer.STATE_CONNECTING:
			return
		WebSocketPeer.STATE_OPEN:
			# TODO: Improve this step
			if connection_validated == false:
				send_message_confirm_connection(current_username)
				connection_validated = true
				return
			while _client.get_available_packet_count():
				data_received()
		WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = _client.get_close_code()
			var reason = _client.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			signal_disconnect.emit()

func connect_to_server():
	# If the connect button is clicked while we're connecting, close instead
	if _is_web_socket_connected() || _is_web_socket_connecting():
		_client.close()
	
	current_username = get_username_input()
	_client = WebSocketPeer.new()	
	_client.connect_to_url(WEB_SOCKET_SERVER_URL)
	set_process(true)
	
	await get_tree().create_timer(2.0).timeout
	
	if !(_is_web_socket_connected()):
		_client.close()

func data_received():
	var packet = _client.get_packet().get_string_from_utf8()
	var packet_to_json = JSON.parse_string(packet)
	if packet_to_json and packet_to_json.has('action') and packet_to_json.has('payload'):
		parse_message_from_server(packet_to_json)
		signal_message.emit(packet)
	else:
		signal_message.emit("Invalid message received")
		push_warning("Invalid message received")


func parse_message_from_server(message):
	match(message.action):
		Action_Connect:
			if  message.payload.has("webId"):
				signal_connection_confirmed.emit(message.payload.webId)
			else:
				_client.disconnect_from_host(1000, "Couldn't authenticate")
		Action_GetUsers:
			if message.payload.has("users"):
				signal_update_user_list.emit(message.payload.users)
			else:
				signal_update_user_list.emit([])
		Action_GetLobbies:
			if message.payload.has("lobbies"):
				signal_lobby_updated.emit(message.payload.lobbies)
		#Action_GetOwnLobby:
			#if message.payload.has("lobby"):
				#signal_lobby_get_own.emit(message.payload.lobby)
		Action_PlayerJoin:
			if message.payload.has("id"):
				signal_player_join.emit(message.payload.id)
		Action_PlayerLeft:
			if message.payload.has("webId"):
				signal_player_left.emit(message.payload.webId)
		Action_CreateLobby:
			signal_lobby_created.emit()
			is_lobby_host = true
		Action_JoinLobby:
			signal_lobby_joined.emit()
		Action_LeaveLobby:
			signal_left_lobby.emit()
			is_lobby_host = false
		#Action_LobbyChanged:
			#if json_message.payload.has("lobby"):
				#signal_lobby_changed.emit(json_message.payload.lobby)
				#lobby_data = json_message.payload.lobby
		Action_Heartbeat:
			signal_heartbeat.emit()
		Action_GameStarted:
			signal_lobby_game_started.emit()
		Action_NewPeerConnection:
			# NOTE: This signal kicks of the WebRTC negotiation process
			signal_new_rtc_peer_connection.emit(message.payload.id)
			# TODO: Action, Offer, Answer are largely untyped, can we improve the types?
		Action_Offer:
			webRTCPeer.get_peer(message.payload.orgPeer).connection.set_remote_description("offer", message.payload.data)
		Action_Answer:
			webRTCPeer.get_peer(message.payload.orgPeer).connection.set_remote_description("answer", message.payload.data)
		Action_Candidate:
			var data = message.payload
			#print("Got Candididate: " + str(data.orgPeer) + " my id is " + str(current_web_id))
			webRTCPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
		Action_MessageToLobby:
			if message.payload.has("message_text"):
				signal_lobby_message.emit(message.payload)

func _send_message(action : String, payload : Dictionary):
	if _is_web_socket_connected():
		var message = {
			"action": action,
			"payload": payload
		}
		var parsed_message = JSON.stringify(message)
		_client.put_packet(parsed_message.to_utf8_buffer())

func _is_web_socket_connected() -> bool:
	if _client:
		return _client.get_ready_state() == WebSocketPeer.STATE_OPEN
	return false

func _is_web_socket_connecting() -> bool:
	if _client:
		return _client.get_ready_state() == WebSocketPeer.STATE_CONNECTING
	return false 

func send_message_confirm_connection(username : String):
	if _is_web_socket_connected():
		_send_message(Action_Connect, {"secretKey" : WEB_SOCKET_SECRET_KEY, "username" : username})

func send_message_get_users():
	if _is_web_socket_connected():
		_send_message(Action_GetUsers,  {})

func send_message_get_lobbies():
	if _is_web_socket_connected():
		_send_message(Action_GetLobbies, {})

func send_message_get_own_lobby():
	if _is_web_socket_connected():
		_send_message(Action_GetOwnLobby, {})

func send_message_create_lobby():
	if _is_web_socket_connected():
		_send_message(Action_CreateLobby, {})

func send_message_join_lobby(idLobby : String):
	if _is_web_socket_connected():
		_send_message(Action_JoinLobby, { "id": idLobby })

func send_message_leave_lobby():
	if _is_web_socket_connected():
		_send_message(Action_LeaveLobby, {})

func send_message_to_lobby(message_text: String):
	if _is_web_socket_connected():
		%LobbyInput.clear()
		var message_payload = { 
			'message_text': message_text,
		}
		_send_message(Action_MessageToLobby, message_payload)

func send_message_heartbeat():
	if _is_web_socket_connected():
		_send_message(Action_Heartbeat, {})

func send_message_start_game(idLobby: String):
	if _is_web_socket_connected():
		_send_message(Action_GameStarted, { "id": idLobby })

func render_user_list(users):
	for child in %UserList.get_children():
		child.queue_free()
	for single_user in users:
		var user_label = Label.new()
		user_label.name = str(int(single_user.id))
		user_label.text = single_user.username
		%UserList.add_child(user_label, true)

func render_lobby_list(lobbies):
	for child in %LobbyList.get_children():
		child.queue_free()
	for lobby in lobbies:
		var render_lobby: LobbyListItem = LobbyItemScene.instantiate()
		render_lobby.name = str(lobby.id)
		render_lobby.player_count = lobby.players.size()
		%LobbyList.add_child(render_lobby, true)
		# TODO: do this a lot better
		render_lobby.lobby_join_button.pressed.connect(func(): send_message_join_lobby(lobby.id))
		render_lobby.lobby_leave_button.pressed.connect(func(): send_message_leave_lobby())
		render_lobby.lobby_start_button.pressed.connect(func(): send_message_start_game(lobby.id))

func render_remove_user_from_list(webId):
	for child in %UserList.get_children():
		# TODO: Better types here, float can often have an extra .0 decimal
		if child.name == str(int(webId)):
			child.queue_free()

func render_connection_confirmed(_webId):
	%LobbyServerConnect.disabled = true
	%LobbyServerDisconnect.disabled = false
	%UsernameInput.editable = false
	%ConnectLight.modulate = Color.GREEN
	send_message_get_lobbies()
	#timer_heartbeat.start()

func render_data_recieved_debug(new_message):
	#print('DEBUG DATA RECIEVED', new_message)
	%ConnectLight.modulate = Color.WHITE
	%DebugText.text = %DebugText.text + new_message + '[br]' 
	timer_heartbeat_light.start()

func render_lobby_message(message_payload):
	%LobbyChat.text = %LobbyChat.text + message_payload.username + ' : ' + message_payload.message_text + '[br]'

#############
#############
#############
# WebRTC
#############
#############
#############

#region WebRTCMultiplayerPeer Signals (Not Used Currently)
func ready_rtc_peer():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)

func RTCServerConnected():
	print("RTC server connected")
	
func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))
#endregion

# NOTE: The server will send a candidate, offer, and answer for each peer in the lobby
func create_multiplayer_peer_connection(id: int):
	if id != current_web_id:
		var new_peer_connection: WebRTCPeerConnection = WebRTCPeerConnection.new()
		new_peer_connection.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		print("binding id " + str(id) + " my id is " + str(current_web_id))

		new_peer_connection.session_description_created.connect(self.offerCreated.bind(id))
		new_peer_connection.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
		webRTCPeer.add_peer(new_peer_connection, id)
		if id < webRTCPeer.get_unique_id():
			new_peer_connection.create_offer()

func offerCreated(type, data, id):
	if !webRTCPeer.has_peer(id):
		return
		
	webRTCPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)

func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : current_web_id,
		"data": data,
		#"Lobby": lobbyValue
	}
	_send_message(Action_Offer, message)
	#peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func sendAnswer(id, data):
	var message = {
		"peer" : id, 
		"orgPeer" : current_web_id, 
		#"message" : Message.answer,
		"data": data,
		#"Lobby": lobbyValue
	}
	_send_message(Action_Answer, message)
	#peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : current_web_id,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		#"Lobby": lobbyValue
	}
	_send_message(Action_Candidate, message)
	#peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func render_web_socket_disconnect(): 
	%LobbyServerConnect.disabled = false
	%LobbyServerDisconnect.disabled = true
	%UsernameInput.editable = true
	render_left_lobby()
	for child in %LobbyList.get_children():
		child.queue_free()
	for child in %UserList.get_children():
		child.queue_free()

func on_disconnect_button_pressed():
	_client.close(1000, 'User clicked disconnect')

func on_heartbeat_light():
	%ConnectLight.modulate = Color.GREEN
	if _is_web_socket_connected() == false:
		%ConnectLight.modulate = Color.WHITE

func render_left_lobby():
	%LobbyChat.text = ''
	%LobbyChat.clear()

func quick_join():
	_client = WebSocketPeer.new()	
	_client.connect_to_url(WEB_SOCKET_SERVER_URL)
	set_process(true)
	
	signal_lobby_updated.connect(quick_join_seek_lobby)

func quick_join_seek_lobby(lobbies):
	if lobbies:
		# players
		# isGameStarted
		# id
		for lobby in lobbies:
			if lobby.isGameStarted == false:
				send_message_join_lobby(lobby.id)
				return
		
		send_message_create_lobby()
	else:
		send_message_create_lobby()

func get_username_input():
	if %UsernameInput && %UsernameInput.text:
		return %UsernameInput.text
	else:
		const letters = "abc123"
		var random_username = ""
		for i in range(8):
			random_username = random_username + letters[randi_range(0, letters.length() - 1)]
		%UsernameInput.text = random_username
		return random_username
