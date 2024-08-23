extends Control
signal win_finished



func fade_in_win(): #lol finish this retard
	self.visible = true

func close_win_screen():
	self.visible = false
	emit_signal("win_finished")
