extends Control
signal win_finished


func _ready():
	SignalTower.prompt_accepted.connect(self.close_win_screen)

func fade_in_win(): #lol finish this retard
	self.visible = true

func close_win_screen():
	self.visible = false
	emit_signal("win_finished")
