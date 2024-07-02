extends Label

func _process(_delta):
	set_text("Time: " + str(Global.gameTime) + "
	" +"Time Factor: " + str(Global.timeFactor))
