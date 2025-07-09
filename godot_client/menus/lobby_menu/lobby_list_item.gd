extends PanelContainer
class_name LobbyListItem

var player_count
@onready var lobby_join_button: Button = %LobbyJoinButton
@onready var lobby_leave_button: Button = %LobbyLeaveButton
@onready var lobby_start_button: Button = %LobbyStartGame

func _ready() -> void:
	%LobbyId.text = str(name).substr(0, 7)
	%PlayerCount.text = str(player_count)
