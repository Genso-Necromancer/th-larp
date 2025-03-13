extends GenericState
class_name AcceptState

	
func _handle_bind(bind):
	
	match bind:
		"invalid": return
		"ui_accept": signalTower.prompt_accepted.emit()
		
	
