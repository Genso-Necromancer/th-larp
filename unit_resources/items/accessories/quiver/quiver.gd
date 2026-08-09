@tool
extends Accessory
class_name Quiver

#@export var stats : QuiverResource:
	#set(value):
		#stats = value
		#load_resource(value)

func _init(resource: QuiverResource = stats) -> void:
	super(resource)
	category = Enums.WEAPON_CATEGORY.ACC

func _get_values() -> Dictionary:
	var values := super._get_values()
	values["class"] = "Quiver"
	return values
