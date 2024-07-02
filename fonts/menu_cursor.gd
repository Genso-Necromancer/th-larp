extends TextureRect
signal wep_updated
signal jobs_done_crs


@export var cursor_offset : Vector2 = Vector2(25,5)
#@export var ui_cooldown := 0.1

var currentButton : Button = null
var menu_parent
var menuIndex
var cursor_index : int = 0
var shouldUpdateCursor = false
var currentFocus

func _ready():
	var parent = get_parent()
	self.jobs_done_crs.connect(parent._on_jobs_done)
	emit_signal("jobs_done_crs", "Cursor", self)

#func _process(delta):
	#if shouldUpdateCursor:
##		set_cursor_from_index(menuIndex)
		#set_cursor(currentFocus)
		#shouldUpdateCursor = false

#func _input(event: InputEvent) -> void:
#
#	var input := Vector2i.ZERO
#
#	if state == 0:
#		return
#
#	if event is InputEventKey:
#
#		if event.is_action_pressed("ui_right"):
#			input.x += 1
#
#		elif event.is_action_pressed("ui_up"):
#			input.y -= 1
#
#		elif event.is_action_pressed("ui_left"):
#			input.x -= 1
#
#		elif event.is_action_pressed("ui_down"):
#			input.y += 1
#
#
#		match menu_parent.get_class():
#			"VBoxContainer":
#				set_cursor_from_index(cursor_index + input.y)
#			"HBoxContainer":
#				set_cursor_from_index(cursor_index + input.x)
#			"GridContainer":
#				set_cursor_from_index(cursor_index + input.x + input.y * menu_parent.columns)


#func focus_shift():
#
#	var i = 0
#	for child in menu_parent.get_children():
#		if child.has_focus():
#			set_cursor_from_index(i)
#			return
#	i += 1
#
#func get_menu_item_at_index(index : int) -> Control:
#	if menu_parent == null:
#		return null
#
#	if index >= menu_parent.get_child_count() or index < 0:
#		return null
#
#	return menu_parent.get_child(index) as Control
#
#func update_cursor(b):
	#shouldUpdateCursor = true
	#currentFocus = b
#
#func set_cursor_from_index(index : int) -> void:
#	if index >= menu_parent.get_child_count():
#		index = 0
#	if index < 0:
#		index = menu_parent.get_child_count() - 1
#	var menu_item := get_menu_item_at_index(index)
##	
##	print(menu_item)
#	if menu_item == null:
#		return
#	menu_item.grab_focus()
#	var cPosition = menu_item.get_global_position()
#	var cSize = menu_item.size
#	var newPos
#
#	newPos = Vector2(cPosition.x, cPosition.y + cSize.y / 2.0) - (size / 2.0) - cursor_offset
#	set_global_position(newPos)
##	print(menu_item.get_global_position(), newPos, get_global_position())
#
#	cursor_index = index
##	if state == 1:
##		Global.activeUnit.unitData.EQUIP = menu_item.get_meta("weaponIndex")
##		emit_signal("wep_updated")
#
#func _on_mouse_entered(i):
#	set_cursor_from_index(i)
		
func set_cursor(button):
	currentFocus = button
	if button == null:
		return
	var cPosition = button.get_global_position()
	var cSize = button.size
	var newPos
	newPos = Vector2(cPosition.x, cPosition.y + cSize.y / 2.0) - (size / 2.0) - cursor_offset
	set_global_position(newPos)
	#print("set_cursor: ")
	#print("-Button: " + str(cPosition))
	#print("-Cursor: " + str(newPos))
	
	#if !button.has_focus():
		#button.grab_focus()
	
#	if state == 1:
#		Global.activeUnit.unitData.EQUIP = button.get_text().get_slice(" [", 0)
#		emit_signal("wep_updated")
	
	
