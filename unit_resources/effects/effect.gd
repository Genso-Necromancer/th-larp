@tool
extends UnitResource
class_name Effect


@export var type : Enums.EFFECT_TYPE = Enums.EFFECT_TYPE.NONE:
	set(value):
		if value == Enums.EFFECT_TYPE.NONE: sub_type = 0
		type = value
		notify_property_list_changed()
var sub_type
@export var target : Enums.EFFECT_TARGET
@export var instant : bool = false ##only set for effects that should occur before an augment skill is rolled.
@export var on_hit := false ##require successful accuracy check to activate effect
@export var proc : int = 0 ##Set to -1 to always proc
@export var duration : int = 0
@export var duration_type : Enums.DURATION_TYPE
@export var stack := false ##True: Effect will stack atop existing versions of itself. False: will overwrite existing versions of itself
var value  ##use 0-2 float for time speed up/slow down. USE NEGATIVE VALUES FOR DEBUFFS, OR YOU BUFF THEM
@export var permanent := false ##if the effect is added as a permanent change to unit
@export_group("Effect Type properties")
@export var curable := true ##STATUS/DEBUFF/BUFF
@export var from_item := false ##HEAL. true disallows stat bonus to healing
@export var hostile := false ##RELOC. determins if relocation is treated as hostile
@export var skill :Skill ##ADD_SKILL
@export var passive :Passive ##ADD_PASSIVE
@export var multi_swing := 0 ## # of extra attacks per swing
@export var multi_round := 0 ## # of extra rounds of combat, it's death match bro
@export var crit_dmg :Array[int]=[0,0] ##CRIT_BUFF adjustment to min and max crit damage roll, can be negative for penalty
@export var crit_mult := false ##CRIT_BUFF Alternative crit damage multiplier, dunno which will be used yet
@export var crit_rate := 0 ##CRIT_BUFF Bonus crit chance

func _get_property_list():
	var properties = []
	var sub_type_entry : Dictionary
	var value_entry : Dictionary
	match type:
		Enums.EFFECT_TYPE.TIME:
			value_entry ={
				"name" : "value",
				"type" : TYPE_FLOAT,
				"hint" : PROPERTY_HINT_NONE,
				
			}
		_:
			value_entry ={
				"name" : "value",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_NONE,
			} 
	
	match type:
		Enums.EFFECT_TYPE.DAMAGE:
			sub_type_entry={
				"name" : "sub_type",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.DAMAGE_TYPE)
			}
		_:
			sub_type_entry={
				"name" : "sub_type",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.SUB_TYPE)
			}
	
	properties.append({
			name = "Effect Value",
			type = TYPE_NIL,
			hint_string = "value",
			usage = PROPERTY_USAGE_CATEGORY
		})
	properties.append(value_entry)
	properties.append({
			name = "Sub Type: DOWN HERE!",
			type = TYPE_NIL,
			hint_string = "sub_type",
			usage = PROPERTY_USAGE_CATEGORY
		})
	properties.append(sub_type_entry)
	
	return properties


func get_resource_path()->String:
	var path:String = "res://unit_resources/effects/%s.tres" % id
	resource_name
	return path
