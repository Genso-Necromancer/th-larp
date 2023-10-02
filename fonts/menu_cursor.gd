extends TextureRect
signal wep_updated

@export var menu_parent_path : NodePath
@export var cursor_offset : Vector2 = Vector2(25,5)
var currentButton : Button = null

@onready var menu_parent := get_node(menu_parent_path)
var state = 0
@export var ui_cooldown := 0.1
var menuIndex
var cursor_index : int = 0
var shouldUpdateCursor = false

func _process(delta):
	if shouldUpdateCursor:
		set_cursor_from_index(menuIndex)
		shouldUpdateCursor = false

func _input(event: InputEvent) -> void:

	var input := Vector2i.ZERO
	
	if state == 0:
		return

	if event is InputEventKey:

		if event.is_action_pressed("ui_right"):
			input.x += 1
			
		elif event.is_action_pressed("ui_up"):
			input.y -= 1
			
		elif event.is_action_pressed("ui_left"):
			input.x -= 1
			
		elif event.is_action_pressed("ui_down"):
			input.y += 1

		
		match menu_parent.get_class():
			"VBoxContainer":
				set_cursor_from_index(cursor_index + input.y)
			"HBoxContainer":
				set_cursor_from_index(cursor_index + input.x)
			"GridContainer":
				set_cursor_from_index(cursor_index + input.x + input.y * menu_parent.columns)


func focus_shift():
	var i = 0
	for child in menu_parent.get_children():
		if child.has_focus():
			set_cursor_from_index(i)
			return
	i += 1

func get_menu_item_at_index(index : int) -> Control:
	if menu_parent == null:
		return null
	
	if index >= menu_parent.get_child_count() or index < 0:
		return null
	
	return menu_parent.get_child(index) as Control

func update_cursor(index):
	shouldUpdateCursor = true
	menuIndex = index

func set_cursor_from_index(index : int) -> void:
	if index >= menu_parent.get_child_count():
		index = 0
	if index < 0:
		index = menu_parent.get_child_count() - 1
	var menu_item := get_menu_item_at_index(index)
#	
#	print(menu_item)
	if menu_item == null:
		return
	
	var cPosition = menu_item.get_global_position()
	var cSize = menu_item.size
	var newPos
	
	newPos = Vector2(cPosition.x, cPosition.y + cSize.y / 2.0) - (size / 2.0) - cursor_offset
	set_global_position(newPos)
#	print(menu_item.get_global_position(), newPos, get_global_position())
	
	cursor_index = index
	if state == 1:
		Global.activeUnit.unitData.EQUIP = menu_item.get_meta("weaponIndex")
		emit_signal("wep_updated")
		
func mouse_entered(i):
	set_cursor_from_index(i)
		
func set_cursor(button):
	if button == null:
		return
	var cPosition = button.get_global_position()
	var cSize = button.size
	var newPos
	
	newPos = Vector2(cPosition.x, cPosition.y + cSize.y / 2.0) - (size / 2.0) - cursor_offset
	set_global_position(newPos)
	
	if state == 1:
		Global.activeUnit.unitData.EQUIP = button.get_text().get_slice(" [", 0)
		emit_signal("wep_updated")
	
	
