extends VBoxContainer

class_name SkillBox

func fill_skills(unit:Unit) -> Array:
	var skills = unit.unitData.Skills
	var sData = UnitData.skillData
	var sPath = load("res://scenes/GUI/skill_button.tscn")
	var s : SkillButton
	var buttons := []
	#var buttons : Array = []
	for skill in skills:
		s = generate_skillbutton(sPath, sData[skill])
		buttons.append(s.get_button())
		s.get_button().add_to_group("SkillsTT")
		s.set_meta_data(skill, unit, false)
		if !_check_composure(unit, skill): s.state = "Disabled"
		if UnitData.skillData[skill].Augment and !_check_aug(unit, skill): s.state = "Disabled"
		add_child(s)
	buttons[0].call_deferred("grab_focus")
	return buttons
		
		
func generate_skillbutton(path, data) -> SkillButton:
	var b : SkillButton
	b = path.instantiate()
	b.isIconMode = false
	b.set_item_text(data.SkillName, str(data.Cost))
	b.set_item_icon(data.Icon)
	#_connect_focus_signals(b)
	return b
	


func _check_composure(unit : Unit, skill : String) -> bool:
	var valid : bool = unit.has_enough_comp(skill)
	return valid


func _check_aug(unit : Unit, skill : String) -> bool:
	var valid : bool = unit.has_valid_aug_weapon(skill)
	return valid


#func _connect_focus_signals(b:Control):
	#var button = b.get_button()
	#if !isPreview: 
		##button.focus_entered.connect(self._on_focus_entered.bind(b))
		##button.focus_exited.connect(self._on_focus_exited.bind(b))
		#button.mouse_entered.connect(self._on_mouse_entered.bind(b))
		#button.mouse_exited.connect(self._on_mouse_exited.bind(b))
