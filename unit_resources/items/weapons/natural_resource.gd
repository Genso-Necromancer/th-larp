@tool
extends WeaponResource
class_name NaturalResource

## Allows the owner's natural-weapon passive to scale these stats with level. Requires a supported scaling rule.
@export var is_scaling : bool = false

func get_resource_path()->String:
	var path:String = "res://unit_resources/items/weapons/natural/%s.tres" % id
	
	return path
