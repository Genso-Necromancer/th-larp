@tool
extends Effect
class_name CompBreak


## Flat Hit modifier during this composure-break effect. Use a negative value for a penalty.
@export var hit_penalty := -10
## Flat Graze modifier during this composure-break effect. Use a negative value for a penalty.
@export var graze_penalty := -10
## Flat Crit modifier during this composure-break effect. Use a negative value for a penalty.
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
