extends Label
class_name LabelValue

@export var key1 : StringName
@export var key2 : StringName
@export var key3 : StringName
@export var pairedIcon : TextureRect
@export_dir var iconDir 
@export var hideIfEmpty: bool = false

var specKeys := Enums.SPEC_ID.keys()
var default : String = get_text()
#var errorThrown := false


func you_need_to_update_yourself_NOW(unit) -> void:
	var newValue
	if unit.get(key1) == null:
		return
	elif unit.get(key1) == null: return
	elif key3: newValue = unit[key1][key2].get(key3, 0)
	elif key2: newValue = unit[key1][key2]
	else: newValue = unit[key1]
	
	if !_check_to_show(newValue): return
	
	if key1 == "Species" or key2 == "Species" or key3 == "Species":
		newValue = StringGetter.get_string("species_name_%s" % [specKeys[newValue].to_snake_case()])
	elif key2 == "Move":
		var typeKeys : Array = Enums.MOVE_TYPE.keys()
		var moveType : String = typeKeys[unit.active_stats.move_type]
		var path = (iconDir + "/" + moveType + ".png").to_snake_case()
		_set_icon(moveType, path)
	elif key1 == "dmkName":
		var template :String = StringGetter.get_template("unit_ownership")
		var masterName = unit.get("master")
		if masterName: masterName = masterName.get("unitName")
		else: masterName = "no_master"
		var stringDick : Dictionary = {"Owner": masterName, "Object":unit[key1]}
		newValue = template.format(stringDick)
	
	newValue = default % [str(newValue)]
	
	set_text(str(newValue))
	


func _set_icon(moveType: StringName, iconPath : String):
	pairedIcon.set_meta("move_type", moveType)
	pairedIcon.set_texture(load(iconPath))


func _check_to_show(value) -> bool:
	if !hideIfEmpty or !get_parent(): return true
	elif get_parent() is not HBoxContainer and get_parent() is not VBoxContainer: return true
	
	if !value: 
		get_parent().visible = false
		return false
	else: 
		get_parent().visible = true
		return true
