@tool
extends ItemResource
class_name WeaponResource

#@export_category("Weapon Stats")

@export var dmg : int = 0
@export var charge_value : int = 0:
	set(value):
		charge_value = clampi(value, 0, 999)
@export var hit : int = 00
@export var crit : int = 00
@export_range(0,99,1.0) var crit_min:int= 10
@export_range(0,99,1.0) var crit_max:int= 20
@export var barrier : int = 0
@export var barrier_chance : int = 0
@export var min_reach : int = 1:
	set(value):
		min_reach = clampi(value, 0, 999)
@export var max_reach: int = 1:
	set(value):
		max_reach = clampi(value, 0, 999)
@export var close_min_reach : int = 0:
	set(value):
		close_min_reach = clampi(value, 0, 999)
@export var close_max_reach : int = 0:
	set(value):
		close_max_reach = clampi(value, 0, 999)
@export var far_min_reach : int = 0:
	set(value):
		far_min_reach = clampi(value, 0, 999)
@export var far_max_reach : int = 0:
	set(value):
		far_max_reach = clampi(value, 0, 999)
@export var damage_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE

func get_resource_path()->String:
	var folder := ""
	if sub_group == Enums.WEAPON_SUB.KNIFE:
		folder = "knife/"
	else:
		match category:
			Enums.WEAPON_CATEGORY.BLADE:
				folder = "blade/"
			Enums.WEAPON_CATEGORY.BLUNT:
				folder = "blunt/"
			Enums.WEAPON_CATEGORY.STICK:
				folder = "polearm/"
			Enums.WEAPON_CATEGORY.BOW:
				folder = "bow/"
			Enums.WEAPON_CATEGORY.GOHEI:
				folder = "gohei/"
			Enums.WEAPON_CATEGORY.BOOK:
				folder = "book/"
			Enums.WEAPON_CATEGORY.OFUDA:
				folder = "ofuda/"
	var path:String = "res://unit_resources/items/weapons/%s%s.tres" % [folder, id]
	
	return path
