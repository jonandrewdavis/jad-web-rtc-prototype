extends StaticBody3D

@onready var parent : CharacterBody3D = $".."

func hitscanHit(damageVal : float, hitscanDir : Vector3, hitscanPos : Vector3, _source: int = 1):
	if parent != null: parent.hitscanHit(damageVal, hitscanDir, hitscanPos)

func projectileHit(damageVal : float, _hitscanDir : Vector3, source: int = 1):
	if parent != null: parent.projectileHit(damageVal, _hitscanDir, source)
