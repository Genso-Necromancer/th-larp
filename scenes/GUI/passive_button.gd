extends ItemButton

class_name PassiveButton


func set_passive_text(data:Passive):
	var pName := $HBoxContainer2/Name
	var pCost := $HBoxContainer2/Cost
	var string : String
	var cost := ""
	
	if isIconMode:
		pName.visible = false
		pCost.visible = false
	else:
		pName.visible = true
		pCost.visible = true
	
	
	if data.is_time_sens:
		match Global.timeOfDay:
			Enums.TIME.DAY: string = data.day_id
			Enums.TIME.NIGHT: string = data.night_id
	else:
		string = data.id
	string = StringGetter.get_string("passive_name_%s" % [string]) 
	pName.set_text(string)
	pCost.set_text(cost)
	
	
func set_passive_icon(data:Passive):
	var iconTx := $HBoxContainer2/Icon
	var icon : String
	var iconPath := "res://sprites/icons/features/%s_.png"
	if data.is_time_sens:
		match Global.timeOfDay:
			Enums.TIME.DAY: icon = data.day_id
			Enums.TIME.NIGHT: icon = data.night_id
	else:
		icon = data.id
	iconPath = iconPath % [icon]
	if ResourceLoader.exists(iconPath):
		iconTx.set_texture(load(iconPath))
	else:
		print("item_button/set_item_icon: invalid icon path[", iconPath,"]")
		iconTx.set_texture(load("res://sprites/icons/items/missing_item.png"))
	
