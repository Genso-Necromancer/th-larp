extends Label


func _process(delta):
	var daddy = get_parent()
	var main = daddy.mainCon
	var state = main.state
	var keys = main.GameState.keys()
	var prevState = main.previousState
	var pString : String
	var cString : String
	if state != null:
		cString = str(keys[state])
	else:
		cString = "--"
	if prevState:
		pString = str(keys[prevState])
	else:
		pString = "--"
		
	self.set_text("State: " + cString + " | " + "Previous State: " + pString)
