extends Label

func _process(_delta):
	set_text("Time: " + str(Global.game_time) + "
	" +"Time Factor: " + str(Global.time_factor))
