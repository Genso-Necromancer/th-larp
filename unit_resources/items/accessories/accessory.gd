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
