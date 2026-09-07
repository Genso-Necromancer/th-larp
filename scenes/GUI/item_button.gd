extends PanelContainer
class_name ItemButton


@export var type :String = "Item"
@export var isIconMode := false
@export_category("FontColors")
@export_group("Enabled")
@export var eFont : Color 
@export var efFont : Color
@export var ehFont : Color
@export var epFont : Color
@export_group("Disabled")
@export var dFont : Color
@export var dfFont : Color
@export var dhFont : Color
@export var dpFont : Color
@export_group("Selected")
@export var sFont : Color
@export var sfFont : Color
@export var shFont : Color
@export var spFont : Color

@onready var button = $ButtonLayer

var useBorder := false
var metaSet := false

var disabled := false :
	set(value):
		disabled = value
		if is_node_ready():
			button.disabled = value
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
	button.focus_entered.connect(self._on_focus_entered)
	button.focus_exited.connect(self._on_focus_exited)
	button.disabled = disabled
	_make_noninteractive_layers_ignore_mouse()
	_set_button_meta()
	if  get_meta("Item") and get_meta("Item") is String: pass
	elif get_meta("Item") and get_meta("Item").id == "unarmed":
		toggle_icon()


func set_item_text(item : SlotWrapper):
	var n: Control = _get_name_label()
	var d: Control = _get_detail_label()
	if n == null:
		return
	var durString
	var dur : int = item.dur
	var mDur : int = item.max_dur
	
	if !item.breakable:
		durString = str(" --")
	elif mDur == -1:
		durString = ""
	else:
		durString = (str(dur) + "/" + str(mDur))
	n.set_text(StringGetter.get_item_name(item))
	if d:
		d.set_text(durString)


func set_blank_item():
	var n: Control = _get_name_label()
	var d: Control = _get_detail_label()
	if n:
		n.set_text("")
	if d:
		d.set_text("")


func set_item_icon(icon_path : String):
	var i = $ContentMargin/HBoxContainer/Icon
	if ResourceLoader.exists(icon_path):
		i.set_texture(load(icon_path))
	else:
		#print("item_button/set_item_icon: invalid icon path[", icon_path,"]")
		i.set_texture(load("res://sprites/icons/items/missing_item.png"))


func toggle_icon():
	var i = $ContentMargin/HBoxContainer/Icon
	var vis = i.visible
	i.visible = !vis


func get_button():
	return $ButtonLayer

#func _set_properties(value : String):

func _verify_state(value) -> String:
	var s : String
	var default : String
	var panel := $Selected
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
	panel.visible = true if s == "Selected" else false
	return s


func _font_state_change(value : String):
	var font_colors := {}
	var labels := []
	var name_label: Control = _get_name_label()
	var detail_label: Control = _get_detail_label()
	if name_label:
		labels.append(name_label)
	if detail_label:
		labels.append(detail_label)
	match value:
		"Enabled": 
			font_colors = _get_font_color_set(eFont, efFont, ehFont, epFont)
		"Disabled":
			font_colors = _get_font_color_set(dFont, dfFont, dhFont, dpFont)
		"Selected": 
			font_colors = _get_font_color_set(sFont, sfFont, shFont, spFont)
			
	for l in labels:
		for color_key in font_colors:
			l.add_theme_color_override(color_key, font_colors[color_key])


func _get_font_color_set(base: Color, focus: Color, hover: Color, pressed: Color) -> Dictionary:
	return {
		"font_color": base,
		"font_focus_color": focus,
		"font_hover_color": hover,
		"font_pressed_color": pressed,
		"font_hover_pressed_color": pressed,
	}


func _get_name_label() -> Control:
	return get_node_or_null("ContentMargin/HBoxContainer/Name")


func _get_detail_label() -> Control:
	var durability = get_node_or_null("ContentMargin/HBoxContainer/Durability")
	if durability:
		return durability
	return get_node_or_null("ContentMargin/HBoxContainer/Cost")

func set_meta_data(item, unit, index, canTrade:=false):
	var isEquipped := false
	if item is Dictionary: set_meta("ID", item.ID)
	else: set_meta("ID", item)
	set_meta("Item", item)
	set_meta("Unit", unit)
	set_meta("Index", index)
	set_meta("CanTrade", canTrade)
	if item is Item and item.equipped:
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
	var icon = $ContentMargin/HBoxContainer/Icon/Equpped
	icon.visible = isEquipped


func _on_focus_entered():
	if useBorder:
		var focusBorder := $FocusBorder
		focusBorder.visible = true


func _on_focus_exited():
	if useBorder:
		var focusBorder := $FocusBorder
		focusBorder.visible = false


func _make_noninteractive_layers_ignore_mouse() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ignore_nodes := [
		get_node_or_null("FocusBorder"),
		get_node_or_null("ContentMargin"),
		get_node_or_null("ContentMargin/HBoxContainer"),
		get_node_or_null("ContentMargin/HBoxContainer/Icon"),
		get_node_or_null("ContentMargin/HBoxContainer/Icon/Equpped"),
		get_node_or_null("ContentMargin/HBoxContainer/Name"),
		get_node_or_null("ContentMargin/HBoxContainer/Durability"),
		get_node_or_null("ContentMargin/HBoxContainer/Cost"),
	]
	for node in ignore_nodes:
		if node is Control:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE

##Inserts it's own data, only intended for use in focus viewer
func fill_yourself(unit:Unit) ->void:
	var item = unit.get_equipped_weapon()
	var dur = item.dur
	var mDur = item.max_dur
	var durString
	var iconPath : String = "res://sprites/icons/items/%s/%s.png"
	var folder : String
	if item is Weapon: folder = "weapon"
	elif item is Accessory: folder = "accessory"
	elif item is Ofuda: folder = "ofuda"
	elif item is Consumable: folder = "consumable"
	iconPath = iconPath % [folder, item.id]
	set_item_text(item)
	set_item_icon(item.id)
	#set_meta_data(item, unit, i, item.trade)
	get_button().add_to_group("ItemTT")
	#if isTrade and !item.trade:
		#b.state = "Disabled"
	#elif _style == _styles[1] and !unit.check_valid_equip(item):
		#b.state = "Disabled"
	#return b
