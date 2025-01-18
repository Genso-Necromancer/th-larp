extends PanelContainer
class_name ItemButton

@onready var button = $ButtonLayer


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

func set_item_text(string : String, durability : String, fSize : int = 0):
	var n = $HBoxContainer/HBoxContainer/Name
	var d = $HBoxContainer/Durability
	n.set_text(string)
	
	d.set_text(durability)
	if fSize:
		n.add_theme_font_size_override("font_size", fSize)
		d.add_theme_font_size_override("font_size", fSize)
	
func set_item_icon(icon : CompressedTexture2D):
	var i = $HBoxContainer/HBoxContainer/Icon
	i.set_texture(icon)
	

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

func set_meta_data(item, unit, index, canTrade):
	set_meta("Item", item)
	set_meta("Unit", unit)
	set_meta("Index", index)
	set_meta("CanTrade", canTrade)
	if item.Equip:
		_set_equipped(true)
		

func _set_equipped(isEquipped):
	var icon = $HBoxContainer/HBoxContainer/Icon/Equpped
	icon.visible = isEquipped
