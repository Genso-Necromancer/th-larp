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
	#resource_name
	return path

func _get_values() -> Dictionary:
	var values: Dictionary = super._get_values()

	# core identity
	values["path"] = resource_path if resource_path != "" else get_resource_path()

	# effect behavior
	values["type"] = int(type)
	values["sub_type"] = int(sub_type)
	values["target"] = int(target)
	values["instant"] = bool(instant)
	values["on_hit"] = bool(on_hit)
	values["proc"] = int(proc)

	# duration/stacking
	values["duration"] = int(duration)
	values["duration_type"] = int(duration_type)
	values["stack"] = bool(stack)
	values["permanent"] = bool(permanent)

	# common flags
	values["curable"] = bool(curable)
	values["from_item"] = bool(from_item)
	values["hostile"] = bool(hostile)

	# value (int or float depending on type)
	values["value"] = value

	# type-specific payload
	values["multi_swing"] = int(multi_swing)
	values["multi_round"] = int(multi_round)
	values["crit_dmg"] = crit_dmg.duplicate(true)
	values["crit_mult"] = bool(crit_mult)
	values["crit_rate"] = int(crit_rate)

	# References: store paths (UnitSim should not hold live Resources)
	values["skill_path"] = (skill.resource_path if skill else "")
	values["passive_path"] = (passive.resource_path if passive else "")

	return values

static func from_data(data: Dictionary) -> Effect:
	if data == null:
		return null

	# If a path exists, prefer loading the actual resource (keeps editor-authored defaults)
	var path := String(data.get("path", ""))
	if path == "":
		path = String(data.get("Properties", ""))

	var e: Effect = null
	if path != "" and ResourceLoader.exists(path):
		e = load(path) as Effect
	else:
		e = Effect.new()

	# Apply fields (only if present in data)
	# Core behavior
	if data.has("type"): e.type = int(data["type"])
	if data.has("sub_type"): e.sub_type = int(data["sub_type"])
	if data.has("target"): e.target = int(data["target"])
	if data.has("instant"): e.instant = bool(data["instant"])
	if data.has("on_hit"): e.on_hit = bool(data["on_hit"])
	if data.has("proc"): e.proc = int(data["proc"])

	# Duration / stacking
	if data.has("duration"): e.duration = int(data["duration"])
	if data.has("duration_type"): e.duration_type = int(data["duration_type"])
	if data.has("stack"): e.stack = bool(data["stack"])
	if data.has("permanent"): e.permanent = bool(data["permanent"])

	# Flags
	if data.has("curable"): e.curable = bool(data["curable"])
	if data.has("from_item"): e.from_item = bool(data["from_item"])
	if data.has("hostile"): e.hostile = bool(data["hostile"])

	# Value
	if data.has("value"): e.value = data["value"] # can be int or float

	# Type-specific payload
	if data.has("multi_swing"): e.multi_swing = int(data["multi_swing"])
	if data.has("multi_round"): e.multi_round = int(data["multi_round"])
	if data.has("crit_dmg"):
		var cd = data["crit_dmg"]
		if cd is Array:
			e.crit_dmg = cd.duplicate(true)
	if data.has("crit_mult"): e.crit_mult = bool(data["crit_mult"])
	if data.has("crit_rate"): e.crit_rate = int(data["crit_rate"])

	# References: load via path if present
	var sp := String(data.get("skill_path", ""))
	if sp != "" and ResourceLoader.exists(sp):
		e.skill = load(sp)

	var pp := String(data.get("passive_path", ""))
	if pp != "" and ResourceLoader.exists(pp):
		e.passive = load(pp)

	return e

#region warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Types that must be INSTANT to matter
	var needs_instant := {
		Enums.EFFECT_TYPE.SLAYER: true,
		Enums.EFFECT_TYPE.CRIT_BUFF: true,
	}
	if needs_instant.has(type) and not bool(instant): warnings.append("This effect requires 'instant' enabled.")

	# These types are not meant to be resolved as per-swing on-hit effects
	var not_on_hit := {
		Enums.EFFECT_TYPE.MULTI_SWING: true,
		Enums.EFFECT_TYPE.MULTI_ROUND: true,
		Enums.EFFECT_TYPE.TIME: true,
	}

	if bool(on_hit) and not_on_hit.has(type):
		warnings.append("This effect type does not require 'Instant'. It is handled elsewhere in the combat flow.")

	return warnings
#endregion
