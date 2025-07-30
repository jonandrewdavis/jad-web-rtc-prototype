extends Node3D

class_name Master

@onready var player: Player = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.speed_scale = 0.7
	$AnimationPlayer.playback_default_blend_time = 0.2
	
	if player.look_at_target:
		$Armature/GeneralSkeleton/RightLower.target_node = player.look_at_target.get_path()
		$Armature/GeneralSkeleton/LeftLower.target_node = player.look_at_target.get_path()

		$Armature/GeneralSkeleton/LeftUpper.target_node = player.look_at_target.get_path()

		$Armature/GeneralSkeleton/RightHand.target_node = player.look_at_target.get_path()
		$Armature/GeneralSkeleton/LeftHand.target_node = player.look_at_target.get_path()

func cast_shadow_only():
	%vanguard_Mesh.cast_shadow = 3
	%vanguard_visor.cast_shadow = 3
