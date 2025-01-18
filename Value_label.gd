extends Label
class_name ValueLabel

@export var default := "--"

func update_value(source):
	var type = get_meta("Type")
	
	match type:
		"Unit": _set_basic_text(UnitData.unitData[source])
		"Item": _set_basic_text(UnitData.itemData[source])
		"Skill": _set_basic_text(UnitData.skillData[source])
		"Passive": _set_basic_text(UnitData.passiveData[source])


func _set_basic_text(data):
	var key = get_meta("Key")
	var string : String = ""
	
	if key == "Range":
		key = "MinRange"
	
	if !data or !data.keys().has(key):
		string = default
	elif key == "Effect" and data[key]:
		_set_as_effect(data)
	elif key == "MinRange" or key == "MaxRange":
		string = _get_range_format(data)
	elif key == "Level" and data[key] == -1:
		string = "Unique"
	elif data[key]: string = str(data[key])
	else: string = default
	
	set_text(string)


func _get_range_format(data) -> String:
	var minR : int = data["MinRange"]
	var maxR : int = data["MaxRange"]
	var format := "%d-%d"
	
	if minR == maxR and minR == 0:
		format = "--"
	elif minR == maxR:
		format = str(minR)
	else:
		format = format % [minR, maxR]
		
	return format


func _set_as_effect(data):
	pass
