@tool
extends AccessoryResource
class_name BarrierResource

func _init() -> void:
	category = Enums.WEAPON_CATEGORY.ACC
	sub_group = Enums.WEAPON_SUB.BARRIER

func get_resource_path() -> String:
	return "res://unit_resources/items/accessories/barrier/%s.tres" % id
