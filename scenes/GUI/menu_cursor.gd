extends TextureRect
class_name MenuCursor


@export var cursor_offset : Vector2 = Vector2(25,5)

var currentButton : Button = null
var setCursor := false
var menu_parent


func _process(_delta):
	if setCursor:
		setCursor = false
		call_deferred("set_cursor")


		
func set_cursor(button = get_viewport().gui_get_focus_owner()):
	
	var cPosition = button.get_global_position()
	var cSize = button.size
	var newPos
	newPos = Vector2(cPosition.x, cPosition.y + cSize.y / 2.0) - (size / 2.0) - cursor_offset
	set_global_position(newPos)
	
func toggle_visible():
	var isVisible = visible
	visible = !isVisible
	

func resignal_cursor(buttons: Array):
	var focus = false
	var firstVis = false
	visible = true
	for b in buttons:
		_connect_btn_to_cursor(b)
		if !b.disabled and b.visible and !focus: focus = b
		elif !firstVis and b.visible: 
			firstVis = b
	if !focus and firstVis: 
		focus = firstVis
	focus.call_deferred("grab_focus")


func _connect_btn_to_cursor(b):
	if b.mouse_entered.is_connected(self._on_mouse_entered.bind(b)): #incase of order switching, this must be reconnected
		b.mouse_entered.disconnect(self._on_mouse_entered.bind(b))
	b.mouse_entered.connect(self._on_mouse_entered.bind(b))
	if b.focus_entered.is_connected(self.set_cursor.bind(b)): #incase of order switching, this must be reconnected
		b.focus_entered.disconnect(self.set_cursor.bind(b))
	b.focus_entered.connect(self.set_cursor.bind(b))


func _on_mouse_entered(b):
	b.call_deferred("grab_focus")
