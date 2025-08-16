extends CanvasLayer

@onready var weaponStackLabelText = %WeaponStackLabelText
@onready var weaponNameLabelText = %WeaponNameLabelText
@onready var totalAmmoInMagLabelText = %TotalAmmoInMagLabelText
@onready var totalAmmoLabelText = %TotalAmmoLabelText


func _ready() -> void:
	Hub.hit.connect(func(): $HitSound.play())

func displayWeaponStack(weaponStack : int):
	weaponStackLabelText.set_text(str(weaponStack))
	
func displayWeaponName(weaponName : String):
	weaponNameLabelText.set_text(str(weaponName))
	
func displayTotalAmmoInMag(totalAmmoInMag : int, nbProjShotsAtSameTime : int):
	totalAmmoInMagLabelText.set_text(str(totalAmmoInMag/nbProjShotsAtSameTime))
	
func displayTotalAmmo(totalAmmo : int, nbProjShotsAtSameTime : int):
	totalAmmoLabelText.set_text(str(totalAmmo/nbProjShotsAtSameTime))
	
	
