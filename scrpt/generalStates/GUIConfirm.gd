extends GenericState
class_name GUIConfirm

	
func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": slave.gui_accept()
		
	
