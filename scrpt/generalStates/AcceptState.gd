extends GenericState
class_name AcceptState
var slave


func setup(newSlaves):
	super.setup(newSlaves)
	slave = slaves[0]
	
func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": emit_signal("prompt_accepted")
		
