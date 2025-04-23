@tool
extends Weapon
class_name Natural

var is_scaling := false

func _init(resource :NaturalResource = stats) -> void:
	super(resource)
	if properties == null: return
	elif properties is NaturalResource:
		is_scaling = properties.is_scaling
		breakable = false
		expendable = false
		personal = true
		trade = false
		use = false
		sub_group = Enums.WEAPON_SUB.NATURAL
