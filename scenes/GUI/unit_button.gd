extends Control
class_name UnitButton

const GRAYSCALE_SHADER := preload("res://scenes/units/unit_palette_shift.gdshader")
const GRAYSCALE_ON := 1.0
const GRAYSCALE_OFF := 0.0

@onready var button = $MarginContainer/TextureButton
@onready var grayscale_nodes: Array[CanvasItem] = [
	$GreenTemplate/PortraitMargin/UnitPortrait,
	$RedWings,
	$BackgroundCenter,
]
var buttonState : StringName


func _ready() -> void:
	_init_grayscale_materials()
	if buttonState != &"":
		_font_state_change(buttonState)



func set_state(state : StringName):
	buttonState = state
	_font_state_change(buttonState)


func temp_font_change(state : StringName = ""):
	if state != "": _font_state_change(state)
	else: _font_state_change(buttonState)


func _font_state_change(state):
	var fColor : Color
	var bgColor : Color
	var labels = [%Name]
	var backGround := $BackgroundWhite
	match state:
		"Deployed": 
			bgColor = Color(1.0, 1.0, 1.0)
			fColor = Color(1,1,1)
			_set_deployment_grayscale(false)
		"Undeployed": 
			bgColor = Color(1.0, 1.0, 1.0)
			fColor = Color(1,1,1)
			_set_deployment_grayscale(true)
		"Forced": 
			bgColor = Color(1.0, 1.0, 1.0)
			fColor = Color(0, 0.62, 0)
			_set_deployment_grayscale(false)
		"Selected": bgColor = Color(1.0, 0.0, 0.0)
			
	if fColor:
		for l in labels:
			l.add_theme_color_override("font_color", fColor)
			l.add_theme_color_override("font_pressed_color", fColor)
			l.add_theme_color_override("font_hover_color", fColor)
			l.add_theme_color_override("font_focus_color", fColor)
			l.add_theme_color_override("font_hover_pressed_color", fColor)
	backGround.set_self_modulate(bgColor)


func _init_grayscale_materials() -> void:
	for node in grayscale_nodes:
		if node == null:
			continue
		var shader_material := ShaderMaterial.new()
		shader_material.shader = GRAYSCALE_SHADER
		shader_material.set_shader_parameter("palette_strength", 0.0)
		shader_material.set_shader_parameter("grayscale_amount", GRAYSCALE_OFF)
		node.material = shader_material


func _set_deployment_grayscale(is_grayscale: bool) -> void:
	if not is_node_ready():
		return
	var amount := GRAYSCALE_ON if is_grayscale else GRAYSCALE_OFF
	for node in grayscale_nodes:
		if node == null or node.material == null:
			continue
		if node.material is ShaderMaterial:
			node.material.set_shader_parameter("grayscale_amount", amount)


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
	var unitLink :Unit= get_unit()
	var n := %Name
	var l := %Lv
	var r := %Role
	var c := %CompCurrent
	var cap := %CompCap
	var texture := $GreenTemplate/PortraitMargin/UnitPortrait
	var unitName :String= unitLink.unit_name
	var spec :String= Enums.SPEC_ID.keys()[unitLink.SPEC_ID]
	var role :String= Enums.ROLE_ID.keys()[unitLink.ROLE_ID]
	spec = StringGetter.get_string("species_name_"+spec.to_snake_case())
	role = StringGetter.get_string("role_name_"+role.to_snake_case())
	var lv :int = unitLink.unit_level
	var comp :int= unitLink.active_stats.Comp
	var current_comp :int= unitLink.current_comp
	var prt :String = unitLink.artPaths.Prt
	
	if prt and ResourceLoader.exists(prt):
		texture.set_texture(load(prt))
	else: texture.set_texture(load("res://sprites/ERROR.png"))
	n.set_text(unitName)
	l.set_text("Lv."+str(lv))
	r.set_text(spec+" "+role)
	c.set_text(str(comp))
	if comp < (comp/2): _change_font_color(c, "Overstressed")
	else: _change_font_color(c)
	cap.set_text(str(current_comp))
