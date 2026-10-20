@tool
extends ItemResource
class_name WeaponResource

#@export_category("Weapon Stats")

## Weapon Might, added to the attacker's relevant damage stat.
@export var dmg : int = 0
## Bonus damage per hex moved, on the first attack only. Zero disables charge; Brace negates it.
@export var charge_value : int = 0:
	set(value):
		charge_value = clampi(value, 0, 999)
## Weapon Hit bonus, added to the wielder's natural Hit.
@export var hit : int = 00
## Weapon Crit chance bonus in percentage points.
@export var crit : int = 00
## Minimum extra damage rolled on a critical hit.
@export_range(0,99,1.0) var crit_min:int= 10
## Maximum extra damage rolled on a critical hit. Keep at least as high as Crit Min.
@export_range(0,99,1.0) var crit_max:int= 20
## Flat Barrier added by this weapon.
@export var barrier : int = 0
## Barrier activation chance bonus in percentage points.
@export var barrier_chance : int = 0
## Nearest hex distance in the normal range band.
@export var min_reach : int = 1:
	set(value):
		min_reach = clampi(value, 0, 999)
## Farthest hex distance in the normal range band. Keep at least as high as Min Reach.
@export var max_reach: int = 1:
	set(value):
		max_reach = clampi(value, 0, 999)
## Nearest distance in the penalized Close band. Both Close values at zero disable it; one zero copies the other bound.
@export var close_min_reach : int = 0:
	set(value):
		close_min_reach = clampi(value, 0, 999)
## Farthest distance in the Close band. Shots here use the global range-band Hit penalty.
@export var close_max_reach : int = 0:
	set(value):
		close_max_reach = clampi(value, 0, 999)
## Nearest distance in the penalized Far band. Both Far values at zero disable it; one zero copies the other bound.
@export var far_min_reach : int = 0:
	set(value):
		far_min_reach = clampi(value, 0, 999)
## Farthest distance in the Far band. Shots here use the global range-band Hit penalty.
@export var far_max_reach : int = 0:
	set(value):
		far_max_reach = clampi(value, 0, 999)
## PHYS uses Pwr against Def; MAG uses Mag against Mag; TRUE bypasses normal defenses.
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
