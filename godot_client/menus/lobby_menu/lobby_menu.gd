class_name LobbyMenu
extends CanvasLayer


# SERVER
const Server_SecretKey = "YOUR_SECRET_KEY_HERE_NEVER_SHOW_IT_:)"

# Change to your server url, currently set to the localhost
const Server_WSUrl = "ws://127.0.0.1:8080"

var current_username : String = ""
var web_socket_client : WebSocketPeer

var current_web_id = ""
var is_lobby_master = false

var lobby_data = null

# Web socket signals
signal web_socket_connected
signal web_socket_disconnected

# Web socket message signals
signal connection(success)

signal update_user_list(success, users)
#signal player_join(id, position, direction)
signal player_join(id)
signal player_left(webId)

signal update_lobby_list(success, lobbies)
signal get_own_lobby(lobby)
signal created_lobby(success)
signal joined_lobby(success)
signal left_lobby(success)
signal lobby_changed(lobby)

signal game_started

# AD: new signal
signal signal_data_received(text)

#signal entity_position_update(data)
#signal entity_hard_position_update(data)
#signal entity_update_state(data)
#signal entity_misc_process_data(data)
#signal entity_misc_one_off(data)
#signal entity_death(data)
#signal entity_spawn(data)

# ACTIONS
# TODO: Should be an ENUM
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

# TODO: Do those code "sections" like in fpc.

# TODO: uh. parse for bad chars?
var username_input = ''
var connection_validated = false

# TODO: Disable connect if no name.
# TODO: Disable connect if connected.
# TODO: Enable disconnect when connected.

# TODO: Clear about these assets.
@export var LobbyItemScene: PackedScene = preload("res://menus/lobby_menu/lobby_list_item.tscn") 

func _ready():
	set_process(false)
	
	# TODO: all UI could go to antoher node. Good to seperate? or is it all tied together
	ready_button_connections()
	ready_render_connections()	

	# Once connected, this signal confirms the authentication
	# TODO: Improve the true/false & property handle disconnect from Websocket server
	#web_socket_connected.connect()
	game_started.connect(on_game_started)

func ready_button_connections():
	%UsernameInput.text_changed.connect(func (text): username_input = text)
	%LobbyServerConnect.pressed.connect(func (): connect_to_server(username_input))
	%LobbyCreate.pressed.connect(func (): send_message_create_lobby())

func ready_render_connections():
	web_socket_connected.connect(render_connection_confirmed)
	update_user_list.connect(render_user_list)
	player_left.connect(render_remove_user_from_list)
	signal_data_received.connect(render_data_recieved_debug)
	update_lobby_list.connect(render_lobby_list)

func _process(_delta):
	web_socket_client.poll()
	var state: WebSocketPeer.State = web_socket_client.get_ready_state()
	match state:
		WebSocketPeer.STATE_CONNECTING:
			return
		WebSocketPeer.STATE_OPEN:
			# TODO: Improve. This confirms our authentication with the server.
			if connection_validated == false:
				send_message_connect(current_username)
				connection_validated = true
				web_socket_connected.emit()
				return
			while web_socket_client.get_available_packet_count():
				data_received()
		WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = web_socket_client.get_close_code()
			var reason = web_socket_client.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false) # Stop processing.

func connect_to_server(username : String):
	if _is_web_socket_connected() || _is_web_socket_connecting():
		web_socket_client.disconnect_from_host(1000, "Reconnecting")
	
	current_username = username
	
	web_socket_client = WebSocketPeer.new()
	
	#web_socket_client.connect("data_received", Callable(self, "data_received"))
	#web_socket_client.connect("connection_established", Callable(self, "connection_established"))
	#web_socket_client.connect("connection_closed", Callable(self, "connection_closed"))
	#web_socket_client.connect("connection_error", Callable(self, "connection_error"))
	#web_socket_client.connect("connection_failed", Callable(self, "connection_failed"))
	
	web_socket_client.connect_to_url(Server_WSUrl)
	set_process(true)
	
	await get_tree().create_timer(4.0).timeout
	
	if !(_is_web_socket_connected()):
		web_socket_client.disconnect_from_host()
		emit_signal("web_socket_disconnected")



func data_received():
	var packet = web_socket_client.get_packet().get_string_from_utf8()
	var packet_to_json = JSON.parse_string(packet)
 	# print('DEBUG DATA RECIEVED', packet_to_json)
	if packet_to_json and packet_to_json.has('action') and packet_to_json.has('payload'):
		parse_message_received(packet_to_json)
		signal_data_received.emit(packet)
	else:
		push_warning("Invalid message received")

func connection_closed(_was_clean_close):
	print("Web socket connection was closed")
	emit_signal("web_socket_disconnected")
	
func connection_error():
	print("Web socket connection was interrupted")
	emit_signal("web_socket_disconnected")

func connection_failed():
	print("Web socket connection failed")
	emit_signal("web_socket_disconnected")

func _send_message(action : String, payload : Dictionary):
	if _is_web_socket_connected():
		var message = {
			"action": action,
			"payload": payload
		}
		var parsed_message = JSON.stringify(message)
		web_socket_client.put_packet(parsed_message.to_utf8_buffer())

func _is_web_socket_connected() -> bool:
	if web_socket_client:
		return web_socket_client.get_ready_state() == WebSocketPeer.STATE_OPEN
	return false

func _is_web_socket_connecting() -> bool:
	if web_socket_client:
		return web_socket_client.get_ready_state() == WebSocketPeer.STATE_CONNECTING
	return false 

# TODO: all of these do a pretty wasteful "_is_web_socket_connected" check... 
func send_message_connect(username : String):
	if _is_web_socket_connected():
		_send_message(Action_Connect, {"secretKey" : Server_SecretKey, "username" : username})

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

func send_message_to_lobby(messageContent):
	if _is_web_socket_connected():
		_send_message(Action_MessageToLobby, messageContent)

func send_message_heartbeat():
	if _is_web_socket_connected():
		_send_message(Action_Heartbeat, {})

# NOTE: Adapted from Lobby Join
func send_message_start_game(idLobby: String):
	if _is_web_socket_connected():
		_send_message(Action_GameStarted, { "id": idLobby })

func parse_message_received(json_message):
	match(json_message.action):
		Action_Connect:
			if json_message.payload.has("success") &&  json_message.payload.has("webId"):
				current_web_id = json_message.payload.webId
				emit_signal("connection", json_message.payload.success)
				if !json_message.payload.success:
					web_socket_client.disconnect_from_host(1000, "Couldn't authenticate")
			else:
				emit_signal("connection", false)
				web_socket_client.disconnect_from_host(1000, "Couldn't authenticate")
		Action_GetUsers:
			if json_message.payload.has("success"):
				if json_message.payload.success:
					if json_message.payload.has("users"):
						emit_signal("update_user_list", json_message.payload.success, json_message.payload.users)
					else:
						emit_signal("update_user_list", false, [])
				else:
					emit_signal("update_user_list", json_message.payload.success, [])
			else:
				emit_signal("update_user_list", false, [])
		Action_GetLobbies:
			if json_message.payload.has("lobbies"):
				emit_signal("update_lobby_list", json_message.payload.lobbies)
		Action_GetOwnLobby:
			if json_message.payload.has("lobby"):
				emit_signal("get_own_lobby", json_message.payload.lobby)
		Action_PlayerJoin:
			if json_message.payload.has("id"):
				emit_signal("player_join", json_message.payload.id)
		Action_PlayerLeft:
			if json_message.payload.has("webId"):
				emit_signal("player_left", json_message.payload.webId)
		Action_CreateLobby:
			if json_message.payload.has("success"):
				emit_signal("created_lobby", json_message.payload.success)
			is_lobby_master = true
		Action_JoinLobby:
			if json_message.payload.has("success"):
				emit_signal("joined_lobby", json_message.payload.success)
		Action_LeaveLobby:
			if json_message.payload.has("success"):
				emit_signal("left_lobby", json_message.payload.success)
			is_lobby_master = false
		Action_LobbyChanged:
			if json_message.payload.has("lobby"):
				emit_signal("lobby_changed", json_message.payload.lobby)
				lobby_data = json_message.payload.lobby
		Action_GameStarted:
			emit_signal("game_started")
		#Action_MessageToLobby:
			#if json_message.payload.has("type"):
				#match (json_message.payload.type):
					#GenericAction_EntityUpdatePosition:
						#if json_message.payload.has("position"):
							#emit_signal("entity_position_update", json_message.payload)
					#GenericAction_EntityHardUpdatePosition:
						#if json_message.payload.has("position"):
							#emit_signal("entity_hard_position_update", json_message.payload)
					#GenericAction_EntityUpdateState:
						#if json_message.payload.has("state"):
							#emit_signal("entity_update_state", json_message.payload)
					#GenericAction_EntityMiscProcessData:
						#emit_signal("entity_misc_process_data", json_message.payload)
					#GenericAction_EntityMiscOneOff:
						#emit_signal("entity_misc_one_off", json_message.payload)
					#GenericAction_EntityDeath:
						#emit_signal("entity_death", json_message.payload)
					#GenericAction_EntitySpawn:
						#emit_signal("entity_spawn", json_message.payload)
		#Action_MapSelected:
			#current_map_key = json_message.payload.mapKey

func current_pos_in_lobby():
	if lobby_data:
		for i in lobby_data.players.size():
			if lobby_data.players[i].id == current_web_id:
				return i
	return 2000

func get_position_in_lobby():
	if lobby_data == null || !lobby_data.has("players"):
		return 0
	var result = 0
	for i in lobby_data.players.size():
		if lobby_data.players[i].id == current_web_id:
			result = i
			break
	return result

# TODO: lol. be better.
func render_user_list(success, users):
	if success:
		for child in %UserList.get_children():
			child.queue_free()
		for single_user in users:
			var user_label = Label.new()
			user_label.name = single_user.id
			user_label.text = single_user.username
			%UserList.add_child(user_label)

func render_lobby_list(lobbies):
	for child in %LobbyList.get_children():
		child.queue_free()

	#players
	#isGameStarted
	#id
	for lobby in lobbies:
		var render_lobby: LobbyListItem = LobbyItemScene.instantiate()
		render_lobby.name = lobby.id
		render_lobby.player_count = lobby.players.size()
		%LobbyList.add_child(render_lobby, true)
		# TODO: do this a lot better
		render_lobby.lobby_join_button.pressed.connect(func(): send_message_join_lobby(lobby.id))
		render_lobby.lobby_leave_button.pressed.connect(func(): send_message_leave_lobby())
		render_lobby.lobby_start_button.pressed.connect(func(): send_message_start_game(lobby.id))

func render_remove_user_from_list(webId):
	# TODO: Unify "webId" ... sometimes it's id, sometimes it's "webId"
	# TODO: Requires server edits
	for child in %UserList.get_children():
		if child.name == str(webId):
			child.queue_free()

func render_connection_confirmed():
	%LobbyServerConnect.disabled = true
	%LobbyServerDisconnect.disabled = false
	send_message_get_lobbies()

func render_data_recieved_debug(new_message):
	%DebugText.text = %DebugText.text + new_message + '[br]' 

# TODO: this one is gonna be kinda nutty....... but basically it'll exchange ICE & turn
func on_game_started():
	print('lets go')
	
	
	





#############
#############
#############
