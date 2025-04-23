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
	GB_TRADE_TARGETING,
	GB_SKILL_MENU,
	GB_ROUND_END,
	GB_WARP,
	GB_SETUP,
	GB_FORMATION,
	GB_AI_TURN,
	GB_END_OF_ROUND,
	START,
	CAMERA_STATE,
	DIALOGUE_SCENE,
	ACCEPT_PROMPT,
	FAIL_STATE,
	WIN_STATE,
	SCENE_ACTIVE
}



var state:= gState.LOADING #when this variable is changed to a valid state tag, it does all the work in properly changing the state to streamline coding. See set_new_state function for more.
	#set(value):
##		if check_valid_state(value):
			#_swap_state(value)
			#state = value
#		else:
#			print("Invalid State")
#			return

var activeState : GenericState
var activeSlave : Node
var previousState : Array[gState]
var previousSlave : Array[Node]

var shouldChangeState = false


func change_state(newSlave : Node = previousSlave.pop_back(), newState: gState = previousState.pop_back()):
	
	
	previousState.append(state)
	state = newState
	
	
	previousSlave.append(activeSlave)
	activeSlave = newSlave
		
	_free_old()
	_switch_state(state)


func _free_old():
	var oldState
	if activeState:
		oldState = activeState
		oldState.queue_free()

##Value = new State Tag. Call this function, or simply changing the "state" variable from anywhere to change the state properly.
func set_new_state(value): 
	state = value


func clear_state_lists():
	previousSlave.clear()
	previousState.clear()

###This is necessary for the 1 tick delay on state change, it is not called directly so variable change can be the streamlined method.
#func _swap_state(value):
	#var oldState
	#if activeState != null:
		#oldState = activeState
		#oldState.queue_free() 
	#_switch_state(value)
	


func check_valid_state(value): 
	if gState.has(value):
		return true
	else: return false


func _switch_state(value):
	#var stateKeys = gState.keys()
	#var key = stateKeys[value]
	#print("StateChange: ", key)
	match value: #when creating a new state, you must add an entry to this match list
		gState.LOADING: 
			activeState = LoadingState.new() #the actual state script, remember to change this when making a new one.
		gState.GB_DEFAULT:
			
			activeState = GBDefaultState.new()
		gState.GB_SELECTED:
			
			activeState = GBSelectedState.new()
		gState.GB_ACTION_MENU:
			
			activeState = GBActionMenuState.new()
		gState.GB_PROFILE:
			
			activeState = GBProfileState.new()
		gState.GB_ATTACK_TARGETING:
			
			activeState = GBAttackState.new()
		gState.GB_COMBAT_FORECAST:
			
			activeState = GBForeCastState.new()
		gState.GB_SKILL_TARGETING:
			
			activeState = GBSkillTargetState.new()
		gState.GB_TRADE_TARGETING: 
			activeState = GBTradeTargetingState.new()
		gState.GB_SKILL_MENU: #Deprecated
			
			activeState = GBSkillMenuState.new()
		gState.GB_ROUND_END:
			
			activeState = GBRoundEndState.new()
		gState.GB_WARP:
			
			activeState = GBWarpSelectState.new()
		gState.GB_SETUP:
			
			activeState = GBSetUpState.new()
		gState.GB_FORMATION:
			
			activeState = GBFormationState.new()
		gState.GB_AI_TURN:
			
			activeState = AcceptState.new()
		gState.START:
			
			activeState = StartState.new()
		gState.CAMERA_STATE:
			
			activeState = CameraState.new()
		gState.ACCEPT_PROMPT:
			
			activeState = AcceptState.new()
		gState.DIALOGUE_SCENE:
			activeState = AcceptState.new()
		gState.FAIL_STATE:
			
			activeState = FailState.new()
		gState.WIN_STATE:
			
			activeState = AcceptState.new()
		gState.SCENE_ACTIVE:
			
			activeState = AcceptState.new()
		gState.GB_END_OF_ROUND:
			
			activeState = LoadingState.new()
	add_child(activeState)
	activeState.setup(activeSlave)
