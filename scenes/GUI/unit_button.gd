extends Control
class_name UnitButton


@onready var button = $MarginContainer/TextureButton
var buttonState : StringName


func set_state(state : StringName):
	buttonState = state
	_font_state_change(buttonState)


func temp_font_change(state : StringName = ""):
	if state != "": _font_state_change(state)
	else: _font_state_change(buttonState)


func _font_state_change(state):
	var fColor : Color
	var bgColor : Color
	var labels = [$MarginContainer/HBoxContainer3/HBoxContainer/Name]
	var backGround := $BackgroundWhite
	match state:
		"Deployed": 
			bgColor = Color(1.0, 1.0, 1.0)
			fColor = Color(1,1,1)
		"Undeployed": 
			bgColor = Color(1.0, 1.0, 1.0)
			fColor = Color(0.194, 0.194, 0.194)
		"Forced": 
			bgColor = Color(1.0, 1.0, 1.0)
			fColor = Color(0, 0.62, 0)
		"Selected": bgColor = Color(1.0, 0.0, 0.0)
			
	if fColor:
		for l in labels:
			l.add_theme_color_override("font_color", fColor)
			l.add_theme_color_override("font_pressed_color", fColor)
			l.add_theme_color_override("font_hover_color", fColor)
			l.add_theme_color_override("font_focus_color", fColor)
			l.add_theme_color_override("font_hover_pressed_color", fColor)
	backGround.set_self_modulate(bgColor)


func _change_font_color(label, style : String = "") -> void:
	var fColor : Color
	
	match style:
		"OverStress": fColor = Color(0.678, 0, 0)
		_: 
			
			label.remove_theme_color_override("font_color")
			label.remove_theme_color_override("font_pressed_color")
			label.remove_theme_color_override("font_hover_color")
			label.remove_theme_color_override("font_focus_color")
			label.remove_theme_color_override("font_hover_pressed_color")
			return
	
	label.add_theme_color_override("font_color", fColor)
	label.add_theme_color_override("font_pressed_color", fColor)
	label.add_theme_color_override("font_hover_color", fColor)
	label.add_theme_color_override("font_focus_color", fColor)
	label.add_theme_color_override("font_hover_pressed_color", fColor)


func set_unit(unit:Unit):
	var clicker = $MarginContainer/TextureButton
	clicker.set_meta("Unit", unit)
	refresh_data()


func get_unit() -> Unit:
	var unit : Unit
	var clicker = $MarginContainer/TextureButton
	unit = clicker.get_meta("Unit")
	return unit


func refresh_data():
	var unitLink = get_unit()
	var n = $MarginContainer/HBoxContainer3/HBoxContainer/Name
	var l = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer2/Lv
	var r = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer2/Role
	var c = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer/CompCurrent
	var cap = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer/CompCap
	var texture = $PortraitMargin/TextureRect
	var unitName = unitLink.unitData.Profile.UnitName
	var role = unitLink.unitData.Profile.Role
	var lv = unitLink.unitData.Profile.Level
	var comp = unitLink.unitData.Stats.Comp
	var curComp = unitLink.activeStats.CurComp
	var prt = unitLink.unitData.Profile.Prt
	
	if prt and ResourceLoader.exists(prt):
		texture.set_texture(load(prt))
	else: texture.set_texture(load("res://sprites/ERROR.png"))
	n.set_text(unitName)
	l.set_text("Lv."+str(lv))
	r.set_text(role)
	c.set_text(str(comp))
	if comp < (comp/2): _change_font_color(c, "Overstressed")
	else: _change_font_color(c)
	cap.set_text(str(curComp))
