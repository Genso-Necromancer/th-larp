extends ItemButton

class_name SkillButton


func set_item_text(skill : SlotWrapper):
	var sName := $ContentMargin/HBoxContainer/Name
	var sCost := $ContentMargin/HBoxContainer/Cost
	
	if isIconMode:
		sName.visible = false
		sCost.visible = false
	else:
		sName.visible = true
		sCost.visible = true
	
	sName.set_text(StringGetter.get_skill_name(skill))
	sCost.set_text(str(skill.cost))
	
	
