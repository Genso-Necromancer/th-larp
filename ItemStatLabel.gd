extends Label
class_name ItemStatLabel

@export var default := "--"
@export var partner : Label


func update_value(source:SlotWrapper, type: String):
	
	_set_basic_text(source)
	if get_text() == "--": _set_pairing_visibility(false)
	else: _set_pairing_visibility(true)

func _set_pairing_visibility(isVisible: bool):
	visible = isVisible
	partner.visible = isVisible


func _set_basic_text(data:SlotWrapper):
	var key = get_meta("Key")
	var string : String = ""
	if key == "range":
		key = "min_reach"
	if !data or key not in data:
		string = default
	elif key == "min_reach" or key == "max_reach":
		string = _get_range_format(data)
	elif key == "level" and data.personal:
		string = "Unique"
	elif key == "category" and data.sub_group:
		var subTypes : Array = Enums.WEAPON_SUB.keys()
		var types : Array = Enums.WEAPON_CATEGORY.keys()
		var template : String = StringGetter.get_template("dual_type_template")
		var format : Dictionary = {"Type":"","Sub":""}
		string = template
		format.Type = StringGetter.get_string("type_" + str(types[data[key]]).to_snake_case())
		format.Sub = StringGetter.get_string("type_" + str(subTypes[data["sub_group"]]).to_snake_case())
		string = string.format(format)
	elif key == "category":
		var types : Array = Enums.WEAPON_CATEGORY.keys()
		string = StringGetter.get_string("type_" + str(types[data[key]]).to_snake_case())
	elif data[key]: string = str(data[key])
	else: string = default
	set_text(string)


func _get_range_format(data) -> String:
	var minR : int = data["min_reach"]
	var maxR : int = data["max_reach"]
	var format := "%d-%d"
	
	if minR == maxR and minR == 0:
		format = "--"
	elif minR == maxR:
		format = str(minR)
	else:
		format = format % [minR, maxR]
		
	return format
