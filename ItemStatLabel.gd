extends Label
class_name ItemStatLabel

@export var default := "--"
@export var partner : Label


func update_value(source, type: String):
	
	match type:
		"Item": 
			_set_basic_text(UnitData.itemData[source])
		"Skill": 

			_set_basic_text(UnitData.skillData[source])
			
	if get_text() == "--": _set_pairing_visibility(false)
	else: _set_pairing_visibility(true)

func _set_pairing_visibility(isVisible: bool):
	visible = isVisible
	partner.visible = isVisible


func _set_basic_text(data):
	var key = get_meta("Key")
	var string : String = ""
	
	if key == "Range":
		key = "MinRange"
	
	if !data or !data.keys().has(key):
		string = default
	elif key == "MinRange" or key == "MaxRange":
		string = _get_range_format(data)
	elif key == "Level" and data[key] == -1:
		string = "Unique"
	elif key == "Category": string = StringGetter.get_string("type_" + str(data[key]).to_snake_case())
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
