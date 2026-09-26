extends Control
##Dialogue Arrays are stored in /scenes/cutscenes as *_event.json files. Specifc file paths are stored on the relevant game map.[br]
##Paths are sent via prepare_new_dialogue() where they're parsed using a JasonParser returning the Array[Dictionary] and sets the event in motion.
class_name DialogueOverlay

signal dialog_finished
signal bobber_check(flag: String)
signal _dialogue_fade_finished

@onready var background_texture_rect = $BackgroundTextureRect
@onready var audio_player = $AudioStreamPlayer_speech
@onready var texturerect = $PortraitsNode/SpeakerPortrait
@onready var text_body = $GradientRect/ForegroundElements/MarginContainer/VBoxContainer/TextBody
@onready var name_label = $GradientRect/ForegroundElements/MarginContainer/VBoxContainer/HBoxContainer/NameLabel
@onready var title_label = $GradientRect/ForegroundElements/MarginContainer/VBoxContainer/HBoxContainer/TitleLabel
@onready var foreground_elements = $GradientRect/ForegroundElements
@onready var debug_line_track : HSlider = $DebugLineTrack
@onready var default_font_size = text_body.label_settings.font_size

const EVENTS_DIR = "res://scenes/cutscenes/scene_events"
const KNOWN_ANIMATIONS := ["slide", "shake", "hop", "double_hop", "interact", "toggle_fade", "question"]
const KNOWN_EFFECTS := ["portrait-sil", "portrait-normal", "dim", "loud", "quiet", "zoom", "teleport", "sound"]
const TARGETED_ANIMATIONS := ["slide", "shake", "hop", "double_hop", "interact", "toggle_fade", "question"]
const TARGETED_EFFECTS := ["portrait-sil", "portrait-normal", "dim", "zoom", "teleport"]
const POSITIONED_ANIMATIONS := ["slide"]
const POSITIONED_EFFECTS := ["teleport"]
const DEFAULT_PORTRAIT_PATH := "res://sprites/character/debug/portrait_full.png"

var letter_time : float = 0.02
var space_time : float = letter_time * 2.0
var punctuation_time : float = letter_time * 6.5
var _ready_flags := {
	"text_complete": false,
	"animations_complete": false,
	"effects_complete": false
}
var portrait : = preload("res://scenes/cutscenes/speaker_portrait.tscn")
var dialogue_finished := false
var speaker_portraits := {}  # Dictionary<String, PortraitRect>
var textline_index := -1
var current_event : Array[Dictionary] = []
var last_scene_errors:Array[String] = []
var default_speaker_setup = [
	{
		"name": "Sirno",
		"display_name": "Sirno",
		"title": "honto no baka",
		"portrait": "res://sprites/Fairy TroublemakerPrt.png",
	},
	{
		"name": "Sakula",
		"display_name": "Sakula",
		"title": "medio",
		"portrait": "res://sprites/SakuyaPrt.png",
	},
	{
		"name": "Pakooli",
		"display_name": "Pakooli",
		"title": "magical girl",
		"portrait": "res://sprites/character/patchouli/scene_sprites/th2.png"
	},
	{
		"name": "Remi",
		"display_name": "Remi",
		"title": "fiary stomper",
		"portrait": "res://sprites/character/remilia/scene_sprites/th1.png"
	}
]
var example_dict : Array[Dictionary] = [
	{
		"active_speaker": "Remi",
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.75}],
		"effects":[{"name": "teleport", "target": "Remi", "pos": 0.25}, {"name": "teleport", "target": "Pakooli", "pos": -0.5}]
	},
	{
		"animations": [{"name": "interact", "target": "Remi"}]
	},
	{
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.25}]
	},
	{
		"animations": [{"name": "interact", "target": "Remi"}]
	},
	{
		"text": "Hmm... I know I left my wing caps around here somewhere...",
		"animations": [{"name": "slide", "target": "Pakooli", "pos": -0.2}]
	},
	{
		"active_speaker": "Pakooli",
		"text": "Hey-",
		"background": "res://sprites/danmaku/danmaku.png"
	},
	{
		"active_speaker": "Remi",
		"text": "GGIAYAAAAAAGHGH !!",
		"effects": [{"name": "loud"}],
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.8}, {"name": "double_hop", "target": "Remi"}, {"name": "slide", "target": "Pakooli", "pos": 0.25}]
	},
	{
		"active_speaker": "Pakooli",
		"text": "uh, like sorry for scaring you or whatever.",
	},
	{
		"text": "were you talking to yourself ..?",
		"effects": [{"name": "quiet"}, {"name": "sound", "sound": "surprise"}],
		"animations": [{"name": "question", "target": "Pakooli"}],
		"background": "null"
	},
	{
		"active_speaker": "Remi",
		"text": "Get out of my room I'm playing Minecraft!!",
		"animations": [{"name": "hop", "target": "Remi"}]
	},
]
var speaker_setup = default_speaker_setup.duplicate(true)


func _ready():
	self.visible = false
	foreground_elements.visible = false
	_set_debug_loader_visible(false)
	set_physics_process(false)
	_reset()
	# TODO Kill all children in PortaitsNode?
	bobber_check.connect(_check_bobber)
	
	debug_line_track.connect("drag_ended", Callable(self, "_on_debug_slider_drag_ended"))
	_populate_load_dropdown()


#func _gui_input(event):
	#if GameState.activeState == null:
			#return
	#if event is InputEventMouseMotion:
		#GameState.activeState.mouse_motion(event)
	#elif event is InputEventMouseButton:
		#GameState.activeState.mouse_pressed(event)
	#elif event is InputEventKey:
		#GameState.activeState.event_key(event)


func _unhandled_input(event) -> void:
	if event.is_action_released("debug_dialogue") and Global.flags.DebugMode and !is_physics_processing():
		_open_debug_loader()
	elif GameState.state != GameState.gState.DIALOGUE_SCENE: return
	elif event.is_action_released("ui_return"): toggle_dialog()
	elif not visible and is_physics_processing(): return
	elif event is InputEventMouseMotion:
		GameState.activeState.mouse_motion(event)
	elif event is InputEventMouseButton:
		GameState.activeState.mouse_pressed(event)
	elif event is InputEventKey:
		GameState.activeState.event_key(event)
	#elif event.is_action_released("ui_accept"): gui_accept() # For testing purposes, comment out for live game
		

##input from control state DIALOGUE_SCENE
func gui_accept():
	if GameState.state != GameState.gState.DIALOGUE_SCENE: return
	elif !current_event[textline_index].has("text"): return
	
	if dialogue_finished && Global.flags.DebugMode:
		_open_debug_loader()
	
	elif !$TextStopper/AnimationPlayer.is_playing():
		skip_text = true
	elif textline_index < current_event.size() - 1:
		next_textline()
	else:
		_conclude_dialog()


func _reset() -> void:
	text_body.text = ""
	name_label.text = ""
	title_label.text = ""
	background_texture_rect.texture = null
	textline_index = -1


func _conclude_dialog() -> void:
	_reset()
	_clear_speaker_portraits()
	dialogue_finished = true
	toggle_dialog()
	await _dialogue_fade_finished
	dialog_finished.emit()


func _set_debug_loader_visible(enabled:bool) -> void:
	debug_line_track.visible = enabled
	$HBoxContainer.visible = enabled
	$ScrollContainer.visible = enabled


func _open_debug_loader() -> void:
	_populate_load_dropdown()
	self.visible = true
	modulate = Color(1,1,1,1)
	foreground_elements.visible = false
	_set_debug_loader_visible(true)


func _clear_speaker_portraits() -> void:
	speaker_portraits = {}
	for child in $PortraitsNode.get_children():
		$PortraitsNode.remove_child(child)
		child.queue_free()


func _build_speaker_portraits() -> void:
	_clear_speaker_portraits()
	for speaker in speaker_setup:
		var new_portrait:PortraitRect= portrait.instantiate()
		var speaker_key := String(speaker.get("name", ""))
		new_portrait.name = speaker_key
		new_portrait.speaker_name = String(speaker.get("display_name", speaker_key))
		new_portrait.speaker_title = String(speaker.get("title", ""))
		var portrait_path := String(speaker.get("portrait", DEFAULT_PORTRAIT_PATH))
		if not ResourceLoader.exists(portrait_path):
			push_warning("[DialogueOverlay] Portrait path '%s' for speaker '%s' is missing; using default portrait." % [portrait_path, speaker_key])
			portrait_path = DEFAULT_PORTRAIT_PATH
		new_portrait.texture = load(portrait_path)
		new_portrait.visible = false
		new_portrait.anim_finished.connect(_on_anim_finished)
		$PortraitsNode.add_child(new_portrait)
		speaker_portraits[speaker_key] = new_portrait


func _begin_dialogue_playback(event_lines:Array[Dictionary], keep_debug_loader:bool = false, fade_in:bool = true) -> void:
	GameState.change_state(self,GameState.gState.DIALOGUE_SCENE)
	current_event = event_lines
	dialogue_finished = false
	_reset()
	_build_speaker_portraits()
	_set_debug_loader_visible(keep_debug_loader and Global.flags.DebugMode)
	debug_line_track.min_value = 0
	debug_line_track.max_value = current_event.size()-1
	debug_line_track.value = 0
	textline_index = -1
	if fade_in and not visible:
		toggle_dialog()
	else:
		self.visible = true
		modulate = Color(1,1,1,1)
		set_physics_process(true)
	next_textline()
	_rebuild_editor_list()


func _abort_dialogue_start(reason:String) -> void:
	push_error("[DialogueOverlay] " + reason)
	dialogue_finished = true
	dialog_finished.emit()


func _get_known_speaker_names() -> Array[String]:
	var names:Array[String] = []
	for speaker in speaker_setup:
		names.append(String(speaker.get("name", "")))
	return names


func _validate_scene_event(event:Array[Dictionary], source:String = "") -> bool:
	last_scene_errors.clear()
	var speaker_names := _get_known_speaker_names()
	if event.is_empty():
		last_scene_errors.append("Scene has no lines.")
	for line_index in range(event.size()):
		var line := event[line_index]
		_validate_scene_line(line, line_index, speaker_names)
	for error in last_scene_errors:
		push_error("[DialogueOverlay] Scene validation error%s: %s" % [_source_suffix(source), error])
	return last_scene_errors.is_empty()


func _validate_scene_line(line:Dictionary, line_index:int, speaker_names:Array[String]) -> void:
	var line_number := line_index + 1
	var active_speaker := String(line.get("active_speaker", ""))
	if active_speaker != "" and active_speaker != "none" and not speaker_names.has(active_speaker):
		last_scene_errors.append("line %s uses unknown active_speaker '%s'." % [line_number, active_speaker])
	var background := String(line.get("background", ""))
	if background != "" and background != "null" and background != "none" and not ResourceLoader.exists(background):
		last_scene_errors.append("line %s uses missing background '%s'." % [line_number, background])
	_validate_scene_actions(line.get("animations", []), line_index, "animation", KNOWN_ANIMATIONS, TARGETED_ANIMATIONS, POSITIONED_ANIMATIONS, speaker_names)
	_validate_scene_actions(line.get("effects", []), line_index, "effect", KNOWN_EFFECTS, TARGETED_EFFECTS, POSITIONED_EFFECTS, speaker_names)
	_validate_portrait_visibility(line.get("portrait_visibility", []), line_index, speaker_names)
	_validate_portrait_swaps(line.get("portrait_swaps", []), line_index, speaker_names)


func _validate_scene_actions(actions, line_index:int, action_label:String, known_names:Array, targeted_names:Array, positioned_names:Array, speaker_names:Array[String]) -> void:
	var line_number := line_index + 1
	if actions == null:
		return
	if typeof(actions) != TYPE_ARRAY:
		last_scene_errors.append("line %s '%ss' field must be an Array." % [line_number, action_label])
		return
	for action_index in range(actions.size()):
		var action_number := action_index + 1
		var action = actions[action_index]
		if typeof(action) != TYPE_DICTIONARY:
			last_scene_errors.append("line %s %s %s must be a Dictionary." % [line_number, action_label, action_number])
			continue
		var action_name := String(action.get("name", ""))
		if action_name == "":
			last_scene_errors.append("line %s %s %s is missing a name." % [line_number, action_label, action_number])
			continue
		if not known_names.has(action_name):
			last_scene_errors.append("line %s %s %s has unknown name '%s'." % [line_number, action_label, action_number, action_name])
			continue
		if targeted_names.has(action_name):
			var target := String(action.get("target", ""))
			if target == "" or not speaker_names.has(target):
				last_scene_errors.append("line %s %s '%s' uses unknown target '%s'." % [line_number, action_label, action_name, target])
		if positioned_names.has(action_name) and not action.has("pos"):
			last_scene_errors.append("line %s %s '%s' is missing 'pos'." % [line_number, action_label, action_name])
		if action_name == "sound" and not action.has("sound"):
			last_scene_errors.append("line %s effect 'sound' is missing 'sound'." % [line_number])


func _validate_portrait_swaps(swaps, line_index:int, speaker_names:Array[String]) -> void:
	var line_number := line_index + 1
	if swaps == null:
		return
	if typeof(swaps) != TYPE_ARRAY:
		last_scene_errors.append("line %s 'portrait_swaps' field must be an Array." % [line_number])
		return
	for swap_index in range(swaps.size()):
		var swap = swaps[swap_index]
		if typeof(swap) != TYPE_DICTIONARY:
			last_scene_errors.append("line %s portrait swap %s must be a Dictionary." % [line_number, swap_index + 1])
			continue
		var target := String(swap.get("target", ""))
		if target == "" or not speaker_names.has(target):
			last_scene_errors.append("line %s portrait swap uses unknown target '%s'." % [line_number, target])
		var path := String(swap.get("path", ""))
		if path == "":
			last_scene_errors.append("line %s portrait swap for '%s' is missing 'path'." % [line_number, target])
		elif not ResourceLoader.exists(path):
			last_scene_errors.append("line %s portrait swap path is missing: %s" % [line_number, path])


func _validate_portrait_visibility(entries, line_index:int, speaker_names:Array[String]) -> void:
	var line_number := line_index + 1
	if entries == null:
		return
	if typeof(entries) != TYPE_ARRAY:
		last_scene_errors.append("line %s 'portrait_visibility' field must be an Array." % [line_number])
		return
	for entry_index in range(entries.size()):
		var entry = entries[entry_index]
		if typeof(entry) != TYPE_DICTIONARY:
			last_scene_errors.append("line %s portrait visibility %s must be a Dictionary." % [line_number, entry_index + 1])
			continue
		var target := String(entry.get("target", ""))
		if target == "" or not speaker_names.has(target):
			last_scene_errors.append("line %s portrait visibility uses unknown target '%s'." % [line_number, target])
		if not entry.has("visible") or typeof(entry.visible) != TYPE_BOOL:
			last_scene_errors.append("line %s portrait visibility for '%s' must include a bool 'visible'." % [line_number, target])


func _source_suffix(source:String) -> String:
	if source == "":
		return ""
	return " in %s" % [source]


func _get_speaker_portrait(speaker_name:String, context:String = "") -> PortraitRect:
	if speaker_portraits.has(speaker_name):
		return speaker_portraits[speaker_name]
	push_warning("[DialogueOverlay] Unknown speaker '%s'%s." % [speaker_name, _source_suffix(context)])
	return null


func _load_scene_data(path:String) -> Dictionary:
	if path.ends_with(".cutscene"):
		var compiler := CutsceneCompiler.new()
		var compiled := compiler.compile_file(path)
		return {
			"event": compiled.get("event", []),
			"speakers": compiled.get("speakers", []),
			"errors": compiled.get("errors", []),
			"warnings": compiled.get("warnings", []),
		}
	var parser = JasonParser.new()
	var parsed_event : Array[Dictionary] = parser.parse_json(path)
	var errors:Array[String] = []
	if not parser.last_error.is_empty():
		errors.append(parser.last_error)
	return {
		"event": parsed_event,
		"speakers": [],
		"errors": errors,
		"warnings": [],
	}


func _report_scene_load_messages(data:Dictionary, source:String) -> void:
	for warning in data.get("warnings", []):
		push_warning("[DialogueOverlay] %s%s." % [warning, _source_suffix(source)])
	for error in data.get("errors", []):
		push_error("[DialogueOverlay] %s%s." % [error, _source_suffix(source)])


func _apply_speaker_setup(new_speakers:Array) -> void:
	if new_speakers.is_empty():
		speaker_setup = default_speaker_setup.duplicate(true)
	else:
		speaker_setup = new_speakers.duplicate(true)


#Now called when a new map is loaded, right after the splash screen. See MapManager:_on_gui_splash_finished(). Will be called in more varied ways
##SceneScripts are stored on the map associated with them. There is to be a Start and End scene to each Chapter that daisy chains things together with a moment for saving/loading in-between last End and new Start
func prepare_new_dialogue(new_event:String= ""):
	dialogue_finished = false
	if new_event: 
		var scene_data := _load_scene_data(new_event)
		_report_scene_load_messages(scene_data, new_event)
		if not scene_data.get("errors", []).is_empty():
			_abort_dialogue_start("Scene load failed%s." % [_source_suffix(new_event)])
			return
		_apply_speaker_setup(scene_data.get("speakers", []))
		var eventDick : Array[Dictionary] = []
		for event_line in scene_data.get("event", []):
			eventDick.append(event_line)
		if not _validate_scene_event(eventDick, new_event):
			_abort_dialogue_start("Scene validation failed%s." % [_source_suffix(new_event)])
			return
		current_event = eventDick
	else:
		_apply_speaker_setup([])
		current_event = example_dict #subverts variable typing to give a dictionary as default, normally only want to pass ScenScript Resource
		if not _validate_scene_event(current_event, "example_dict"):
			_abort_dialogue_start("Example scene validation failed.")
			return
	_begin_dialogue_playback(current_event, false, true)


func next_textline(scrub : bool = false):
	textline_index += 1
	if textline_index < 0 or textline_index >= current_event.size():
		_conclude_dialog()
		return
	if !scrub:
		debug_line_track.value = textline_index
	anims_finished = 0
	expected_anims = 0
	skip_text = scrub
	var speed = 1.0
	if scrub: speed = 0.1
	
	_ready_flags = {
		"text_complete": false,
		"animations_complete": false,
		"effects_complete": false
	}
	
	$TextStopper.visible = false
	$TextStopper/AnimationPlayer.stop()
	
	var cur_line = current_event[textline_index]
	
	var has_text = true if cur_line.get("text","") != "" else false
	if has_text && !scrub:
		foreground_elements.visible = true
		_type_text(cur_line.text)
	else:
		foreground_elements.visible = false
		bobber_check.emit("text_complete")
	
	var has_bg = true if cur_line.get("background","") != "" else false
	if has_bg:
		if cur_line.background == "null" or cur_line.background == "none" or cur_line.background == "":
			background_texture_rect.texture = null
		else:
			background_texture_rect.texture = load(cur_line.background)
	
	var has_active_speaker = true if cur_line.get("active_speaker","") != "" else false
	if has_active_speaker:
		if cur_line.active_speaker != "none":
			var active_speaker := _get_speaker_portrait(cur_line.active_speaker, "line %s" % [textline_index + 1])
			if active_speaker == null:
				bobber_check.emit("animations_complete")
				bobber_check.emit("effects_complete")
				return
			name_label.text = active_speaker.speaker_name
			title_label.text = active_speaker.speaker_title
			active_speaker.visible = true
		else:
			name_label.text = ""
			title_label.text = ""

	var has_portrait_visibility = true if !cur_line.get("portrait_visibility",[]).is_empty() else false
	if has_portrait_visibility:
		for entry in cur_line.portrait_visibility:
			var visible_target := _get_speaker_portrait(String(entry.get("target", "")), "line %s portrait visibility" % [textline_index + 1])
			if visible_target == null:
				continue
			visible_target.visible = bool(entry.get("visible", false))
			if visible_target.visible:
				visible_target.modulate = Color(1,1,1,1)

	var has_portrait_swaps = true if !cur_line.get("portrait_swaps",[]).is_empty() else false
	if has_portrait_swaps:
		for swap in cur_line.portrait_swaps:
			var swap_target := _get_speaker_portrait(String(swap.get("target", "")), "line %s portrait swap" % [textline_index + 1])
			if swap_target == null:
				continue
			var swap_path := String(swap.get("path", DEFAULT_PORTRAIT_PATH))
			if not ResourceLoader.exists(swap_path):
				push_warning("[DialogueOverlay] Portrait swap path '%s' is missing; using default portrait." % [swap_path])
				swap_path = DEFAULT_PORTRAIT_PATH
			swap_target.texture = load(swap_path)
	
	#if cur_line.has("speaker"):
		#if cur_line["speaker"] is int:
			#var predefined_speaker = CutsceneManager.ActorData[cur_line["speaker"]]
			#name_label.text = predefined_speaker["name"]
			#title_label.text = predefined_speaker["title"]
			#texturerect.texture = predefined_speaker["portrait"]
		#elif cur_line["speaker"] == "none":
			#name_label.text = ""
			#title_label.text = ""
		#else:
			#name_label.text = cur_line["speaker"]
	#
	#if current_event[textline_index].has("title"):
		#title_label.text = cur_line["title"]
	#
	#if current_event[textline_index].has("portrait"):
		#texturerect.texture = load(cur_line["portrait"])
	
	var has_effects = true if !cur_line.get("effects",[]).is_empty() else false
	if has_effects: # TODO Add a default-to-Active_Speaker fallback if no Target is specified?
		bobber_check.emit("effects_complete")
		for eff in cur_line.effects:
			var effect_name := String(eff.get("name", ""))
			if not KNOWN_EFFECTS.has(effect_name):
				push_warning("[DialogueOverlay] Unknown effect '%s' on line %s." % [effect_name, textline_index + 1])
				continue
			var effect_target:PortraitRect = null
			if TARGETED_EFFECTS.has(effect_name):
				effect_target = _get_speaker_portrait(String(eff.get("target", "")), "line %s effect '%s'" % [textline_index + 1, effect_name])
				if effect_target == null:
					continue
			match effect_name:
				"portrait-sil":
					effect_target.modulate = Color(0,0,0)
				"portrait-normal":
					effect_target.modulate = Color(1,1,1)
				"dim":
					effect_target.dim()
				"loud":
					text_body.label_settings.font_size *= 1.8
				"quiet":
					text_body.label_settings.font_size *= 0.8
				"zoom":
					effect_target.zoom()
				"teleport":
					effect_target.teleport(eff.pos)
				"sound":
					if scrub: break
					match String(eff.get("sound", "")):
						"surprise":
							$AudioStreamPlayer_surprise.play()
						_:
							pass
				_:
					continue
	else:
		bobber_check.emit("effects_complete")
	
	var has_animations = true if !cur_line.get("animations",[]).is_empty() else false
	if has_animations:
		var dispatched_animations := 0
		for anim in cur_line.animations:
			var anim_name := String(anim.get("name", ""))
			if not KNOWN_ANIMATIONS.has(anim_name):
				push_warning("[DialogueOverlay] Unknown animation '%s' on line %s." % [anim_name, textline_index + 1])
				continue
			var anim_target := _get_speaker_portrait(String(anim.get("target", "")), "line %s animation '%s'" % [textline_index + 1, anim_name])
			if anim_target == null:
				continue
			dispatched_animations += 1
			match anim_name:
				"slide":
					anim_target.slide(anim.pos, speed)
				"shake":
					anim_target.shake(speed)
				"hop":
					anim_target.hop()
					if !scrub: $AudioStreamPlayer_fwip.play()
				"double_hop":
					anim_target.double_hop(speed)
					if !scrub: $AudioStreamPlayer_fwip.play()
				"interact":
					anim_target.interact(speed)
				"toggle_fade":
					anim_target.toggle_fade(speed)
				"question":
					anim_target.show_question(speed)
				_:
					continue
		expected_anims = dispatched_animations
		if dispatched_animations == 0:
			bobber_check.emit("animations_complete")
	else:
		expected_anims = 0
		bobber_check.emit("animations_complete")


var toggle_dialog_tween
func toggle_dialog():
	if toggle_dialog_tween:
		toggle_dialog_tween.kill()
	toggle_dialog_tween = create_tween()
	var tween_dur = 0.3
	var fade_dir: Color = Color(1,1,1,1) #Default fade-in
	if visible:
		fade_dir = Color(1,1,1,0)
	else:
		visible = true
		modulate = Color(1,1,1,0)
	
	toggle_dialog_tween.tween_property(self, "modulate", fade_dir, tween_dur)
	toggle_dialog_tween.tween_callback(func(): if modulate == Color(1,1,1,0): visible = false)
	await toggle_dialog_tween.finished
	_dialogue_fade_finished.emit()
	
	set_physics_process(!is_physics_processing())


var anims_finished = 0
var expected_anims = 0
func _on_anim_finished():
	if !current_event[textline_index].has("animations"): return
	
	anims_finished += 1
	if Global.flags.DebugMode:
		print("(Alon) Animation %s of %s finished." % [anims_finished, expected_anims])
	
	if anims_finished >= expected_anims:
		if !current_event[textline_index].has("text"):
			await get_tree().create_timer(0.6).timeout # Delay anim-only lines
		bobber_check.emit("animations_complete")


var skip_text := false
func _type_text(line: String) -> void:
	text_body.text = ""
	text_body.label_settings.font_size = default_font_size
	
	if current_event[textline_index].has("animations") or current_event[textline_index].has("effects"):
		await get_tree().create_timer(0.5).timeout # Delay to let anim/effect SFX play
	
	for c in line:
		if _abort_text: 
			text_body.text = ""
			_abort_text = false
			return
		
		if skip_text:
			text_body.text = line
			break
			
		text_body.text += c
		match c:
			"?", ".", "-", "!", ",":
				await get_tree().create_timer(punctuation_time).timeout
			" ":
				await get_tree().create_timer(space_time).timeout
			_:
				await get_tree().create_timer(letter_time).timeout
				
				if !(text_body.text.right(1) in ["?", ".", "-", "!", ",", " "]):
					if text_body.text.right(2).left(1) != c: # if same character, continue same pitch
						audio_player.pitch_scale = randf_range(0.90, 1.05)
						if text_body.text.right(1) in ["a", "e", "i", "o", "u"]:
							audio_player.pitch_scale += 0.2
						if text_body.text.right(1) == text_body.text.right(1).capitalize():
							audio_player.pitch_scale += 0.2
						if current_event[textline_index].has("effects"):
							if current_event[textline_index].effects.find({"name": "loud"}, 0):
								audio_player.pitch_scale -= 0.2
							if current_event[textline_index].effects.find({"name": "quiet"}, 0):
								audio_player.pitch_scale += 0.4
					audio_player.play()
	
	bobber_check.emit("text_complete")


func _check_bobber(signal_name):
	_ready_flags[signal_name] = true
	
	var proceed : bool = _ready_flags.text_complete and _ready_flags.animations_complete and _ready_flags.effects_complete
	if !proceed: return
	
	if current_event[textline_index].has("text") && !skip_text:
		await get_tree().create_timer(0.2).timeout # small delay to prevent double clicking
	$TextStopper.visible = true
	$TextStopper/AnimationPlayer.play("ContinueBobber")
		
	if !current_event[textline_index].has("text") and textline_index < current_event.size()-1:
		next_textline() # auto play non-text lines
	elif !current_event[textline_index].has("text") and textline_index == current_event.size()-1:
		_conclude_dialog()


var _abort_text : bool = false
func _on_debug_slider_drag_ended(value_changed : bool):
	_reset()
	_abort_text = !value_changed
	$TextStopper.visible = false
	$TextStopper/AnimationPlayer.stop()
	textline_index = -1
	while textline_index < int(debug_line_track.value)-1:
		next_textline(true)
	
	skip_text = false
	next_textline()


const LineEditorScene = preload("res://scenes/LineEditor.tscn")
func _rebuild_editor_list():
	var le_prefix = "HBoxContainer"
	for child in $ScrollContainer/LineEditorContainer.get_children():  # remove all children first
		$ScrollContainer/LineEditorContainer.remove_child(child)
		child.free()
		
	for i in current_event.size():
		var le = LineEditorScene.instantiate()
		le.name = str(i)
		le.get_node(le_prefix + "/IndexLabel").text = str(i)
		le.get_node(le_prefix + "/LineEdit").text = current_event[i].get("text","")

		var ob = le.get_node(le_prefix + "/ActiveSpeakerOptionButton")
		ob.clear()
		var ob_list = ["none"]
		for s in speaker_setup:
			ob_list.append(s.name)
		var sel = ob_list.find(current_event[i].get("active_speaker","none"), 0)
		for s in ob_list:
			ob.add_item(s)
		ob.selected = sel

		ob.connect("item_selected", Callable(self, "_on_speaker_changed").bind(i), 1)
		le.get_node(le_prefix + "/LineEdit").connect("text_changed", Callable(self, "_on_text_changed").bind(i), 1)
		le.get_node(le_prefix + "/MoveUpButton").connect("pressed", Callable(self, "swap_lines").bind(i, i-1), 1)
		le.get_node(le_prefix + "/MoveDownButton").connect("pressed", Callable(self, "swap_lines").bind(i, i+1), 1)
		le.get_node(le_prefix + "/RemoveLineButton").connect("pressed", Callable(self, "_on_remove_line").bind(i), 1)
		
		_populate_effects_for_line(le, i)
		_populate_animations_for_line(le, i)
		
		$ScrollContainer/LineEditorContainer.add_child(le)


func _on_text_changed(index:int):
	var le_txt = $ScrollContainer/LineEditorContainer.get_node(str(index) + "/HBoxContainer/LineEdit")
	current_event[index]["text"] = le_txt.text


func _on_speaker_changed(selected_id:int, index:int):
	current_event[index]["active_speaker"] = ("none" if selected_id <= 0 else speaker_setup[selected_id-1].name)


func swap_lines(a:int, b:int):
	if a < 0 or b < 0 or a >= current_event.size() or b >= current_event.size():
		return
	var tmp = current_event[a]
	current_event[a] = current_event[b]
	current_event[b] = tmp
	_rebuild_editor_list()


func _on_remove_line(index:int):
	current_event.remove_at(index)
	_rebuild_editor_list()
	debug_line_track.max_value = current_event.size()-1


func _on_add_line_button_pressed():
	var new_line = {}
	# insert after the current slider index
	var insert_at = clamp(textline_index + 1, 0, current_event.size())
	current_event.insert(insert_at, new_line)
	_rebuild_editor_list()
	debug_line_track.max_value = current_event.size()-1


const AnimEditorScene = preload("res://scenes/animation_editor.tscn")
func _populate_animations_for_line(le:Control, line_idx:int):
	le.get_node("AddAnimButton").connect("pressed", Callable(self, "_on_add_animation").bind(line_idx), 1)
	
	var hasAnims = current_event[line_idx].get("animations",[])
	if hasAnims.is_empty(): return
	
	var list  = le.get_node("AnimList") as VBoxContainer
	for child in list.get_children():  # remove all children first
		child.queue_free()
	
	for j in range(current_event[line_idx]["animations"].size()):
		var data = current_event[line_idx]["animations"][j]
		var ae = AnimEditorScene.instantiate() as HBoxContainer
		var speaker_names = speaker_setup.map(func(x): return x["name"])
		list.add_child(ae)
		await ae.call_deferred("setup", data, speaker_names)
		ae.connect("changed", Callable(self, "_on_animation_changed").bind(line_idx, j), 1)
		ae.connect("remove_anim_pressed", Callable(self, "_on_animation_removed").bind(line_idx, j), 1)


func _on_animation_changed(new_data:Dictionary, line_idx:int, anim_idx:int):
	current_event[line_idx]["animations"][anim_idx] = new_data


func _on_animation_removed(line_idx:int, anim_idx:int):
	current_event[line_idx]["animations"].remove_at(anim_idx)
	call_deferred("_rebuild_editor_list")


func _on_add_animation(line_idx:int):
	var arr = current_event[line_idx].get("animations", [])
	arr.append({ "name":"slide", "target":speaker_setup[0].name, "pos":0.0 })
	current_event[line_idx]["animations"] = arr
	call_deferred("_rebuild_editor_list")


const EffectEditorScene = preload("res://scenes/effect_editor.tscn")
func _populate_effects_for_line(le:Control, line_idx:int):
	le.get_node("AddEffectButton").connect("pressed", Callable(self, "_on_add_effect").bind(line_idx), 1)
	
	var hasEffects = current_event[line_idx].get("effects",[])
	if hasEffects.is_empty(): return
	
	var list  = le.get_node("EffectList") as VBoxContainer
	for child in list.get_children():  # remove all children first
		child.queue_free()
	
	for j in range(current_event[line_idx]["effects"].size()):
		var data = current_event[line_idx]["effects"][j]
		var ae = EffectEditorScene.instantiate() as HBoxContainer
		var speaker_names = speaker_setup.map(func(x): return x["name"])
		list.add_child(ae)
		await ae.call_deferred("setup", data, speaker_names)
		ae.connect("changed", Callable(self, "_on_effect_changed").bind(line_idx, j), 1)
		ae.connect("remove_effect_pressed", Callable(self, "_on_effect_removed").bind(line_idx, j), 1)


func _on_effect_changed(new_data:Dictionary, line_idx:int, eff_idx:int):
	current_event[line_idx]["effects"][eff_idx] = new_data


func _on_effect_removed(line_idx:int, eff_idx:int):
	current_event[line_idx]["effects"].remove_at(eff_idx)
	call_deferred("_rebuild_editor_list")


func _on_add_effect(line_idx:int):
	var arr = current_event[line_idx].get("effects", [])
	arr.append({ "name":"portrait-sil", "target":speaker_setup[0].name, "pos":0.0 })
	current_event[line_idx]["effects"] = arr
	call_deferred("_rebuild_editor_list")


func _populate_load_dropdown():
	var dir = DirAccess.open(EVENTS_DIR)
	var load_dropdown = $HBoxContainer/LoadOptionButton
	if not dir:
		push_error("(Alon) Could not open events folder: " + EVENTS_DIR)
		return
	load_dropdown.clear()
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and (fname.ends_with(".json") or fname.ends_with(".cutscene")):
			load_dropdown.add_item(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	if load_dropdown.get_item_count() > 0:
		load_dropdown.selected = 0


func _on_load_scene_button_pressed():
	var load_dropdown = $HBoxContainer/LoadOptionButton
	var idx = load_dropdown.selected
	if idx < 0: return
	
	var file_name = load_dropdown.get_item_text(idx)
	var path = EVENTS_DIR + "/" + file_name
	var scene_data := _load_scene_data(path)
	_report_scene_load_messages(scene_data, path)
	if not scene_data.get("errors", []).is_empty():
		return
	_apply_speaker_setup(scene_data.get("speakers", []))
	var eventDick : Array[Dictionary] = []
	for event_line in scene_data.get("event", []):
		eventDick.append(event_line)
	if not _validate_scene_event(eventDick, path):
		return
	_begin_dialogue_playback(eventDick, true, false)


func _on_save_scene_button_pressed():
	
	var script_name = $HBoxContainer/SaveTextEdit.text.strip_edges()
	if script_name == "":
		push_error("(Alon) Please enter a name before saving.")
		return
	if not script_name.ends_with(".json"):
		script_name += ".json"
	var path = EVENTS_DIR + "/" + script_name
	
	var json = JSON.stringify(current_event, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("(Alon) Cannot write to: " + path)
		return
	file.store_string(json)
	file.close()
	
	_populate_load_dropdown()


#TODO make this better ?
func _on_new_scene_button_pressed():
	dialogue_finished = false
	current_event = [{},{}]
	debug_line_track.min_value = 0
	debug_line_track.max_value = current_event.size()-1
	debug_line_track.value = 0
	textline_index = -1
	_reset()
	next_textline()
	_rebuild_editor_list()
