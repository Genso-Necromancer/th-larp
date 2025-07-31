@tool
extends WeaponResource
class_name NaturalResource

@export var is_scaling : bool = false

func get_resource_path()->String:
	var path:String = "res://unit_resources/items/weapons/%s.tres" % id
	
	return path
