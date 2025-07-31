@tool
extends Feature
class_name Skill


@export var augment : bool = false
@export var target : Enums.SKILL_TARGET = Enums.SKILL_TARGET.NONE
@export var can_miss : bool = true
@export var can_crit : bool = true
@export var can_dmg : bool = true
@export var min_reach : int = 0 ##if 0, ignored by Augment. Set value to require specific weapon reach. Otherwise is range of regular skill
@export var max_reach : int = 0
@export var cost : int = 0 ##Composure cost to use
@export_category("Augment Skill Parameters")
@export var weapon_category : Enums.WEAPON_CATEGORY = Enums.WEAPON_CATEGORY.ANY
@export var sub_group : Enums.WEAPON_SUB = Enums.WEAPON_SUB.NONE
@export var bonus_min_range : int = 0
@export var bonus_max_range : int = 0
@export_category("Skill Parameters")
@export var hit : int = 0
@export var dmg : int = 0
@export var crit : int = 0
@export var dmg_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE
@export_category("Effects")
@export var effects : Array[Effect] = []

func get_resource_path()->String:
	var path:String = "res://unit_resources/features/skills/%s.gd" % id
	return path
