extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BADMP.add_scene(BADSceneManager.MAIN, "res://menus/main_menu_bad/main_menu_bad.tscn")
	BADMP.add_scene(BADSceneManager.GAME, "res://game/world/world.tscn")
	BADMP.add_scene(BADSceneManager.LOADING, "res://menus/main_menu_loading/main_menu_loading.tscn")
