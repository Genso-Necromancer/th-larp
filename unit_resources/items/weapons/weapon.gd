@tool
extends Item
class_name Weapon

@export var stats : WeaponResource:
	set(value):
		stats = value
		load_resource(value)
var dmg : int = 0
var hit : int = 00
var crit : int = 00
var crit_min: int = 0
var crit_max: int = 0
var barrier : int = 0
var barrier_chance : int = 0
var min_reach : int = 1:
	set(value):
		min_reach = clampi(value, 0, 999)
var max_reach: int = 1:
	set(value):
		max_reach = clampi(value, 0, 999)
var damage_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE


func _init(resource:WeaponResource = stats) ->void:
		#if stats == null: stats = resource
		super(resource)
		if properties == null: return
		dmg = properties.dmg
		hit = properties.hit
		crit = properties.crit
		crit_min = properties.crit_min
		crit_max = properties.crit_max
		barrier = properties.barrier
		barrier_chance = properties.barrier_chance
		min_reach = properties.min_reach
		max_reach = properties.max_reach
		damage_type = properties.damage_type


func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["class"] = "Weapon"
	values["dmg"] = dmg
	values["hit"] = hit
	values["crit"] = crit
	values["crit_min"] = crit_min
	values["crit_max"] = crit_max
	values["barrier"] = barrier
	values["barrier_chance"] = barrier_chance
	values["min_reach"] = min_reach
	values["max_reach"] = max_reach
	values["damage_type"] = damage_type
	
	return values


func load_save_data(save_data:Dictionary):
	super.load_save_data(save_data)
	#stats = load(save_data.properties)
