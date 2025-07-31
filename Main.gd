extends Node
class_name MainNode

static var root := "user://"
static var screen_shot_folder := "screen_shots"

#enum SAVE_TYPE {TRANSITION, SET_UP, SUSPENDED,}

var gameBoard: GameBoard
var first_map:String = "res://scenes/maps/seize_test.tscn"
var manager_preload:= preload("res://scenes/map_manager.tscn")
var file_selected:bool = false


func _ready():
	var startScene = load("res://scenes/GUI/title/title_screen.tscn").instantiate()
	load_scene(startScene)
	_check_directory()


func _process(_delta):
	pass


func load_scene(scene):
	add_child(scene)


func load_map(map:String):
	gameBoard.load_map(map)


func _init():
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
	if not DirAccess.dir_exists_absolute(root):
		var dir = DirAccess.open(root)
		dir.make_dir(root)
	


func _create_director(newDir : String) -> String:
	var filePath : String = root + "/" + newDir
	var newPath : String
	
	if not DirAccess.dir_exists_absolute(filePath):
		var dir = DirAccess.open(root)
		dir.make_dir(newDir)
		
	newPath = filePath + "/"
	
	return newPath


func take_screenshot():
	var viewport = get_viewport()
	var screenShotDir := _create_director(screen_shot_folder)
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


func on_load_map_manager(map:String):
	var manager = load("res://scenes/map_manager.tscn").instantiate()
	load_scene(manager)
	manager.load_map(map)


func unload_me(scene):
	scene.queue_free()

#region title screen buttons
func new_game_start():
	var rng = RngTool.new()
	rng.new_seed()
	SaveHub.reset_globals()
	#_load_opening_scene()
	_load_first() #Temporary until opening scene is set-up


func begin_file_select():
	var fileSelect = load("res://scenes/chapter_save_screen.tscn").instantiate()
	fileSelect.save_type = Enums.SAVE_TYPE.NONE
	fileSelect.file_selected.connect(self._on_file_selected)
	fileSelect.save_scene_finished.connect(self._on_save_scene_finished)
	load_scene(fileSelect)
#endregion

#region save select screen
func _on_file_selected(save_file:String):
	_start_file_load(save_file)
	file_selected = true

func _on_save_scene_finished(_save_screen:SaveScreen):
	if file_selected:
		#loading screen needed here
		file_selected = false
	else: 
		var startScene = load("res://scenes/GUI/title/title_screen.tscn").instantiate()
		load_scene(startScene)
#endregion


func _start_file_load(save_file:String):
	var data: Dictionary = SaveHub.get_file(save_file)
	SaveHub.load_globals(data)
	_load_file(data)


func _load_first():
	var manager := _load_map_manager()
	manager.load_map(first_map)


#region save data loading
func _load_file(data:Dictionary):
	match int(data.Headstone.SaveType):
		Enums.SAVE_TYPE.TRANSITION: _load_from_transition(data)
		Enums.SAVE_TYPE.SET_UP: _load_from_set_up(data)
		Enums.SAVE_TYPE.SUSPENDED: _load_from_suspended(data)


func _load_from_transition(data:Dictionary):
	var manager := _load_map_manager()
	manager.load_data(data)
	manager.load_map(manager.current_map)


func _load_from_set_up(data:Dictionary):
	var manager := _load_map_manager()
	manager.load_data(data)
	manager.load_map_from_file(manager.current_map, data)


func _load_from_suspended(data:Dictionary):
	pass
#endregion


func _load_opening_scene():
	pass


func _on_opening_complete():
	_load_first()


func _load_map_manager()->MapManager:
	var manager :MapManager= manager_preload.instantiate()
	#unload_me(title_screen)
	load_scene(manager)
	return manager
