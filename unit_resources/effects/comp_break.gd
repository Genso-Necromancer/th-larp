@tool
extends Effect
class_name CompBreak


@export var hit_penalty := -10
@export var graze_penalty := -10
@export var crit_penalty := -5


func _init() -> void:
	type = Enums.EFFECT_TYPE.DEBUFF
	target = Enums.EFFECT_TARGET.SELF
	curable = false
	stack = false
	permanent = false
	duration = 0
	duration_type = Enums.DURATION_TYPE.NONE
	sub_type = Enums.SUB_TYPE.NONE
	value = 0


func _get_values() -> Dictionary:
	var values := super._get_values()
	values["comp_break"] = true
	values["hit_penalty"] = hit_penalty
	values["graze_penalty"] = graze_penalty
	values["crit_penalty"] = crit_penalty
	return values
