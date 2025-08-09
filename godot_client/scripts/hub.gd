extends Node

var world: Node3D
var projectile_system: ProjectileSystem
var players


var colors = [Color.WHITE, Color.CHARTREUSE, Color.DEEP_PINK, Color.CYAN, Color.ORANGE_RED, Color.SLATE_BLUE, Color.YELLOW, Color.CORAL, Color.BLUE]
# TODO: These are shortcuts. Normally the server would be able to tell us about these, but we'll just 
# set them here and sync them once on spawn.
var current_chosen_color: Color
var current_chosen_color_index: int
var current_chosen_username: String
