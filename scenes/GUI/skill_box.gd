extends VBoxContainer

class_name SkillBox

func fill_skills(unit:Unit) -> Array: #Needs a context check for if a skill is valid to use
	var sPath = load("res://scenes/GUI/skill_button.tscn")
	var s : SkillButton
	var buttons := []
	#var buttons : Array = []
	for skill in unit.skills:
		s = generate_skillbutton(sPath, skill)
		buttons.append(s.get_button())
		s.get_button().add_to_group("SkillsTT")
		s.set_meta_data(skill, unit, false)
		if !_check_composure(unit, skill): s.state = "Disabled"
		if skill.augment and !_check_aug(unit, skill): s.state = "Disabled"
		add_child(s)
	buttons[0].call_deferred("grab_focus")
	return buttons
		
		
func generate_skillbutton(path, data) -> SkillButton:
	var b : SkillButton
	var iconPath : String = "res://sprites/icons/features/%s.png" % [data.id]
	b = path.instantiate()
	b.isIconMode = false
	b.set_item_text(data)
	b.set_item_icon(iconPath)
	#_connect_focus_signals(b)
	return b
	


func _check_composure(unit : Unit, skill : Skill) -> bool:
	var valid : bool = unit.has_enough_comp(skill.cost)
	return valid


func _check_aug(unit : Unit, skill : Skill) -> bool:
	var valid : bool = unit.has_valid_aug_weapon(skill)
	return valid


#func _connect_focus_signals(b:Control):
	#var button = b.get_button()
	#if !isPreview: 
		##button.focus_entered.connect(self._on_focus_entered.bind(b))
		##button.focus_exited.connect(self._on_focus_exited.bind(b))
		#button.mouse_entered.connect(self._on_mouse_entered.bind(b))
		#button.mouse_exited.connect(self._on_mouse_exited.bind(b))
