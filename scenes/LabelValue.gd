extends Label
class_name LabelValue

@export var key1 : StringName
@export var key2 : StringName
@export var key3 : StringName
@export var pairedIcon : TextureRect
@export_dir var iconDir 
@export var hideIfEmpty: bool = false
## Font color when the displayed stat exceeds its neutral reference.
@export var boosted_color := Color("3cb85b")
## Font color when the displayed stat falls below its neutral reference.
@export var reduced_color := Color("e05252")

var _stat_color_active := false
var _had_font_override := false
var _original_font_color := Color.WHITE


var default : String = get_text()
#var errorThrown := false


func you_need_to_update_yourself_NOW(unit:Path2D) -> void:
	var newValue
	match key1:
		"combatData": newValue = unit.get_combat_breakdown(key2).final
		"active_stats","activeStats": newValue = unit.get_stat(key2)
		null: return
		_: if unit.get(key1) != null: newValue = unit[key1]
	
	if !_check_to_show(newValue): return
	_update_stat_color(unit, newValue)
	
	if key1 == "SPEC_ID":
		var specKeys := Enums.SPEC_ID.keys()
		newValue = StringGetter.get_string("species_name_%s" % [specKeys[newValue].to_snake_case()])
	elif key1 == "ROLE_ID":
		var roleKeys := Enums.ROLE_ID.keys()
		newValue = StringGetter.get_string("role_name_%s" % [roleKeys[newValue].to_snake_case()])
	elif key2 == "Move":
		var typeKeys : Array = Enums.MOVE_TYPE.keys()
		var moveType : String = typeKeys[unit.move_type]
		var path = (iconDir + "/" + moveType + ".png").to_snake_case()
		_set_icon(moveType, path)
	elif key1 == "dmkName":
		if unit is not Danmaku: return
		var template :String = StringGetter.get_template("unit_ownership")
		var masterName = unit.get("master")
		if masterName: masterName = masterName.get("unitName")
		else: masterName = "no_master"
		var stringDick : Dictionary = {"Owner": masterName, "Object":unit[key1]}
		newValue = template.format(stringDick)
	
	newValue = default % [str(newValue)]
	#print("Key1: %s Key2: %s newValue: %s" % [key1,key2,newValue])
	set_text(str(newValue))
	


func _update_stat_color(unit: Path2D, value) -> void:
	var neutral
	if unit is Unit and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT):
		match key1:
			"active_stats", "activeStats":
				neutral = unit.get_base_stat(key2)
			"combatData":
				neutral = unit.get_combat_breakdown(key2).base
				if key2 == "Hit":
					var weapon: Weapon = unit.get_equipped_weapon()
					if weapon != null and weapon != unit.unarmed:
						neutral += weapon.hit
	if neutral == null or value == neutral:
		if _stat_color_active:
			if _had_font_override:
				add_theme_color_override("font_color", _original_font_color)
			else:
				remove_theme_color_override("font_color")
			_stat_color_active = false
		return
	if not _stat_color_active:
		_had_font_override = has_theme_color_override("font_color")
		_original_font_color = get_theme_color("font_color")
	_stat_color_active = true
	add_theme_color_override("font_color", boosted_color if value > neutral else reduced_color)


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
