extends MarginContainer

class_name ItemDisplay


func update_stat_values(control:Control):
	get_tree().call_group("ValueLabels", "update_value", control.get_meta("ID"), control.get_meta("Type"))
	_check_extra_params(control.get_meta("ID"), control.get_meta("Type"))

func _check_extra_params(id:String, type:String):
	var efftag := $ToolTipVBox/StatPanel/VBoxContainer/EffectTitleBox
	var data:Dictionary
	match type:
		"Item": data = UnitData.itemData[id]
		"Skill": data = UnitData.skillData[id]
	if data.get("Effects",false): efftag.visible = true
	else: efftag.visible = false
	
