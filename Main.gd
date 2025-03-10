extends Node
#enum GameState {
	#LOADING,
	#GB_DEFAULT,
	#GB_SELECTED,
	#GB_ACTION_MENU,
	#GB_PROFILE,
	#GB_ATTACK_TARGETING,
	#GB_COMBAT_FORECAST,
	#GB_SKILL_TARGETING,
	#GB_SKILL_MENU,
	#GB_ROUND_END,
	#GB_WARP,
	#GB_SETUP,
	#GB_FORMATION,
	#GB_AI_TURN,
	#GB_END_OF_ROUND,
	#START,
	#ACCEPT_PROMPT,
	#FAIL_STATE,
	#WIN_STATE,
	#SCENE_ACTIVE
#} #state tags for easy swapping

static var root := "user://"
static var gameFolder := "thLARP"
static var dataDir := root + gameFolder

var gameBoard
#var newSlave : Array = []
#var GameState.gState.activeState : GenericState
#var state:= GameState.gState.LOADING: #when this variable is changed to a valid state tag, it does all the work in properly changing the state to streamline coding. See set_new_state function for more.
	#set(value):
##		if check_valid_state(value):
			#change_state(value)
			#state = value
##		else:
##			print("Invalid State")
##			return
#var previousState
#var previousSlave
#var newState
#var shouldChangeState = false

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
	_check_directory()
	
func load_scene(scene):
	add_child(scene)
	
func load_map(map):
	gameBoard.load_new_map(map)

func _init(): #Occurs when game first launches, sets to loading state
	GameState.set_new_state(GameState.gState.LOADING)
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	elif Input.is_action_just_pressed("ui_return"):
		get_viewport().set_input_as_handled()
		GameState.activeState._handle_bind("ui_return")
	elif Input.is_action_just_pressed("debug_mode"):
		Global.flags.DebugMode = !Global.flags.DebugMode
		print("Debug: ", Global.flags.DebugMode)
	elif Input.is_action_just_pressed("debug_camera_test") and !Global.flags.DebugMode:
		return
	elif Input.is_action_just_pressed("debug_kill_test") and !Global.flags.DebugMode:
		return
	
func _unhandled_input(event: InputEvent) -> void: #Main picks up the inputs, then directs them to the currently active state for processing.
	if event.is_action_pressed("ui_snap"):
		take_screenshot()
	if event.is_action_pressed("xml_debug"):
		StringGetter.mash_test()
#	var test = event.action
#
#	print(test)
	if GameState.activeState == null:
		return
	if event is InputEventMouseMotion:
		GameState.activeState.mouse_motion(event)
	elif event is InputEventMouseButton:
		GameState.activeState.mouse_pressed(event)
	elif event is InputEventKey:
		GameState.activeState.event_key(event)


func _check_directory():
	if not DirAccess.dir_exists_absolute(dataDir):
		var dir = DirAccess.open(root)
		dir.make_dir(gameFolder)
	


func _create_director(newDir : String) -> String:
	var filePath : String = dataDir + "/" + newDir
	var newPath : String
	
	if not DirAccess.dir_exists_absolute(filePath):
		var dir = DirAccess.open(dataDir)
		dir.make_dir(newDir)
		
	newPath = filePath + "/"
	
	return newPath


	
func take_screenshot(): ##ignore this, dev purpose only
	var viewport = get_viewport()
	var newDir := "screenshots"
	var screenShotDir := _create_director(newDir)
	if viewport:
		await RenderingServer.frame_post_draw
		var screenshot = viewport.get_texture().get_image()
#		var image = ImageTexture.new()
		var tag = 0
		var fileName
		var time = str(Time.get_unix_time_from_system())
		fileName = ("screenshot_" + time + ".png")
		while is_file_duplicate(screenShotDir, fileName):
			fileName = ("screenshot_"+ time + tag + ".png")
			tag += 1
		screenshot.save_png(screenShotDir + fileName)
		if is_file_duplicate(screenShotDir, fileName):
			print("ScreenShot:[",fileName,"]", " Saved to:[", screenShotDir,"]",)

func is_file_duplicate(directory:String, fileName: String) -> bool: 
	var dir := DirAccess.open(directory)
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

#func check_valid_state(value): 
	#if GameState.gState.has(value):
		#return true
	#else: return false

#func change_state(value): #This is necessary for the 1 tick delay on state change, it is not called directly so variable change can be the streamlined method.
	#var oldState
	#var slaves = []
	#if GameState.gState.activeState != null:
		#oldState = GameState.gState.activeState
		#oldState.queue_free() 
	#slaves = _switch_state_get_slaves(value)
	#GameState.gState.activeState.setup(slaves)
	

#func set_new_state(value): #Value = new State Tag. Call this function, or simply changing the "state" variable from anywhere to change the state properly.
	#state = value



#func _switch_state_get_slaves(value):
	#var slaves = []
	#var stateKeys = GameState.gState.keys()
	#var key = stateKeys[value]
	##print("StateChange: ", key)
	#match value: #when creating a new state, you must add an entry to this match list
		#GameState.gState.LOADING: 
			#slaves = newSlave #array of nodes that listen to the state, used to call their functions
			#GameState.gState.activeState = LoadingState.new() #the actual state script, remember to change this when making a new one.
		#GameState.gState.GB_DEFAULT:
			#slaves = newSlave
			#GameState.activeState = GBDefaultState.new()
		#GameState.gState.GB_SELECTED:
			#slaves = newSlave
			#GameState.activeState = GBSelectedState.new()
		#GameState.gState.GB_ACTION_MENU:
			#slaves = newSlave
			#GameState.activeState = GBActionMenuState.new()
		#GameState.gState.GB_PROFILE:
			#slaves = newSlave
			#GameState.activeState = GBProfileState.new()
		#GameState.gState.GB_ATTACK_TARGETING:
			#slaves = newSlave
			#GameState.activeState = GBAttackState.new()
		#GameState.gState.GB_COMBAT_FORECAST:
			#slaves = newSlave
			#GameState.activeState = GBForeCastState.new()
		#GameState.gState.GB_SKILL_TARGETING:
			#slaves = newSlave
			#GameState.activeState = GBSkillTargetState.new()
		#GameState.gState.GB_SKILL_MENU:
			#slaves = newSlave
			#GameState.activeState = GBSkillMenuState.new()
		#GameState.gState.GB_ROUND_END:
			#slaves = newSlave
			#GameState.activeState = GBRoundEndState.new()
		#GameState.gState.GB_WARP:
			#slaves = newSlave
			#GameState.activeState = GBWarpSelectState.new()
		#GameState.gState.GB_SETUP:
			#slaves = newSlave
			#GameState.activeState = GBSetUpState.new()
		#GameState.gState.GB_FORMATION:
			#slaves = newSlave
			#GameState.activeState = GBFormationState.new()
		#GameState.gState.GB_AI_TURN:
			#slaves = newSlave
			#GameState.activeState = AcceptState.new()
		#GameState.gState.START:
			#slaves = newSlave
			#GameState.activeState = StartState.new()
		#GameState.gState.ACCEPT_PROMPT:
			#slaves = newSlave
			#GameState.activeState = AcceptState.new()
		#GameState.gState.FAIL_STATE:
			#slaves = newSlave
			#GameState.activeState = FailState.new()
		#GameState.gState.WIN_STATE:
			#slaves = newSlave
			#GameState.activeState = AcceptState.new()
		#GameState.gState.SCENE_ACTIVE:
			#slaves = newSlave
			#GameState.activeState = AcceptState.new()
		#GameState.gState.GB_END_OF_ROUND:
			#slaves = newSlave
			#GameState.activeState = LoadingState.new()
	#add_child(GameState.activeState)
	#return slaves

func on_load_map_manager(map):
	var manager = preload("res://scenes/map_manager.tscn").instantiate()
	load_scene(manager)
	$mapManager.load_map(map)
	
#func set_map(map):
	#gameBoard = $mapManager/Gameboard
	#gameBoard.change_map(map)

func unload_me(scene):
	scene.queue_free()
	
