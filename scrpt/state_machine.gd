extends Node
class_name StateMachine

var state = null:
	get:
		return state
	set(value):
		state = value
var previousState = null
var states = {}

@onready var parent = get_parent()


func _state_logic(delta):
	pass
	

func _get_transition(delta):
	return


func _enter_state(newState, oldState):
	pass
	

func _exit_state(oldState, newState):
	pass
	

func set_state(newState):
	previousState = state
	state = newState
	
	if previousState != null:
		_exit_state(previousState, newState)
		
	if newState != null:
		_enter_state(newState, previousState)


func add_state(stateName):
	states[stateName] = states.size()
