extends GenericState
class_name GBDefaultState
var gameBoard

func setup(newSlaves):
	super.setup(newSlaves)
	gameBoard = slaves[0]

func mouse_motion(event: InputEvent) -> void:
	gameBoard.gb_mouse_motion(event)
	
func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": gameBoard.select_cell()
		"ui_info": gameBoard.toggle_unit_profile()
		"ui_return": pass
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
		"debugKillLady": gameBoard._kill_lady()
		"debug_camera_test": 
			gameBoard._camera_test()
		"debug_kill_test": gameBoard._kill_camera_test()
