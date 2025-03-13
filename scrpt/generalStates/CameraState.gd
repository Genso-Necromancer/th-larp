extends GenericState
class_name CameraState

	
func _handle_bind(bind):
	
	match bind:
		"invalid": return
		"ui_accept": signalTower.prompt_accepted.emit()
		"debug_kill_test": slave._kill_camera_test()
