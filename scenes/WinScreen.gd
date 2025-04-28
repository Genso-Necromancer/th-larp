extends Control
signal win_finished


func _gui_input(event):
	if GameState.activeState == null:
			return
	if event is InputEventMouseMotion:
		GameState.activeState.mouse_motion(event)
	elif event is InputEventMouseButton:
		GameState.activeState.mouse_pressed(event)
	elif event is InputEventKey:
		GameState.activeState.event_key(event)


func gui_accept():
	close_win_screen()

func fade_in_win(): #lol finish this retard
	visible = true
	GameState.change_state(self, GameState.gState.WIN_STATE)

func close_win_screen():
	if visible:
		visible = false
		emit_signal("win_finished")
