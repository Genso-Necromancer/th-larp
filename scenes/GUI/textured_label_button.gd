@tool
extends PanelContainer
class_name TextureLabelButton
signal button_focus_entered(button:TextureButton)
signal button_mouse_entered(button:TextureButton)
signal button_pressed(button:TextureLabelButton)
signal key_input(event:InputEvent)
@onready var label : RichTextLabel = %ButtonText
@onready var icon : TextureRect = $ContentsHBox/Icon
@onready var background : TextureRect = $ButtonBackground
@onready var button : TextureButton = $TextureButton
@onready var highlight : TextureRect = $ButtonHighlight
@export var label_text : String = "Null":
	set(value):
		label_text = value
		if is_node_ready(): _set_label_text(value)
@export var icon_texture : CompressedTexture2D:
	set(value):
		icon_texture = value
		if is_node_ready(): _set_icon(value)
@export var background_texture:CompressedTexture2D:
	set(value):
		background_texture = value
		if is_node_ready(): _set_background(value)
@export var highlight_border:CompressedTexture2D:
	set(value):
		highlight_border = value
		if is_node_ready(): _set_highlight(value)
@export var font_override:= 0:
	set(value):
		if value > 0: %ButtonText.add_theme_font_size_override("normal_font_size", value)
		elif %ButtonText.has_theme_font_size_override("normal_font_size"): %ButtonText.remove_theme_font_size_override("normal_font_size")
		font_override = value


func _ready():
	_set_label_text(label_text)
	_set_icon(icon_texture)
	_set_background(background_texture)
	_set_highlight(highlight_border)


func _set_icon(texture : CompressedTexture2D) -> void:
	if texture == null: icon.visible = false
	else:
		icon.visible = true
		icon.set_texture(texture)


func _set_label_text(text:String) ->void:
	label.set_text(text)


func _set_background(texture:CompressedTexture2D) -> void:
	background.set_texture(texture)


func _set_highlight(texture:CompressedTexture2D) -> void:
	highlight.set_texture(texture)


func set_neighbor(side:Side, neighbor:Control) -> void:
	var path :NodePath= button.get_path_to(neighbor)
	button.set_focus_neighbor(side,path)


func _on_texture_button_focus_entered():
	button_focus_entered.emit(button)
	if highlight_border: highlight.visible = true


func _on_texture_button_focus_exited():
	if highlight_border: highlight.visible = false


func _on_texture_button_mouse_entered():
	button_mouse_entered.emit(button)


func _on_texture_button_pressed():
	button_pressed.emit(self)


func _on_texture_button_gui_input(event):
	if event is InputEventKey: key_input.emit(event)
