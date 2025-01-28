extends ItemButton

class_name SkillButton


func set_item_text(string : String, cost: String = ""):
	var sName := $HBoxContainer/HBoxContainer/Name
	var sCost := $HBoxContainer/Cost
	
	
	sName.set_text(string)
	sCost.set_text(cost)
	
	

