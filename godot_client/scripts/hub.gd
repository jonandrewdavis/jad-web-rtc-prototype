extends Node

var world: Node3D
var projectile_system: ProjectileSystem
var players

# TODO: These are shortcuts. Normally the server would be able to tell us about these, but we'll just 
# set them here and sync them once on spawn.
var current_chosen_color: Color = Color.WHITE
var current_chosen_username: String
