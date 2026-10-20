@tool
extends ItemResource
class_name ConsumableResource

## Which units this item may target. Set SELF for a self-use consumable.
@export var target : Enums.SKILL_TARGET = Enums.SKILL_TARGET.NONE
## Nearest allowed target distance in hexes. Zero supports targeting the user's own cell.
@export var min_reach : int = 0:
	set(value):
		min_reach = clampi(value, 0, 999)
## Farthest allowed target distance in hexes. Use 0/0 for self-only items.
@export var max_reach: int = 0:
	set(value):
		max_reach = clampi(value, 0, 999)

func get_resource_path()->String:
	var path:String = "res://unit_resources/items/consumables/%s.tres" % id
	
	return path
