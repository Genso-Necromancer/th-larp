@tool
##inheritance only, do not use directly. Instead use Weapon, Natural, Consumable or Accessory. 
##Any class inheriting this class is intended to be instanced using .duplicate(), without recursion
extends Resource
class_name SlotWrapper

var properties : UnitResource
var id : String





func _init(resource : UnitResource = load("res://unit_resources/items/weapons/unarmed_resource.tres")) -> void:
	if resource == null: return
	else: properties = resource
	id = properties.id
	print(_format_to_id())


func get_property_names() -> Array[String]:
	var propList : Array[Dictionary] = get_property_list()
	var propNames : Array[String] = []
	for prop in propList:
		if prop.name in self:
			propNames.append(prop.name)
	return propNames


func load_resource(resource:UnitResource):
	_init(resource)


func _format_to_id() -> String:
	var path = get_path()
	var new_id : String
	var count : int = path.get_slice_count("/")
	var slice :String = path.get_slice("/",count)
	new_id = slice.trim_suffix(".tres")
	#print(path)
	#print(count)
	#print(slice)
	#print(new_id)
	return new_id


func convert_to_save_data()->Dictionary:
	var converted:Dictionary
	converted = _get_values()
	converted["Properties"] = properties.get_resource_path()
	return converted


func _get_values()->Dictionary:
	var values:Dictionary ={}
	values["id"] = id
	return values


func load_save_data(save_data:Dictionary):
	id = save_data.id
