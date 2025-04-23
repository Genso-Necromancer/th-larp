@tool
extends ItemResource
class_name WeaponResource

#@export_category("Weapon Stats")

@export var dmg : int = 0
@export var hit : int = 00
@export var crit : int = 00
@export var barrier : int = 0
@export var barrier_chance : int = 0
@export var min_reach : int = 1:
	set(value):
		min_reach = clampi(value, 0, 999)
@export var max_reach: int = 1:
	set(value):
		max_reach = clampi(value, 0, 999)
@export var damage_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE
