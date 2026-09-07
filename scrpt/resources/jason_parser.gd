extends Resource
class_name JasonParser

var last_error:String = ""
var used_relaxed_parse:bool = false


func _load_file(event_json:String) -> String:
	if event_json == "":
		last_error = "No scene event path was provided."
		push_error("[JasonParser] " + last_error)
		return ""
	if not FileAccess.file_exists(event_json):
		last_error = "Scene event path does not exist: %s" % [event_json]
		push_error("[JasonParser] " + last_error)
		return ""
	var file := FileAccess.open(event_json, FileAccess.READ)
	if file == null:
		last_error = "Could not open scene event file: %s" % [event_json]
		push_error("[JasonParser] " + last_error)
		return ""
	return file.get_as_text()


func parse_json(event_json:String) -> Array[Dictionary]:
	last_error = ""
	used_relaxed_parse = false
	var json := _load_file(event_json)
	if json == "":
		return []
	var parser := JSON.new()
	var error := parser.parse(json)
	if error != OK:
		var relaxed_json := _strip_trailing_commas(json)
		var relaxed_parser := JSON.new()
		var relaxed_error := relaxed_parser.parse(relaxed_json)
		if relaxed_error == OK:
			parser = relaxed_parser
			error = OK
			used_relaxed_parse = true
			push_warning("[JasonParser] Scene event used trailing-comma recovery: %s" % [event_json])
		else:
			last_error = "JSON Parse Error: %s at line %s in %s" % [parser.get_error_message(), parser.get_error_line(), event_json]
			push_error("[JasonParser] " + last_error)
			return []
	if typeof(parser.data) != TYPE_ARRAY:
		last_error = "Scene event root must be an Array: %s" % [event_json]
		push_error("[JasonParser] " + last_error)
		return []
	var data_received:Array[Dictionary] = []
	for index in range(parser.data.size()):
		var entry = parser.data[index]
		if typeof(entry) != TYPE_DICTIONARY:
			last_error = "Scene event line %s must be a Dictionary: %s" % [index, event_json]
			push_error("[JasonParser] " + last_error)
			return []
		data_received.append(entry)
	return data_received


func _strip_trailing_commas(text:String) -> String:
	var result := ""
	var in_string := false
	var escaped := false
	for i in range(text.length()):
		var c := text[i]
		if in_string:
			result += c
			if escaped:
				escaped = false
			elif c == "\\":
				escaped = true
			elif c == "\"":
				in_string = false
			continue
		if c == "\"":
			in_string = true
			result += c
			continue
		if c == ",":
			var j := i + 1
			while j < text.length() and text[j] in [" ", "\t", "\r", "\n"]:
				j += 1
			if j < text.length() and text[j] in ["]", "}"]:
				continue
		result += c
	return result
