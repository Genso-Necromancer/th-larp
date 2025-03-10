extends GenericState
class_name CameraState
var slave


func setup(newSlaves):
	super.setup(newSlaves)
	slave = slaves[0]
	
func _handle_bind(bind):
	
	match bind:
		"invalid": return
		"ui_accept": signalTower.prompt_accepted.emit()
		"debug_kill_test": slave._kill_camera_test()
