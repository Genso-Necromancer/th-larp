extends GenericState
class_name GBSkillMenuState
var gameBoard

func setup(newSlaves):
	super.setup(newSlaves)
	gameBoard = slaves[0]

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": pass
		"ui_return": gameBoard.menu_step_back()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
