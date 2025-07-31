@tool
extends ItemResource
class_name AccessoryResource

func get_resource_path()->String:
	var path:String = "res://unit_resources/items/accessories/%s.tres" % id
	
	return path
