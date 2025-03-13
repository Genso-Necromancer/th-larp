extends GenericState
class_name StartState


#func mouse_motion(event: InputEvent) -> void:
#	slave.gb_mouse_motion(event)

func _handle_bind(bind):
	
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": 
			pass
			#slave._on_gameboard_toggle_prof()
		"ui_return": 
			pass
			#slave.regress_menu()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
