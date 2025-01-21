extends Label
class_name LabelValue

@export var key1 : StringName
@export var key2 : StringName
@export var key3 : StringName
@export var pairedIcon : TextureRect
@export_dir var iconDir 

var specKeys := Enums.SPEC_ID.keys()
var default : String = get_text()


func you_need_to_update_yourself_NOW(unit):
	var newValue
	if key3: newValue = unit[key1][key2][key3]
	elif key2: newValue = unit[key1][key2]
	else: newValue = unit[key1]
	
	if key1 == "Species" or key2 == "Species" or key3 == "Species":
		newValue = StringGetter.get_string("species_name_%s" % [specKeys[newValue].to_snake_case()])
	elif key2 == "Move":
		var typeKeys : Array = Enums.MOVE_TYPE.keys()
		var moveType : String = typeKeys[unit[key1]["MoveType"]]
		var path = (iconDir + "/" + moveType + ".png").to_snake_case()
		_set_icon(moveType, path)
	newValue = default % [str(newValue)]
	set_text(str(newValue))

func _set_icon(moveType: StringName, iconPath : String):
	pairedIcon.set_meta("MoveType", moveType)
	pairedIcon.set_texture(load(iconPath))
