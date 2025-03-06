extends ItemButton

class_name SkillButton


func set_item_text(string : String, cost: String = ""):
	var sName := $ContentMargin/HBoxContainer/Name
	var sCost := $ContentMargin/HBoxContainer/Cost
	
	if isIconMode:
		sName.visible = false
		sCost.visible = false
	else:
		sName.visible = true
		sCost.visible = true
	
	sName.set_text(string)
	sCost.set_text(cost)
	
	

