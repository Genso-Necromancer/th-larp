extends GenericState
class_name GBProfileState


func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": slave.toggle_tooltips()
		"ui_return": slave.toggle_profile()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
