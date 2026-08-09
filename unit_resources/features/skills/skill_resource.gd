@tool
extends Feature
class_name Skill


@export var augment : bool = false
@export var magical : bool = false: ##Determins if the skill is treated as a spell, like in use with Silence. Does not determine if the skill uses Power or Magic. dmg_type determines this.
	set(value):
		magical = value
		if not magical:
			element = Enums.SPELL_ELEMENT.NONE
		notify_property_list_changed()
var element : Enums.SPELL_ELEMENT = Enums.SPELL_ELEMENT.NONE
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
##this is *added* to existing weapon crit range if used on a weapon skill, otherwise is the literal crit range of a normal skill
@export_range(0,99,1.0) var crit_min:int= 0
##this is *added* to existing weapon crit range if used on a weapon skill, otherwise is the literal crit range of a normal skill
@export_range(0,99,1.0) var crit_max:int= 0
@export var dmg_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE
@export_category("Effects")
@export var effects : Array[Effect] = []

func _get_property_list():
	var properties = super._get_property_list()
	if magical:
		properties.append({
			"name": "element",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _enum_to_string(Enums.SPELL_ELEMENT)
		})
	return properties

func get_resource_path()->String:
	var path:String = "res://unit_resources/features/skills/%s.gd" % id
	return path


func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["augment"] = bool(augment)
	values["magical"] = bool(magical)
	values["element"] = element if magical else Enums.SPELL_ELEMENT.NONE
	values["target"] = target
	values["can_miss"] = bool(can_miss)
	values["can_crit"] = bool(can_crit)
	values["can_dmg"] = bool(can_dmg)
	values["min_reach"] = min_reach
	values["max_reach"] = max_reach
	values["cost"] = cost
	values["weapon_category"] = weapon_category
	values["sub_group"] = sub_group
	values["bonus_min_range"] = bonus_min_range
	values["bonus_max_range"] = bonus_max_range
	values["hit"] = hit
	values["dmg"] = dmg
	values["crit"] = crit
	values["crit_min"] = crit_min
	values["crit_max"] = crit_max
	values["dmg_type"] = dmg_type
	values["effects"] = effects
	return values
