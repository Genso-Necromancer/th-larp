extends Node
var save_data : Dictionary = {}
const root := "user://"
const save_dir := "user://saves"
var validation := Global.validation.sha256_text()
signal save_complete(file_name:String)
var save_format:= "save_%d.tomb"

func _ready():
	#SignalTower.save_called.connect(self._on_save_called)
	_verify_save_dir(save_dir)


func _verify_save_dir(dir:String)->void:
	DirAccess.make_dir_absolute(dir)


func save_to_file(file_name:String,save_type:Enums.SAVE_TYPE):
	match save_type:
		Enums.SAVE_TYPE.TRANSITION,Enums.SAVE_TYPE.SET_UP:_write_to_file(file_name,save_type)
		Enums.SAVE_TYPE.SUSPENDED:pass
		Enums.SAVE_TYPE.IRON:pass
	
	
	
func _write_to_file(file_name:String,save_type:Enums.SAVE_TYPE)->void:
	
	var saveNodes := get_tree().get_nodes_in_group("Persist")
	var storage: Dictionary = {}
	var global : Dictionary = Global.save()
	var player : Dictionary = PlayerData.save()
	
	var headStone : Dictionary = {
		"DataType":"Headstone",
		"Validation":validation,
		"FileName":file_name,
		"SaveType":save_type,
		"Date": Time.get_datetime_dict_from_system(),
		"game_time":global.game_time,
		"time_of_day":global.time_of_day,
		"victory":global.flags.victory,
		"chapter_title":player.chapter_title,
		"chapter_number":player.chapter_number,}
	storage["Headstone"] = headStone
	storage["Global"] = global
	storage["PlayerData"] = player
	for node:Node in saveNodes:
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		var nodeData :Dictionary= node.call("save")
		storage[nodeData.DataType] = nodeData
	#var file := FileAccess.open_encrypted_with_pass(save_dir+"/"+file_name, FileAccess.WRITE_READ, validation)
	var file := FileAccess.open(save_dir+"/"+file_name, FileAccess.WRITE_READ)
	if file == null:
		print(FileAccess.get_open_error())
		return
	#for key in storage:
		#var jsonString = JSON.stringify(storage[key], "\t")
		#file.store_string(jsonString)
	var jsonString = JSON.stringify(storage, "\t")
	file.store_string(jsonString)
	file.close()
	save_complete.emit(file_name)


func get_file(file_name:String) -> Dictionary:
	var savePath := save_dir+"/"+file_name
	var saveData:Dictionary = {}
	if !FileAccess.file_exists(savePath):
		printerr("[save_hub/get_file] File not found: [%s]" % [savePath])
		return saveData
	#var file = FileAccess.open_encrypted_with_pass(savePath, FileAccess.READ,validation)
	var file = FileAccess.open(savePath, FileAccess.READ)
	if file == null:
		print(FileAccess.get_open_error())
		return saveData
	var stringVer := file.get_as_text()
	file.close()
	saveData = JSON.parse_string(stringVer)
	if saveData == null:
		printerr("[save_hub/get_file] %s unparsed: [%s]" % [savePath, stringVer])
		return saveData
	return saveData


func get_save_files() -> Array:
	var savesDir := DirAccess.open(save_dir)
	var fileArray := savesDir.get_files()
	var saves := []
	for file in fileArray:
		if file.contains("save_") and file.ends_with(".tomb") and is_valid_file(file):
			saves.append(file)
	return saves


##Returns the headStone data exclusively
func get_header(file_name:String):
	#var savePath := save_dir+"/"+file_name
	var headStone:Dictionary = {}
	#var save_file = FileAccess.open_encrypted_with_pass(savePath, FileAccess.READ,validation)
	var saveData = get_file(file_name)
	if saveData.get("Headstone", false):
		headStone = saveData.Headstone
	return headStone


func is_valid_file(file_name:String) -> bool: # Need better validation system
	var savePath := save_dir+"/"+file_name
	if !FileAccess.file_exists(savePath): return false
	#elif FileAccess.open_encrypted_with_pass(savePath, FileAccess.READ, validation): return true
	elif FileAccess.open(savePath, FileAccess.READ): return true
	return false


func get_file_name(file_name:String)->int:
	var number:int
	file_name = file_name.get_basename()
	file_name = file_name.get_slice("_",0)
	number = int(file_name)
	return number

#region globals
func load_globals(data:Dictionary):
	Global.load_persistant(data["Global"])
	PlayerData.load_persistant(data["PlayerData"])


func reset_globals():
	Global.reset_values()
	PlayerData.reset_values()
#endregion


#func _create_directory(newDir : String) -> String:
	#var filePath : String = root + "/" + newDir
	#var newPath : String
	#if not DirAccess.dir_exists_absolute(filePath):
		#var dir = DirAccess.open(root)
		#dir.make_dir(newDir)
	#newPath = filePath
	#return newPath
