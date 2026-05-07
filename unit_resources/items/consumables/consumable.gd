@tool
extends Item
class_name Consumable

@export var stats: ConsumableResource:
	set(value):
		stats = value
		load_resource(value)

# Combat-engine compatibility surface.
# Consumables can be routed through the same action resolution path as skills,
# so they need the same baseline fields even when most stay at harmless defaults.
var can_miss : bool = false
var can_dmg : bool = false
var can_crit : bool = false
var dmg : int = 0
var hit : int = 0
var crit : int = 0
var crit_min : int = 0
var crit_max : int = 0
var damage_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.PHYS
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
	values["can_miss"] = can_miss
	values["can_dmg"] = can_dmg
	values["can_crit"] = can_crit
	values["dmg"] = dmg
	values["hit"] = hit
	values["crit"] = crit
	values["crit_min"] = crit_min
	values["crit_max"] = crit_max
	values["damage_type"] = damage_type
	values["target"] = target
	values["min_reach"] = min_reach
	values["max_reach"] = max_reach
	return values
	
func load_save_data(save_data:Dictionary):
	super.load_save_data(save_data)
	#stats = load(save_data.properties)
