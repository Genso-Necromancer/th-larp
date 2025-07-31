@tool
extends ItemResource
class_name ConsumableResource

@export var target : Enums.SKILL_TARGET = Enums.SKILL_TARGET.NONE
@export var min_reach : int = 0:
	set(value):
		min_reach = clampi(value, 0, 999)
@export var max_reach: int = 0:
	set(value):
		max_reach = clampi(value, 0, 999)

func get_resource_path()->String:
	var path:String = "res://unit_resources/items/consumables/%s.tres" % id
	
	return path
