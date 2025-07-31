@tool
extends Item
class_name Consumable

@export var stats: ConsumableResource:
	set(value):
		stats = value
		load_resource(value)
var target : Enums.SKILL_TARGET = Enums.SKILL_TARGET.NONE
var min_reach : int = 0:
	set(value):
		min_reach = clampi(value, 0, 999)
var max_reach: int = 0:
	set(value):
		max_reach = clampi(value, 0, 999)


func _init(resource : ItemResource = stats) -> void:
	if resource == null: return
	elif stats == null: stats = resource
	super(resource)
	if properties == null: return
	target = properties.target
	min_reach = properties.min_reach
	max_reach = properties.max_reach


func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["class"] = "Consumable"
	return values
	
func load_save_data(save_data:Dictionary):
	super.load_save_data(save_data)
	#stats = load(save_data.properties)
