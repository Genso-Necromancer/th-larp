extends ItemButton

class_name SkillButton


func set_item_text(string : String, cost: String = ""):
	var sName := $HBoxContainer/HBoxContainer/Name
	var sCost := $HBoxContainer/Cost
	
	
	sName.set_text(string)
	sCost.set_text(cost)
	
	
func set_meta_data(skill, unit, index, _canTrade):
	set_meta("Skill", skill)
	set_meta("Unit", unit)
	set_meta("Index", index)
	
