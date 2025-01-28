extends PanelContainer
class_name ItemButton

@onready var button = $ButtonLayer
@export var type :String = "Item"
var metaSet := false

var disabled := false :
	set(value):
		#var b = $ButtonLayer
		disabled = value
		#b.disabled = value
	get:
		return disabled

var state : String = "Enabled" :
	set(value):
		var newState = _verify_state(value)
		state = newState
		_font_state_change(newState)
	get:
		return state


func _ready():
	_set_button_meta()
	

func set_item_text(string : String, durability : String):
	var n = $HBoxContainer/HBoxContainer/Name
	var d = $HBoxContainer/Durability
	n.set_text(string)
	if durability == "-1":
		durability = ""
	d.set_text(durability)
	
	#if fSize:
		#n.add_theme_font_size_override("font_size", fSize)
		#d.add_theme_font_size_override("font_size", fSize)
	
func set_item_icon(icon : String):
	var i = $HBoxContainer/HBoxContainer/Icon
	i.set_texture(load(icon))
	

func toggle_icon():
	var i = $HBoxContainer/HBoxContainer/Icon
	var vis = i.visible
	i.visible = !vis


func get_button():
	return $ButtonLayer

#func _set_properties(value : String):

func _verify_state(value) -> String:
	var s : String
	var default : String
	if disabled:
		default = "Disabled"
	else:
		default = "Enabled"
	match value:
		"Enabled":
			disabled = false
			s = value
		"Disabled":
			disabled = true
			s = value
		"Selected":
			s = value
		_:
			s = default
	return s


func _font_state_change(value : String):
	var fColor : Color
	var labels = [$HBoxContainer/HBoxContainer/Name, $HBoxContainer/Durability]
	match value:
		"Enabled": fColor = Color(1,1,1)
		"Disabled": fColor = Color(0.278, 0.278, 0.278)
		"Selected": fColor = Color(0.84, 0.84, 0)
	for l in labels:
		l.add_theme_color_override("font_color", fColor)
		l.add_theme_color_override("font_pressed_color", fColor)
		l.add_theme_color_override("font_hover_color", fColor)
		l.add_theme_color_override("font_focus_color", fColor)
		l.add_theme_color_override("font_hover_pressed_color", fColor)

func set_meta_data(item, unit, index, canTrade:=false):
	var isEquipped := false
	if item is Dictionary: set_meta("ID", item.ID)
	else: set_meta("ID", item)
	set_meta("Item", item)
	set_meta("Unit", unit)
	set_meta("Index", index)
	set_meta("CanTrade", canTrade)
	if item is Dictionary and item.Equip:
		isEquipped = true
		_set_equipped(true)
	set_meta("Equipped", isEquipped)
	metaSet = true

func _set_button_meta():
	if metaSet:
		button.set_meta("Type", type)
		button.set_meta("ID", get_meta("ID"))
		button.set_meta("Item", get_meta("Item"))
		button.set_meta("Unit", get_meta("Unit"))
		button.set_meta("Index", get_meta("Index"))
		button.set_meta("CanTrade", get_meta("CanTrade"))
		button.set_meta("Equipped", get_meta("Equipped"))


func _set_equipped(isEquipped):
	var icon = $HBoxContainer/HBoxContainer/Icon/Equpped
	icon.visible = isEquipped
