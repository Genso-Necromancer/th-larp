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
var speaker_setup = [
	{
		"name": "Sirno",
		"title": "honto no baka",
		"portrait": "res://sprites/Fairy TroublemakerPrt.png",
	},
	{
		"name": "Sakula",
		"title": "medio",
		"portrait": "res://sprites/SakuyaPrt.png",
	},
	{
		"name": "Pakooli",
		"title": "magical girl",
		"portrait": "res://sprites/th2.png"
	},
	{
		"name": "Remi",
		"title": "fiary stomper",
		"portrait": "res://sprites/th1.png"
	}
]


func _ready():
	self.visible = false
	foreground_elements.visible = false
	set_physics_process(false)
	_reset()
	# TODO Kill all children in PortaitsNode?
	bobber_check.connect(_check_bobber)
	
	debug_line_track.connect("drag_ended", Callable(self, "_on_debug_slider_drag_ended"))
	debug_line_track.visible = Global.flags.DebugMode


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
	if event.is_action_released("debug_dialogue") and Global.flags.DebugMode and !is_physics_processing(): #For solo testing, intend to simply call this below function when ready to play scene 
		prepare_new_dialogue()
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
	speaker_portraits = {}
	for child in $PortraitsNode:
		child.queue_free()
	dialogue_finished = true
	toggle_dialog()
	await _dialogue_fade_finished
	dialog_finished.emit()


#Now called when a new map is loaded, right after the splash screen. See MapManager:_on_gui_splash_finished(). Will be called in more varied ways
##SceneScripts are stored on the map associated with them. There is to be a Start and End scene to each Chapter that daisy chains things together with a moment for saving/loading in-between last End and new Start
func prepare_new_dialogue(new_event:String= ""):
	var parser = JasonParser.new()
	GameState.change_state(self,GameState.gState.DIALOGUE_SCENE) #Used to avoid conflicting inputs. Currently only uses ACCEPT_PROMPT input script, could extend GenericScript to make a new one specifically for this scene. You'll know what to do when you look at existing ones.
	if new_event: 
		var eventDick : Array[Dictionary] = parser.parse_json(new_event)
		current_event = eventDick
	else: current_event = example_dict #subverts variable typing to give a dictionary as default, normally only want to pass ScenScript Resource
	toggle_dialog()
	for speaker in speaker_setup:
		var new_portrait:PortraitRect= portrait.instantiate()
		new_portrait.name = speaker.name
		new_portrait.speaker_name = speaker.name
		new_portrait.speaker_title = speaker.title
		new_portrait.texture = load(speaker.portrait)
		new_portrait.visible = false
		new_portrait.anim_finished.connect(_on_anim_finished)
		$PortraitsNode.add_child(new_portrait)
	for pr in $PortraitsNode.get_children():
		speaker_portraits[ pr.name ] = pr
	
	debug_line_track.min_value = 0
	debug_line_track.max_value = current_event.size()-1
	debug_line_track.value = 0
	
	# await _dialogue_fade_finished # works, but doesn't look good atm
	textline_index = -1
	next_textline()


func next_textline(scrub : bool = false):
	textline_index += 1
	if !scrub:
		debug_line_track.value = textline_index
	anims_finished = 0
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
	
	if cur_line.has("text") && !scrub:
		foreground_elements.visible = true
		_type_text(cur_line.text)
	else:
		foreground_elements.visible = false
		bobber_check.emit("text_complete")
	
	if cur_line.has("background"):
		if cur_line.background == "null" or cur_line.background == "none":
			background_texture_rect.texture = null
		else:
			background_texture_rect.texture = load(cur_line.background)
	
	if cur_line.has("active_speaker"):
		if cur_line.active_speaker != "none":
			var active_speaker = speaker_portraits[ cur_line.active_speaker ]
			name_label.text = active_speaker.speaker_name
			title_label.text = active_speaker.speaker_title
			active_speaker.visible = true
		else:
			name_label.text = ""
			title_label.text = ""
	
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
	
	if cur_line.has("effects"): # TODO Add a default-to-Active_Speaker fallback if no Target is specified?
		bobber_check.emit("effects_complete")
		for eff in cur_line.effects:
			match eff.name:
				"portrait-sil":
					speaker_portraits[eff.target].modulate = Color(0,0,0)
				"portrait-normal":
					speaker_portraits[eff.target].modulate = Color(1,1,1)
				"dim":
					speaker_portraits[eff.target].dim()
				"loud":
					text_body.label_settings.font_size *= 1.8
				"quiet":
					text_body.label_settings.font_size *= 0.8
				"zoom":
					speaker_portraits[eff.target].zoom()
				"teleport":
					speaker_portraits[eff.target].teleport(eff.pos)
				"sound":
					if scrub: break
					match eff.sound:
						"surprise":
							$AudioStreamPlayer_surprise.play()
						_:
							pass
	else:
		bobber_check.emit("effects_complete")
	
	if cur_line.has("animations"):
		for anim in cur_line.animations:
			match anim.name:
				"slide":
					speaker_portraits[anim.target].slide(anim.pos, speed)
				"shake":
					speaker_portraits[anim.target].shake(speed)
				"hop":
					speaker_portraits[anim.target].hop()
					if !scrub: $AudioStreamPlayer_fwip.play(speed)
				"double_hop":
					speaker_portraits[anim.target].double_hop(speed)
					if !scrub: $AudioStreamPlayer_fwip.play()
				"interact":
					speaker_portraits[anim.target].interact(speed)
				"toggle_fade":
					speaker_portraits[anim.target].toggle_fade(speed)
				"question":
					speaker_portraits[anim.target].show_question(speed)
	else:
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
func _on_anim_finished():
	if !current_event[textline_index].has("animations"): return
	
	anims_finished += 1
	if Global.flags.DebugMode:
		print("(Alon) Animation %s of %s finished." % [anims_finished, current_event[textline_index]["animations"].size()])
	
	if anims_finished == current_event[textline_index]["animations"].size():
		if !current_event[textline_index].has("text"):
			await get_tree().create_timer(0.6).timeout # Delay anim-only lines
		bobber_check.emit("animations_complete")


var skip_text := false
func _type_text(line: String) -> void:
	text_body.text = ""
	text_body.label_settings.font_size = default_font_size
	
	if current_event[textline_index].has("animations") or current_event[textline_index].has("effects"):
		await get_tree().create_timer(0.5).timeout # Delay to let anim/effect SFX play
	
	for char in line:
		if _abort_text: 
			_abort_text = false
			return
		
		if skip_text:
			text_body.text = line
			break
			
		text_body.text += char
		match char:
			"?", ".", "-", "!", ",":
				await get_tree().create_timer(punctuation_time).timeout
			" ":
				await get_tree().create_timer(space_time).timeout
			_:
				await get_tree().create_timer(letter_time).timeout
				
				if !(text_body.text.right(1) in ["?", ".", "-", "!", ",", " "]):
					if text_body.text.right(2).left(1) != char: # if same character, continue same pitch
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
