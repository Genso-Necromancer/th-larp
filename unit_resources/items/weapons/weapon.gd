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
		barrier = properties.barrier
		barrier_chance = properties.barrier_chance
		min_reach = properties.min_reach
		max_reach = properties.max_reach
		damage_type = properties.damage_type
		
