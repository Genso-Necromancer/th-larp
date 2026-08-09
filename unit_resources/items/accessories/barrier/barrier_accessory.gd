@tool
extends Accessory
class_name BarrierAccessory

#@export var stats : BarrierResource:
	#set(value):
		#stats = value
		#load_resource(value)

func _init(resource: BarrierResource = stats) -> void:
	super(resource)
	category = Enums.WEAPON_CATEGORY.ACC
	sub_group = Enums.WEAPON_SUB.BARRIER

func _get_values() -> Dictionary:
	var values := super._get_values()
	values["class"] = "BarrierAccessory"
	return values
