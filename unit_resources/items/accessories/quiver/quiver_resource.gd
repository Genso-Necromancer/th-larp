@tool
extends AccessoryResource
class_name QuiverResource

func _init() -> void:
	category = Enums.WEAPON_CATEGORY.ACC

func get_resource_path() -> String:
	return "res://unit_resources/items/accessories/quiver/%s.tres" % id
