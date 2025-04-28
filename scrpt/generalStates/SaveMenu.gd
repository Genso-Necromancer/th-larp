extends GenericState
class_name SaveMenuState

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": slave.accept_prompt()
		"ui_return" : slave.return_pressed()
