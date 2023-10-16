extends GenericState
class_name GBActionMenuState
var gameBoard

func setup(newSlaves):
	super.setup(newSlaves)
	gameBoard = slaves[0]

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": gameBoard.toggle_unit_profile()
		"ui_return": gameBoard.request_deselect()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
