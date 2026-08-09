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
	elif key == "close_range":
		key = "close_min_reach"
	elif key == "far_range":
		key = "far_min_reach"
	if !data or key not in data:
		string = default
	elif key == "min_reach" or key == "max_reach":
		string = _get_range_format(data, "min_reach", "max_reach")
	elif key == "close_min_reach" or key == "close_max_reach":
		string = _get_range_format(data, "close_min_reach", "close_max_reach")
	elif key == "far_min_reach" or key == "far_max_reach":
		string = _get_range_format(data, "far_min_reach", "far_max_reach")
	elif key == "charge_value":
		string = "+%dH" % int(data[key]) if int(data[key]) > 0 else default
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


func _get_range_format(data, min_key := "min_reach", max_key := "max_reach") -> String:
	var minR : int = data[min_key]
	var maxR : int = data[max_key]
	var format := "%d-%d"
	
	if minR == maxR and minR == 0:
		format = "--"
	elif minR == 0:
		format = str(maxR)
	elif maxR == 0:
		format = str(minR)
	elif minR == maxR:
		format = str(minR)
	else:
		format = format % [minR, maxR]
		
	return format
