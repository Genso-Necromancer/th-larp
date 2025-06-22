extends Node
var save_data : Dictionary = {}
static var root := "user://thLARP"
static var saveFolder := "Saves"
static var dataDir := "user://thLARP/Saves"
signal save_complete(save_file)

func _ready():
	#SignalTower.save_called.connect(self._on_save_called)
	_create_directory(saveFolder)
	set_process(false)


func save_to_file(file_name:String = ""):
	var deTyped:String = file_name.get_slice(".",0)
	match deTyped:
		"Suspended":pass
		"Iron":pass
		_:_write_to_file(deTyped)
	
	
	
func _write_to_file(file_name:String):
	var saveDir := _create_directory(saveFolder)
	var saveFile := FileAccess.open(saveDir+"/"+file_name+".save", FileAccess.WRITE)
	var saveNodes := get_tree().get_nodes_in_group("Persist")
	var headerData := {
		"NodeType":"Header",
		"FileName":file_name,
		"Date": Time.get_datetime_dict_from_system(),
		"PlayTime": Global.play_time,
		"Victory":Global.flags.victory,
		"CurrentChapter": Global.flags.CurrentMap,
		"NextMap": Global.flags.NextMap,
		"ChapterTime": Global.gameTime,
		"TimeOfDay": Global.timeOfDay
	}
	var jsonString = JSON.stringify(headerData)
	saveFile.store_line(jsonString)
	
	var singletonData : Dictionary = Global.save()
	jsonString = JSON.stringify(headerData)
	saveFile.store_line(jsonString)
	singletonData = UnitData.save()
	jsonString = JSON.stringify(headerData)
	saveFile.store_line(jsonString)
	
	for node:Node in saveNodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		# Call the node's save function.
		var nodeData :Dictionary= node.call("save")
		# JSON provides a static method to serialized JSON string.
		jsonString = JSON.stringify(nodeData)
		# Store the save dictionary as a new line in the save file.
		saveFile.store_line(jsonString)
	
	save_complete.emit(file_name)


func _create_directory(newDir : String) -> String:
	var filePath : String = root + "/" + newDir
	var newPath : String
	
	if not DirAccess.dir_exists_absolute(filePath):
		var dir = DirAccess.open(root)
		dir.make_dir(newDir)
		
	newPath = filePath 
	
	return newPath


func load_file(file_name:String):
	var savePath := dataDir+"/"+file_name+".save"
	if not FileAccess.file_exists(savePath):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(savePath, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var nodeData = json.data
		var activeLode
		# Firstly, we need to create the object and add it to the tree and set its position.
		match nodeData["NodeType"]: #Code needs to be made specific to loading method later
			"Utility": 
				activeLode = load(nodeData["filename"]).instantiate()
				get_node(nodeData["parent"]).add_child(activeLode)
			"Unit": 
				activeLode = load(nodeData["filename"]).instantiate()
				get_node(nodeData["parent"]).add_child(activeLode)
				activeLode.position = Vector2(nodeData["pos_x"], nodeData["pos_y"])
			"Global": activeLode = Global
			"UnitData": activeLode = UnitData
			_: continue
		# Now we set the remaining variables.
		for i in nodeData.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y": continue
			activeLode.set(i, nodeData[i])


func get_save_files() -> Array:
	var savesDir := DirAccess.open(dataDir)
	var fileArray := savesDir.get_files()
	var saves := []
	for file in fileArray:
		if file.contains("save_") and file.ends_with(".save"):
			saves.append(file)
	return saves


func get_header(file_name:String):
	var savePath := dataDir+"/"+file_name+".save"
	var header:Dictionary = {
				"NodeType":"Header",
				"FileName":file_name,
				"FileSlot":0,
				"Date": Time.get_datetime_dict_from_system(),
				"PlayTime": 0
			}
	if not FileAccess.file_exists(savePath):
		return 
	var save_file = FileAccess.open(savePath, FileAccess.READ)
	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			return
	header = json.data
	if header.NodeType == "Header":
		return header


func is_valid_file(file_name:String) -> bool:
	var savePath := dataDir+"/"+file_name
	if FileAccess.file_exists(savePath): return true
	return false


func _load_globals(data:Dictionary):
	Global.load_persistant(data)
	UnitData.load_persistant(data)
	
