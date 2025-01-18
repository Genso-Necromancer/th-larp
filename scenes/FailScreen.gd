extends Control
signal fail_finished

func _ready():
	SignalTower.prompt_accepted.connect(self.close_fail_screen)

func fade_in_failure(): #lol finish this retard
	self.visible = true
	
func close_fail_screen():
	if self.visible: 
		self.visible = false
		emit_signal("fail_finished")
