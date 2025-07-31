@tool
extends Item
class_name Accessory

@export var stats : AccessoryResource:
	set(value):
		stats = value
		load_resource(value)


func _init(resource : ItemResource = stats) -> void:
	if resource == null: return
	elif stats == null: stats = resource
	super(resource)


func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["class"] = "Accessory"
	return values


func load_save_data(save_data:Dictionary):
	super.load_save_data(save_data)
	#stats = load(save_data.properties)
