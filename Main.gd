extends Node
enum GameState {
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
	ACCEPT_PROMPT,
	FAIL_STATE,
	WIN_STATE,
	SCENE_ACTIVE
} #state tags for easy swapping

var gameBoard
var newSlave : Array = []
var activeState : GenericState
var state:= GameState.LOADING: #when this variable is changed to a valid state tag, it does all the work in properly changing the state to streamline coding. See set_new_state function for more.
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

#func _process(delta):
#	if shouldChangeState: #delay the change of state by 1 tick. If this is not done, values could be passed as "null", as their definitions have not updated yet. This is a temporary work around due to the skeletal nature of the game currently.
##		shouldChangeState = false
#		delayed_state(newState)
		
	
#note on 1 tick delay: I see this not being necessary down the line when the game doesn't go straight to a test map. It is also simple to remove the 1 tick delay once it's no longer needed without rewriting the foundation.

func _ready():
	var startScene = preload("res://scenes/start.tscn").instantiate()
#	gameBoard.queue_free()
#	gui.queue_free()
	load_scene(startScene)
	
	
func load_scene(scene):
	add_child(scene)
	
func load_map(map):
	gameBoard.load_new_map(map)

func _init(): #Occurs when game first launches, sets to loading state
	set_new_state(GameState.LOADING)
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	elif Input.is_action_just_pressed("ui_return"):
		get_viewport().set_input_as_handled()
		activeState._handle_bind("ui_return")
		
	
func _unhandled_input(event: InputEvent) -> void: #Main picks up the inputs, then directs them to the currently active state for processing.
	if event.is_action_pressed("ui_snap"):
		take_screenshot()
	if event.is_action_pressed("xml_debug"):
		StringGetter.mash_test()
#	var test = event.action
#
#	print(test)
	if activeState == null:
		return
	if event is InputEventMouseMotion:
		activeState.mouse_motion(event)
	elif event is InputEventMouseButton:
		activeState.mouse_pressed(event)
	elif event is InputEventKey:
		activeState.event_key(event)
		
	
func take_screenshot(): ##ignore this, dev purpose only
	var viewport = get_viewport()
	if viewport:
		await RenderingServer.frame_post_draw
		var screenshot = viewport.get_texture().get_image()
#		var image = ImageTexture.new()
		var tag = 0
		var fileName
		

#		image.create_from_image(screenshot)
		fileName= ("screenshot%s.png" % [tag])
		while is_screenshot_duplicate(fileName):
			tag += 1
			fileName= ("screenshot%s.png" % [tag])
		screenshot.save_png("res://screenshots/screenshot%s.png" % [tag])

func is_screenshot_duplicate(fileName: String) -> bool: 
	var dir := DirAccess.open("res://screenshots/")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file == fileName:
				return true
			else:
				file = dir.get_next()
	return false
## stop ignoring now

func check_valid_state(value): 
	if GameState.has(value):
		return true
	else: return false

func change_state(value): #This is necessary for the 1 tick delay on state change, it is not called directly so variable change can be the streamlined method.
	var oldState
	var slaves = []
	if activeState != null:
		oldState = activeState
		oldState.queue_free() 
	slaves = _switch_state_get_slaves(value)
	activeState.setup(slaves)
	

func set_new_state(value): #Value = new State Tag. Call this function, or simply changing the "state" variable from anywhere to change the state properly.
	state = value



func _switch_state_get_slaves(value): 
	var slaves = []
	var stateKeys = GameState.keys()
	var key = stateKeys[value]
	print("StateChange: ", key)
	match value: #when creating a new state, you must add an entry to this match list
		GameState.LOADING: 
			slaves = newSlave #array of nodes that listen to the state, used to call their functions
			activeState = LoadingState.new() #the actual state script, remember to change this when making a new one.
		GameState.GB_DEFAULT:
			slaves = newSlave
			activeState = GBDefaultState.new()
		GameState.GB_SELECTED:
			slaves = newSlave
			activeState = GBSelectedState.new()
		GameState.GB_ACTION_MENU:
			slaves = newSlave
			activeState = GBActionMenuState.new()
		GameState.GB_PROFILE:
			slaves = newSlave
			activeState = GBProfileState.new()
		GameState.GB_ATTACK_TARGETING:
			slaves = newSlave
			activeState = GBAttackState.new()
		GameState.GB_COMBAT_FORECAST:
			slaves = newSlave
			activeState = GBForeCastState.new()
		GameState.GB_SKILL_TARGETING:
			slaves = newSlave
			activeState = GBSkillTargetState.new()
		GameState.GB_SKILL_MENU:
			slaves = newSlave
			activeState = GBSkillMenuState.new()
		GameState.GB_ROUND_END:
			slaves = newSlave
			activeState = GBRoundEndState.new()
		GameState.GB_WARP:
			slaves = newSlave
			activeState = GBWarpSelectState.new()
		GameState.GB_SETUP:
			slaves = newSlave
			activeState = GBSetUpState.new()
		GameState.GB_FORMATION:
			slaves = newSlave
			activeState = GBFormationState.new()
		GameState.GB_AI_TURN:
			slaves = newSlave
			activeState = AcceptState.new()
		GameState.START:
			slaves = newSlave
			activeState = StartState.new()
		GameState.ACCEPT_PROMPT:
			slaves = newSlave
			activeState = AcceptState.new()
		GameState.FAIL_STATE:
			slaves = newSlave
			activeState = FailState.new()
		GameState.WIN_STATE:
			slaves = newSlave
			activeState = AcceptState.new()
		GameState.SCENE_ACTIVE:
			slaves = newSlave
			activeState = AcceptState.new()
		GameState.GB_END_OF_ROUND:
			slaves = newSlave
			activeState = LoadingState.new()
	add_child(activeState)
	return slaves

func on_load_map_manager(map):
	var manager = preload("res://scenes/map_manager.tscn").instantiate()
	load_scene(manager)
	$mapManager.load_map(map)
	
#func set_map(map):
	#gameBoard = $mapManager/Gameboard
	#gameBoard.change_map(map)

func unload_me(scene):
	scene.queue_free()
	

