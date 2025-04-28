extends Node
class_name MainNode

static var root := "user://"
static var gameFolder := "thLARP"
static var dataDir := root + gameFolder

var gameBoard

func _ready():
	var startScene = preload("res://scenes/start.tscn").instantiate()
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
	elif event.is_action_pressed("ui_snap"):
		take_screenshot()
	elif event.is_action_pressed("xml_debug"):
		StringGetter.mash_test()
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


#Picks up the inputs, then directs them to the currently active state for processing.
func _unhandled_input(event: InputEvent) -> void: 
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


func on_load_map_manager(map):
	var manager = load("res://scenes/map_manager.tscn").instantiate()
	load_scene(manager)
	manager.load_map(map)
	
#func set_map(map):
	#gameBoard = $mapManager/Gameboard
	#gameBoard.change_map(map)

func unload_me(scene):
	scene.queue_free()
	
