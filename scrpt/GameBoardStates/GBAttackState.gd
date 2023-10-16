extends GenericState
class_name GBAttackState
var gameBoard

func setup(newSlaves):
	super.setup(newSlaves)
	gameBoard = slaves[0]
	
func mouse_motion(event: InputEvent) -> void:
	gameBoard.gb_mouse_motion(event)

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": gameBoard.attack_target_selected()
		"ui_info": gameBoard.toggle_unit_profile()
		"ui_return": gameBoard.menu_step_back()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": 
			direction = Vector2.RIGHT
			gameBoard.on_directional_press(direction)
		"ui_up": 
			direction = Vector2.UP
			gameBoard.on_directional_press(direction)
		"ui_left": 
			direction = Vector2.LEFT
			gameBoard.on_directional_press(direction)
		"ui_down": 
			direction = Vector2.DOWN
			gameBoard.on_directional_press(direction)
