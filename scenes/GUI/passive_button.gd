extends ItemButton

class_name PassiveButton


func set_passive_text(data:Dictionary):
	var pName := $HBoxContainer/HBoxContainer/Name
	var pCost := $HBoxContainer/Cost
	var string : String
	var cost := ""
	
	if data.IsTimeSens:
		match Global.timeOfDay:
			Enums.TIME.DAY: string = data.NameDay
			Enums.TIME.NIGHT: string = data.NameNight
	else:
		string = data.Name
	
	pName.set_text(string)
	pCost.set_text(cost)
	
	
func set_passive_icon(data:Dictionary):
	var iconTx := $HBoxContainer/HBoxContainer/Icon
	var icon : String
	if data.IsTimeSens:
		match Global.timeOfDay:
			Enums.TIME.DAY: icon = data.IconDay
			Enums.TIME.NIGHT: icon = data.IconNight
	else:
		icon = data.Icon
	iconTx.set_texture(load(icon))


