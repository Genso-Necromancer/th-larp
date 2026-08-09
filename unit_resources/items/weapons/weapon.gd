@tool
extends Item
class_name Weapon

@export var stats : WeaponResource:
	set(value):
		stats = value
		load_resource(value)
var dmg : int = 0
var charge_value : int = 0:
	set(value):
		charge_value = clampi(value, 0, 999)
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
var close_min_reach : int = 0:
	set(value):
		close_min_reach = clampi(value, 0, 999)
var close_max_reach : int = 0:
	set(value):
		close_max_reach = clampi(value, 0, 999)
var far_min_reach : int = 0:
	set(value):
		far_min_reach = clampi(value, 0, 999)
var far_max_reach : int = 0:
	set(value):
		far_max_reach = clampi(value, 0, 999)
var damage_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE


func _init(resource:WeaponResource = stats) ->void:
		#if stats == null: stats = resource
		super(resource)
		if properties == null: return
		dmg = properties.dmg
		charge_value = properties.charge_value
		hit = properties.hit
		crit = properties.crit
		crit_min = properties.crit_min
		crit_max = properties.crit_max
		barrier = properties.barrier
		barrier_chance = properties.barrier_chance
		min_reach = properties.min_reach
		max_reach = properties.max_reach
		close_min_reach = properties.close_min_reach
		close_max_reach = properties.close_max_reach
		far_min_reach = properties.far_min_reach
		far_max_reach = properties.far_max_reach
		damage_type = properties.damage_type


func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["class"] = "Weapon"
	values["dmg"] = dmg
	values["charge_value"] = charge_value
	values["hit"] = hit
	values["crit"] = crit
	values["crit_min"] = crit_min
	values["crit_max"] = crit_max
	values["barrier"] = barrier
	values["barrier_chance"] = barrier_chance
	values["min_reach"] = min_reach
	values["max_reach"] = max_reach
	values["close_min_reach"] = close_min_reach
	values["close_max_reach"] = close_max_reach
	values["far_min_reach"] = far_min_reach
	values["far_max_reach"] = far_max_reach
	values["damage_type"] = damage_type
	
	return values


func load_save_data(save_data:Dictionary):
	super.load_save_data(save_data)
	#stats = load(save_data.properties)
