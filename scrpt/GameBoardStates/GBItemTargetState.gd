extends GenericState
class_name GBItemTargetState


func mouse_motion(event: InputEvent) -> void:
	slave.gb_mouse_motion(event)

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": slave.item_target_selected()
		"ui_info": slave.toggle_unit_profile()
		"ui_return": slave.end_targeting()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": 
			direction = Vector2.RIGHT
			slave.on_directional_press(direction)
		"ui_up": 
			direction = Vector2.UP
			slave.on_directional_press(direction)
		"ui_left": 
			direction = Vector2.LEFT
			slave.on_directional_press(direction)
		"ui_down": 
			direction = Vector2.DOWN
			slave.on_directional_press(direction)
