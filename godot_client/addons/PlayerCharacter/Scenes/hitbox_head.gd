extends StaticBody3D

@onready var parent : CharacterBody3D = $".."

func hitscanHit(damageVal : float, hitscanDir : Vector3, hitscanPos : Vector3, source: int = 1):
	if parent != null: parent.hitscanHit(damageVal, hitscanDir, hitscanPos, source)
