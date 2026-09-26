extends Resource
class_name CutsceneCompiler

const DEFAULT_PORTRAIT_PATH := "res://sprites/character/debug/portrait_full.png"
const SCENE_SPRITE_PATH := "res://sprites/character/%s/scene_sprites/%s.png"
const KNOWN_ANIMATIONS := ["slide", "shake", "hop", "double_hop", "interact", "toggle_fade", "question"]
const KNOWN_EFFECTS := ["portrait-sil", "portrait-normal", "dim", "loud", "quiet", "zoom", "teleport", "sound"]
const TARGETED_EFFECTS := ["portrait-sil", "portrait-normal", "dim", "zoom", "teleport"]
const SPEAKER_FOCUS_EFFECT := "speaker"
const COMMANDS := ["bg", "show", "hide", "swap", "anim", "effect", "sfx", "enter", "exit", "slide", "dim", "normal", "focus", "with", "end"]
const EXIT_POSITIONS := {
	"left": -0.25,
	"right": 1.25,
}

var errors:Array[String] = []
var warnings:Array[String] = []
var speakers:Array[Dictionary] = []
var speaker_keys:Array[String] = []
var events:Array[Dictionary] = []
var _section := ""
var _batch := {}
var _in_batch := false
var _current_line_text := ""


func compile_file(path:String) -> Dictionary:
	_reset()
	if path == "":
		_add_error(0, "No cutscene path was provided.")
		return _result()
	if not FileAccess.file_exists(path):
		_add_error(0, "Cutscene path does not exist: %s" % [path])
		return _result()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_add_error(0, "Could not open cutscene file: %s" % [path])
		return _result()
	var text := file.get_as_text()
	file.close()
	_compile_text(text, path)
	return _result()


func compile_text(text:String, source:String = "") -> Dictionary:
	_reset()
	_compile_text(text, source)
	return _result()


func _reset() -> void:
	errors.clear()
	warnings.clear()
	speakers.clear()
	speaker_keys.clear()
	events.clear()
	_section = ""
	_batch = {}
	_in_batch = false


func _compile_text(text:String, source:String) -> void:
	var lines := text.split("\n", false)
	for index in range(lines.size()):
		var line_number := index + 1
		var raw_line := String(lines[index])
		var line := raw_line.strip_edges()
		_current_line_text = line
		if line == "" or line.begins_with("#"):
			continue
		if line.begins_with("@"):
			_read_section(line, line_number)
			continue
		match _section:
			"cast":
				_read_cast_line(line, line_number)
			"scene":
				_read_scene_line(line, line_number)
			_:
				_add_error(line_number, "Line must be inside @cast or @scene.")
	_current_line_text = ""
	if _in_batch:
		_add_error(lines.size(), "Missing 'end' for command attachment block.")
	if not _section_seen(text, "@scene"):
		_add_error(0, "Missing @scene section.")
	if speakers.is_empty():
		_add_warning(0, "Cutscene has no cast entries.")


func _read_section(line:String, line_number:int) -> void:
	match line:
		"@cast":
			_section = "cast"
		"@scene":
			_section = "scene"
		_:
			_add_error(line_number, "Unknown cutscene section '%s'." % [line])


func _read_cast_line(line:String, line_number:int) -> void:
	var split_at := line.find("=")
	if split_at < 0:
		_add_error(line_number, "Bad cast syntax. Expected: key = Display Name | Title | Folder | alias:file")
		return
	var key := line.substr(0, split_at).strip_edges()
	var payload := line.substr(split_at + 1).strip_edges()
	if key == "":
		_add_error(line_number, "Cast entry is missing a key.")
		return
	if speaker_keys.has(key):
		_add_error(line_number, "Duplicate cast key '%s'." % [key])
		return
	var fields := payload.split("|", true)
	var display_name := _field(fields, 0)
	if display_name == "":
		_add_error(line_number, "Cast entry '%s' is missing a display name." % [key])
		return
	var title := _field(fields, 1)
	var folder := _field(fields, 2)
	if folder == "":
		folder = key
	var sprite_aliases := _parse_sprite_aliases(_field(fields, 3), key)
	var portrait_path := _resolve_sprite_path(key, folder, sprite_aliases.get("neutral", "%s_talk" % [key]), line_number)
	speaker_keys.append(key)
	speakers.append({
		"name": key,
		"display_name": display_name,
		"title": title,
		"folder": folder,
		"portrait": portrait_path,
		"sprites": sprite_aliases,
	})


func _parse_sprite_aliases(raw:String, key:String) -> Dictionary:
	var aliases := {}
	if raw == "":
		aliases["neutral"] = "%s_talk" % [key]
		return aliases
	var entries := raw.split(",", false)
	for entry in entries:
		var pair := String(entry).strip_edges()
		if pair == "":
			continue
		var split_at := pair.find(":")
		if split_at < 0:
			aliases[pair] = pair
			continue
		var alias := pair.substr(0, split_at).strip_edges()
		var file := pair.substr(split_at + 1).strip_edges()
		if alias != "" and file != "":
			aliases[alias] = file
	if not aliases.has("neutral"):
		aliases["neutral"] = "%s_talk" % [key]
	return aliases


func _read_scene_line(line:String, line_number:int) -> void:
	if line == "with":
		if _in_batch:
			_add_error(line_number, "Nested 'with' blocks are not supported.")
			return
		_in_batch = true
		_batch = {}
		return
	if line == "end":
		if not _in_batch:
			_add_error(line_number, "'end' without matching 'with'.")
			return
		_flush_batch()
		return
	var event := _parse_scene_statement(line, line_number)
	if event.is_empty():
		return
	if _in_batch:
		if _batch.has("text") and event.has("text"):
			_add_error(line_number, "Only one dialogue line can be attached inside a 'with' block.")
			return
		_merge_event(_batch, event)
	else:
		events.append(event)


func _parse_scene_statement(line:String, line_number:int) -> Dictionary:
	var command := line.get_slice(" ", 0)
	match command:
		"bg":
			return _parse_bg(line, line_number)
		"enter":
			return _parse_enter(line, line_number)
		"exit":
			return _parse_exit(line, line_number)
		"slide":
			return _parse_slide(line, line_number)
		"show":
			return _parse_show(line, line_number)
		"hide":
			return _parse_hide(line, line_number)
		"swap":
			return _parse_swap(line, line_number)
		"anim":
			return _parse_anim(line, line_number)
		"dim":
			return _parse_effect_alias(line, line_number, "dim")
		"normal":
			return _parse_effect_alias(line, line_number, "portrait-normal")
		"focus":
			return _parse_focus_alias(line, line_number)
		"effect":
			return _parse_effect(line, line_number)
		"sfx":
			return _parse_sfx(line, line_number)
	var colon_at := line.find(":")
	if colon_at >= 0:
		return _parse_dialogue(line, colon_at, line_number)
	_add_error(line_number, _with_suggestion("Unknown command '%s'." % [command], command, COMMANDS))
	return {}


func _parse_dialogue(line:String, colon_at:int, line_number:int) -> Dictionary:
	var speaker := line.substr(0, colon_at).strip_edges()
	var text := line.substr(colon_at + 1).strip_edges()
	if speaker == "":
		_add_error(line_number, "Dialogue line is missing a speaker key.")
		return {}
	if speaker != "none" and not speaker_keys.has(speaker):
		_add_error(line_number, _with_suggestion("Unknown dialogue speaker '%s'." % [speaker], speaker, speaker_keys))
		return {}
	return {"active_speaker": speaker, "text": text}


func _parse_bg(line:String, line_number:int) -> Dictionary:
	var value := line.substr(2).strip_edges()
	if value == "":
		_add_error(line_number, "'bg' requires a value.")
		return {}
	return {"background": value}


func _parse_show(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 4 or parts[2] != "at":
		_add_error(line_number, "'show' expects: show speaker at position")
		return {}
	var speaker := parts[1]
	if not _validate_speaker(speaker, line_number, "show"):
		return {}
	if not String(parts[3]).is_valid_float():
		_add_error(line_number, "'show' position must be a number.")
		return {}
	return {
		"portrait_visibility": [{"target": speaker, "visible": true}],
		"animations": [{"name": "slide", "target": speaker, "pos": float(parts[3])}],
	}


func _parse_enter(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() < 3 or parts.size() > 4:
		_add_error(line_number, "'enter' expects: enter speaker position or enter speaker left/right position")
		return {}
	var speaker := ""
	var side := "left"
	var destination := ""
	if parts.size() == 3:
		speaker = parts[1]
		destination = parts[2]
	elif EXIT_POSITIONS.has(String(parts[1])):
		side = parts[1]
		speaker = parts[2]
		destination = parts[3]
	else:
		speaker = parts[1]
		side = parts[2]
		destination = parts[3]
	if not _validate_speaker(speaker, line_number, "enter"):
		return {}
	if not EXIT_POSITIONS.has(side):
		_add_error(line_number, _with_suggestion("'enter' side must be left or right.", side, EXIT_POSITIONS.keys()))
		return {}
	if not String(destination).is_valid_float():
		_add_error(line_number, "'enter' position must be a number.")
		return {}
	return {
		"portrait_visibility": [{"target": speaker, "visible": true}],
		"effects": [{"name": "teleport", "target": speaker, "pos": EXIT_POSITIONS[side]}],
		"animations": [{"name": "slide", "target": speaker, "pos": float(destination)}],
	}


func _parse_exit(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 3:
		_add_error(line_number, "'exit' expects: exit speaker left/right")
		return {}
	var speaker := parts[1]
	var side := parts[2]
	if not _validate_speaker(speaker, line_number, "exit"):
		return {}
	if not EXIT_POSITIONS.has(side):
		_add_error(line_number, _with_suggestion("'exit' side must be left or right.", side, EXIT_POSITIONS.keys()))
		return {}
	return {"animations": [{"name": "slide", "target": speaker, "pos": EXIT_POSITIONS[side]}]}


func _parse_slide(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 3:
		_add_error(line_number, "'slide' expects: slide speaker position")
		return {}
	var speaker := parts[1]
	if not _validate_speaker(speaker, line_number, "slide"):
		return {}
	if not String(parts[2]).is_valid_float():
		_add_error(line_number, "'slide' position must be a number.")
		return {}
	return {"animations": [{"name": "slide", "target": speaker, "pos": float(parts[2])}]}


func _parse_hide(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 2:
		_add_error(line_number, "'hide' expects: hide speaker")
		return {}
	var speaker := parts[1]
	if not _validate_speaker(speaker, line_number, "hide"):
		return {}
	return {"portrait_visibility": [{"target": speaker, "visible": false}]}


func _parse_swap(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 3:
		_add_error(line_number, "'swap' expects: swap speaker sprite_alias")
		return {}
	var speaker := parts[1]
	var sprite_alias := parts[2]
	if not _validate_speaker(speaker, line_number, "swap"):
		return {}
	var sprite_path := _resolve_sprite_alias(speaker, sprite_alias, line_number)
	return {"portrait_swaps": [{"target": speaker, "sprite": sprite_alias, "path": sprite_path}]}


func _parse_anim(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() < 3:
		_add_error(line_number, "'anim' expects: anim speaker animation_name")
		return {}
	var speaker := parts[1]
	var anim_name := parts[2]
	if not _validate_speaker(speaker, line_number, "anim"):
		return {}
	if not KNOWN_ANIMATIONS.has(anim_name):
		_add_error(line_number, _with_suggestion("Unknown animation '%s'." % [anim_name], anim_name, KNOWN_ANIMATIONS))
		return {}
	var anim := {"name": anim_name, "target": speaker}
	if anim_name == "slide":
		if parts.size() < 4 or not String(parts[3]).is_valid_float():
			_add_error(line_number, "'slide' animation requires a numeric position.")
			return {}
		anim["pos"] = float(parts[3])
	return {"animations": [anim]}


func _parse_effect(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() < 2:
		_add_error(line_number, "'effect' expects an effect name or speaker plus effect name.")
		return {}
	var effect_name := parts[1]
	var effect := {}
	if KNOWN_EFFECTS.has(effect_name):
		effect["name"] = effect_name
	elif parts.size() >= 3:
		var speaker := parts[1]
		effect_name = parts[2]
		if speaker == "all":
			return _parse_all_effect(parts, effect_name, line_number)
		if effect_name == SPEAKER_FOCUS_EFFECT:
			return _parse_speaker_focus_effect(speaker, line_number)
		if not _validate_speaker(speaker, line_number, "effect"):
			return {}
		if not KNOWN_EFFECTS.has(effect_name):
			_add_error(line_number, _with_suggestion("Unknown effect '%s'." % [effect_name], effect_name, _known_authoring_effects()))
			return {}
		effect["name"] = effect_name
		effect["target"] = speaker
	else:
		_add_error(line_number, _with_suggestion("Unknown effect '%s'." % [effect_name], effect_name, _known_authoring_effects()))
		return {}
	if TARGETED_EFFECTS.has(effect_name) and not effect.has("target"):
		_add_error(line_number, "Effect '%s' requires a speaker target." % [effect_name])
		return {}
	if effect_name == "teleport":
		var pos_index := 3
		if parts.size() <= pos_index or not String(parts[pos_index]).is_valid_float():
			_add_error(line_number, "'teleport' effect requires a numeric position.")
			return {}
		effect["pos"] = float(parts[pos_index])
	return {"effects": [effect]}


func _parse_effect_alias(line:String, line_number:int, effect_name:String) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 2:
		_add_error(line_number, "'%s' expects: %s speaker" % [parts[0], parts[0]])
		return {}
	var speaker := parts[1]
	if speaker == "all":
		return _parse_all_effect(PackedStringArray(["effect", "all", effect_name]), effect_name, line_number)
	if not _validate_speaker(speaker, line_number, parts[0]):
		return {}
	return {"effects": [{"name": effect_name, "target": speaker}]}


func _parse_focus_alias(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 2:
		_add_error(line_number, "'focus' expects: focus speaker")
		return {}
	return _parse_speaker_focus_effect(parts[1], line_number)


func _parse_all_effect(parts:PackedStringArray, effect_name:String, line_number:int) -> Dictionary:
	if effect_name == SPEAKER_FOCUS_EFFECT:
		_add_error(line_number, "'speaker' focus effect requires one speaker target, not 'all'.")
		return {}
	if not KNOWN_EFFECTS.has(effect_name):
		_add_error(line_number, _with_suggestion("Unknown effect '%s'." % [effect_name], effect_name, _known_authoring_effects()))
		return {}
	if not TARGETED_EFFECTS.has(effect_name):
		_add_error(line_number, "Effect '%s' cannot use 'all' because it does not target portraits." % [effect_name])
		return {}
	var effects:Array[Dictionary] = []
	for speaker in speaker_keys:
		var effect := {"name": effect_name, "target": speaker}
		if effect_name == "teleport":
			var pos_index := 3
			if parts.size() <= pos_index or not String(parts[pos_index]).is_valid_float():
				_add_error(line_number, "'teleport' effect requires a numeric position.")
				return {}
			effect["pos"] = float(parts[pos_index])
		effects.append(effect)
	return {"effects": effects}


func _parse_speaker_focus_effect(speaker:String, line_number:int) -> Dictionary:
	if not _validate_speaker(speaker, line_number, "speaker focus effect"):
		return {}
	var effects:Array[Dictionary] = []
	for speaker_key in speaker_keys:
		if speaker_key == speaker:
			continue
		effects.append({"name": "dim", "target": speaker_key})
	effects.append({"name": "portrait-normal", "target": speaker})
	return {"effects": effects}


func _parse_sfx(line:String, line_number:int) -> Dictionary:
	var parts := line.split(" ", false)
	if parts.size() != 2:
		_add_error(line_number, "'sfx' expects: sfx sound_name")
		return {}
	return {"effects": [{"name": "sound", "sound": parts[1]}]}


func _validate_speaker(speaker:String, line_number:int, context:String) -> bool:
	if speaker_keys.has(speaker):
		return true
	_add_error(line_number, _with_suggestion("Unknown speaker '%s' for %s." % [speaker, context], speaker, speaker_keys))
	return false


func _resolve_sprite_alias(speaker:String, sprite_alias:String, line_number:int) -> String:
	for speaker_data in speakers:
		if speaker_data.get("name", "") != speaker:
			continue
		var aliases:Dictionary = speaker_data.get("sprites", {})
		if not aliases.has(sprite_alias):
			_add_warning(line_number, "Speaker '%s' has no sprite alias '%s'; using default portrait." % [speaker, sprite_alias])
			return DEFAULT_PORTRAIT_PATH
		return _resolve_sprite_path(speaker, speaker_data.get("folder", speaker), aliases[sprite_alias], line_number)
	_add_warning(line_number, "Speaker '%s' was not found while resolving sprite '%s'; using default portrait." % [speaker, sprite_alias])
	return DEFAULT_PORTRAIT_PATH


func _resolve_sprite_path(speaker:String, folder:String, file_name:String, line_number:int) -> String:
	var path := SCENE_SPRITE_PATH % [folder, file_name]
	if ResourceLoader.exists(path):
		return path
	_add_warning(line_number, "Sprite for '%s' not found at '%s'; using default portrait." % [speaker, path])
	return DEFAULT_PORTRAIT_PATH


func _flush_batch() -> void:
	if not _batch.is_empty():
		events.append(_batch)
	_batch = {}
	_in_batch = false


func _merge_event(target:Dictionary, event:Dictionary) -> void:
	for key in event.keys():
		if event[key] is Array:
			if not target.has(key):
				target[key] = []
			for item in event[key]:
				target[key].append(item)
		else:
			target[key] = event[key]


func _field(fields:PackedStringArray, index:int) -> String:
	if index >= fields.size():
		return ""
	return String(fields[index]).strip_edges()


func _section_seen(text:String, section_name:String) -> bool:
	for raw_line in text.split("\n", false):
		if String(raw_line).strip_edges() == section_name:
			return true
	return false


func _add_error(line_number:int, message:String) -> void:
	errors.append(_format_message(line_number, message))


func _add_warning(line_number:int, message:String) -> void:
	warnings.append(_format_message(line_number, message))


func _format_message(line_number:int, message:String) -> String:
	if line_number <= 0:
		return message
	var formatted := "line %s: %s" % [line_number, message]
	if _current_line_text != "":
		formatted += " Source: %s" % [_current_line_text]
	return formatted


func _known_authoring_effects() -> Array:
	var names:Array = KNOWN_EFFECTS.duplicate()
	names.append(SPEAKER_FOCUS_EFFECT)
	return names


func _with_suggestion(message:String, bad_value:String, options:Array) -> String:
	var suggestion := _closest_match(bad_value, options)
	if suggestion == "":
		return message
	return "%s Did you mean '%s'?" % [message, suggestion]


func _closest_match(bad_value:String, options:Array) -> String:
	var best := ""
	var best_distance := 999
	for option in options:
		var candidate := String(option)
		var distance := _string_distance(bad_value, candidate)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	if best_distance <= 3:
		return best
	return ""


func _string_distance(left:String, right:String) -> int:
	var previous := []
	for index in range(right.length() + 1):
		previous.append(index)
	for left_index in range(left.length()):
		var current := [left_index + 1]
		for right_index in range(right.length()):
			var insert_cost:int = current[right_index] + 1
			var delete_cost:int = previous[right_index + 1] + 1
			var replace_cost:int = previous[right_index]
			if left[left_index] != right[right_index]:
				replace_cost += 1
			current.append(min(insert_cost, min(delete_cost, replace_cost)))
		previous = current
	return previous[right.length()]


func _result() -> Dictionary:
	return {
		"speakers": speakers,
		"event": events,
		"errors": errors,
		"warnings": warnings,
	}
