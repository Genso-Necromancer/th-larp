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
	GB_WARP
} #state tags for easy swapping

@onready var gameBoard = $Gameboard #temporarily grabbing Gameboard this way as there is nothing that swaps scenes yet. When scenes can be swapped, defining this would occur during scene swap.
var activeState
var state:= GameState.LOADING: #when this variable is changed to a valid state tag, it does all the work in properly changing the state to streamline coding. See set_new_state function for more.
	set(value):
#		if check_valid_state(value):
			change_state(value)
			state = value
#		else:
#			print("Invalid State")
#			return
var previousState
var newState
var shouldChangeState = false

func _process(delta):
	if shouldChangeState: #delay the change of state by 1 tick. If this is not done, values could be passed as "null", as their definitions have not updated yet. This is a temporary work around due to the skeletal nature of the game currently.
#		shouldChangeState = false
		delayed_state(newState)
		
	
#note on 1 tick delay: I see this not being necessary down the line when the game doesn't go straight to a test map. It is also simple to remove the 1 tick delay once it's no longer needed without rewriting the foundation.

#func _ready():
#	var startScene = preload("res://scenes/start.tscn").instantiate()
#	load_scene(startScene)
#
#func load_scene(scene):
#	add_child(scene)

func _init(): #Occurs when game first launches, sets to loading state
	set_new_state(GameState.LOADING)
	
func _unhandled_input(event: InputEvent) -> void: #Main picks up the inputs, then directs them to the currently active state for processing.
	if event.is_action_pressed("ui_snap"):
		take_screenshot()
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
	shouldChangeState = true
	newState = value

func set_new_state(value): #Value = new State Tag. Call this function, or simply changing the "state" variable from anywhere to change the state properly.
	state = value

func delayed_state(value): #actually changes the state
	var oldState
	var slaves = []
	if activeState != null:
		oldState = activeState
		oldState.queue_free() 
	slaves = _switch_state_get_slaves(value)
	activeState.setup(slaves)

func _switch_state_get_slaves(value): 
	var slaves = []
	match value: #when creating a new state, you must add an entry to this match list
		GameState.LOADING: 
			slaves = [] #array of nodes that listen to the state, used to call their functions
			activeState = LoadingState.new() #the actual state script, remember to change this when making a new one.
		GameState.GB_DEFAULT:
			slaves = [gameBoard]
			activeState = GBDefaultState.new()
		GameState.GB_SELECTED:
			slaves = [gameBoard]
			activeState = GBSelectedState.new()
		GameState.GB_ACTION_MENU:
			slaves = [gameBoard]
			activeState = GBActionMenuState.new()
		GameState.GB_PROFILE:
			slaves = [gameBoard]
			activeState = GBProfileState.new()
		GameState.GB_ATTACK_TARGETING:
			slaves = [gameBoard]
			activeState = GBAttackState.new()
		GameState.GB_COMBAT_FORECAST:
			slaves = [gameBoard]
			activeState = GBForeCastState.new()
		GameState.GB_SKILL_TARGETING:
			slaves = [gameBoard]
			activeState = GBSkillTargetState.new()
		GameState.GB_SKILL_MENU:
			slaves = [gameBoard]
			activeState = GBSkillMenuState.new()
		GameState.GB_ROUND_END:
			slaves = [gameBoard]
			activeState = GBRoundEndState.new()
		GameState.GB_WARP:
			slaves = [gameBoard]
			activeState = GBWarpSelectState.new()
	add_child(activeState)
	return slaves
