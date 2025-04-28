extends Resource
class_name JasonParser




func _load_file(event_json:String) -> String:
	var file := FileAccess.open(event_json, FileAccess.READ)
	assert(FileAccess.file_exists(event_json), "File path does not exist")
	return file.get_as_text()


func parse_json(event_json:String) -> Array[Dictionary]:
	var json := _load_file(event_json)
	var parser := JSON.new()
	var error := parser.parse(json)
	var data_received :Array[Dictionary] =[]
	for dic in parser.data:
		data_received.append(dic)
	
	if error == OK:
		if typeof(data_received) == TYPE_ARRAY: 
			print("Was Array: ",data_received)
		elif typeof(data_received) == TYPE_DICTIONARY:
			print("Was Dictionary: ",data_received)
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", parser.get_error_message(), " in ", json, " at line ", parser.get_error_line())
	return data_received
