extends Node

enum gState {
	LOADING,
	GB_DEFAULT,
	GB_SELECTED,
	GB_ACTION_MENU,
	GB_PROFILE,
	GB_ATTACK_TARGETING,
	GB_COMBAT_FORECAST,
	GB_SKILL_TARGETING,
	GB_SKILL_MENU,
	GB_ROUND_END,
	GB_WARP,
	GB_SETUP,
	GB_FORMATION,
	GB_AI_TURN,
	GB_END_OF_ROUND,
	START,
	CAMERA_STATE,
	ACCEPT_PROMPT,
	FAIL_STATE,
	WIN_STATE,
	SCENE_ACTIVE
}

var newSlave : Array = []
var activeState : GenericState
var state:= gState.LOADING: #when this variable is changed to a valid state tag, it does all the work in properly changing the state to streamline coding. See set_new_state function for more.
	set(value):
#		if check_valid_state(value):
			change_state(value)
			state = value
#		else:
#			print("Invalid State")
#			return
var previousState
var previousSlave
var newState
var shouldChangeState = false

##Value = new State Tag. Call this function, or simply changing the "state" variable from anywhere to change the state properly.
func set_new_state(value): 
	state = value

##This is necessary for the 1 tick delay on state change, it is not called directly so variable change can be the streamlined method.
func change_state(value):
	var oldState
	var slaves = []
	if activeState != null:
		oldState = activeState
		oldState.queue_free() 
	slaves = _switch_state_get_slaves(value)
	activeState.setup(slaves)


func check_valid_state(value): 
	if gState.has(value):
		return true
	else: return false


func _switch_state_get_slaves(value):
	var slaves = []
	#var stateKeys = gState.keys()
	#var key = stateKeys[value]
	#print("StateChange: ", key)
	match value: #when creating a new state, you must add an entry to this match list
		gState.LOADING: 
			slaves = newSlave #array of nodes that listen to the state, used to call their functions
			activeState = LoadingState.new() #the actual state script, remember to change this when making a new one.
		gState.GB_DEFAULT:
			slaves = newSlave
			activeState = GBDefaultState.new()
		gState.GB_SELECTED:
			slaves = newSlave
			activeState = GBSelectedState.new()
		gState.GB_ACTION_MENU:
			slaves = newSlave
			activeState = GBActionMenuState.new()
		gState.GB_PROFILE:
			slaves = newSlave
			activeState = GBProfileState.new()
		gState.GB_ATTACK_TARGETING:
			slaves = newSlave
			activeState = GBAttackState.new()
		gState.GB_COMBAT_FORECAST:
			slaves = newSlave
			activeState = GBForeCastState.new()
		gState.GB_SKILL_TARGETING:
			slaves = newSlave
			activeState = GBSkillTargetState.new()
		gState.GB_SKILL_MENU: #Deprecated
			slaves = newSlave
			activeState = GBSkillMenuState.new()
		gState.GB_ROUND_END:
			slaves = newSlave
			activeState = GBRoundEndState.new()
		gState.GB_WARP:
			slaves = newSlave
			activeState = GBWarpSelectState.new()
		gState.GB_SETUP:
			slaves = newSlave
			activeState = GBSetUpState.new()
		gState.GB_FORMATION:
			slaves = newSlave
			activeState = GBFormationState.new()
		gState.GB_AI_TURN:
			slaves = newSlave
			activeState = AcceptState.new()
		gState.START:
			slaves = newSlave
			activeState = StartState.new()
		gState.CAMERA_STATE:
			slaves = newSlave
			activeState = CameraState.new()
		gState.ACCEPT_PROMPT:
			slaves = newSlave
			activeState = AcceptState.new()
		gState.FAIL_STATE:
			slaves = newSlave
			activeState = FailState.new()
		gState.WIN_STATE:
			slaves = newSlave
			activeState = AcceptState.new()
		gState.SCENE_ACTIVE:
			slaves = newSlave
			activeState = AcceptState.new()
		gState.GB_END_OF_ROUND:
			slaves = newSlave
			activeState = LoadingState.new()
	add_child(activeState)
	return slaves
