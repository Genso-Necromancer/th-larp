extends GenericState
class_name GBForeCastState
var slave

func setup(newSlaves):
	super.setup(newSlaves)
	slave = slaves[0]
	print(str(slaves))

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": pass
		"ui_return": slave.cancel_forecast()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
