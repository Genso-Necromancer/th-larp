extends MarginContainer

class_name ItemDisplay


func update_stat_values(control:Control):
	var id = control.get_meta("ID")
	get_tree().call_group("ValueLabels", "update_value", control.get_meta("ID"), control.get_meta("Type"))
	_check_extra_params(control.get_meta("ID"))

func _check_extra_params(data:SlotWrapper):
	var efftag := $ToolTipVBox/StatPanel/VBoxContainer/EffectTitleBox
	if data.effects: efftag.visible = true
	else: efftag.visible = false
