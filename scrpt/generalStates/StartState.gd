extends GenericState
class_name StartState
var slave

func setup(newSlaves):
	super.setup(newSlaves)
	slave = slaves[0]

#func mouse_motion(event: InputEvent) -> void:
#	slave.gb_mouse_motion(event)
