extends GenericState
class_name GBFormationState

	
func mouse_motion(event: InputEvent) -> void:
	slave.gb_mouse_motion(event)

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": slave.select_formation_cell()
		"ui_info": slave.toggle_unit_profile()
		"ui_return": slave.deselect_formation_cell()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": 
			direction = Vector2i.RIGHT
			slave.on_directional_press(direction)
		"ui_up": 
			direction = Vector2i.UP
			slave.on_directional_press(direction)
		"ui_left": 
			direction = Vector2i.LEFT
			slave.on_directional_press(direction)
		"ui_down": 
			direction = Vector2i.DOWN
			slave.on_directional_press(direction)
