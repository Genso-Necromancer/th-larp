extends Control
##Dialogue Arrays are stored in /scenes/cutscenes as *_event.json files. Specifc file paths are stored on the relevant game map.[br]
##Paths are sent via prepare_new_dialogue() where they're parsed using a JasonParser returning the Array[Dictionary] and sets the event in motion.
class_name DialogueOverlay
signal dialog_finished
signal line_finished(textline_index)
signal _dialogue_fade_finished
#signal dialogue_loaded
@onready var texturerect = $PortraitsNode/SpeakerPortrait
@onready var text_body = $ForegroundElements/TextBody
@onready var name_label = $ForegroundElements/HBoxContainer/NameLabel
@onready var title_label = $ForegroundElements/HBoxContainer/TitleLabel
@export var draw_speed = 30

var portrait : = preload("res://scenes/cutscenes/speaker_portrait.tscn")
var dialogue_finished := false
var text_count := 0
var textline_index := -1
var line_is_finished = false
var current_event : Array[Dictionary]
var example_dict = [
	{
		"active_speaker": "Remi",
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.75}]
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
		"text": "Hey-"
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
		"text": "Were you talking to yourself ?",
		"effects": [{"name": "quiet"}]
	},
	{
		"active_speaker": "Remi",
		"text": "Get out of my room I'm playing Minecraft!!",
		"animations": [{"name": "hop", "target": "Remi"}]
	},
]

	#{
		#"active_speaker": "Sakula",
		#"text": "Just know, the milady's with me. With that out of the way, how may I be of service?",
		#"effects": [{"name": "portrait-sil", "target": "Sakula"}]
	#},
	#{
		#"text": "This was just a test... OK!",
		#"effects": [{"name": "portrait-normal", "target": "Sakula"},{"name": "loud"}],
		#"animations": [{"name": "slide", "target": "Sakula", "pos": 0.5}]
	#},
	#{
		#"active_speaker": "Pakooli",
		#"text": "Hey I just ordered a pizz- ...oh sorry for interrupting.",
		#"effects": [{"name": "quiet"}]
	#},
	#{
		#"active_speaker": "Sirno",
		#"text": "Erm... What the sigma?",
		#"animations": [{"name": "slide", "target": "Sakula", "pos": 0.9},{"name": "slide", "target": "Pakooli", "pos": 0.5}]
	#},
	#{
		#"animations": [{"name": "shake", "target": "Pakooli"}, {"name": "shake", "target": "Sakula"},{"name": "interact", "target": "Sirno"}]
	#},
	#{
		#"active_speaker": "Pakooli",
		#"text": "dieee!!",
		#"animations": [{"name": "slide", "target": "Pakooli", "pos": 0.25}, {"name": "hop", "target": "Pakooli"}],
		#"effects": [{"name": "dim", "target": "Sakula"}]
	#},
	#{
		#"animations": [{"name": "double_hop", "target": "Sirno"}]
	#},
	#{
		#"animations": [{"name": "slide", "target": "Sirno", "pos": -0.2}]
	#},
	#{
		#"active_speaker": "Sirno",
		#"text": "im died."
	#},
	#{
		#"active_speaker": "Sakula",
		#"text": "boy am i glad shes gone.",
		#"effects": [{"name": "portrait-normal", "target": "Sakula"}],
		#"animations": [{"name": "slide", "target": "Sakula", "pos": 0.6}]
	#},
	#{
		#"active_speaker": "Sakula",
		#"text": "lets get out of here.",
		#"animations": [{"name": "toggle_fade", "target": "Sakula"}, {"name": "toggle_fade", "target": "Pakooli"}]
	#},
	#{
		#"animations": [{"name": "slide", "target": "Sirno", "pos": 0.5}]
	#},
	#{
		#"active_speaker": "Sirno",
		#"text": "but spring all ways return. !!!",
		#"effects": [{"name": "zoom", "target": "Sirno"}]
	#}


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
		"portrait": "res://sprites/th2.png" #"res://sprites/PatchouliPrt.png"
	},
	{
		"name": "Remi",
		"title": "just racist",
		"portrait": "res://sprites/th1.png"
	}
]

#Would be nice to have a function to set a specific background image. With showing the game map as the default.
func _ready():
	self.visible = false
	set_physics_process(false) #Added to halt the scene from auto-playing on load
	line_finished.connect(_on_line_finished)


func _gui_input(event):
	if GameState.activeState == null:
			return
	if event is InputEventMouseMotion:
		GameState.activeState.mouse_motion(event)
	elif event is InputEventMouseButton:
		GameState.activeState.mouse_pressed(event)
	elif event is InputEventKey:
		GameState.activeState.event_key(event)


func _unhandled_input(event) -> void:
	if event.is_action_released("debug_dialogue") and Global.flags.DebugMode and !is_physics_processing(): #For solo testing, intend to simply call this below function when ready to play scene 
		prepare_new_dialogue()
	elif GameState.state != GameState.gState.DIALOGUE_SCENE: return
	elif event.is_action_released("ui_return"): toggle_dialog()
	elif not visible and is_physics_processing(): return
	#elif event.is_action_released("ui_accept"): 
		

##input from control state DIALOGUE_SCENE
func gui_accept():
	if GameState.state != GameState.gState.DIALOGUE_SCENE: return
	elif !current_event[textline_index].has("text"): return
	if !$TextStopper/AnimationPlayer.is_playing():
		line_finished.emit(textline_index)
	elif textline_index < current_event.size() - 1:
		next_textline()
	else: _conclude_dialog()
		


func _conclude_dialog() -> void:
	dialogue_finished = true
	toggle_dialog()
	await _dialogue_fade_finished
	dialog_finished.emit()
	

var delta_speed = 0.0
var text_proceed = false
var anim_proceed = false
var effect_proceed = false
func _physics_process(delta):
	if !dialogue_finished && text_proceed && anim_proceed && effect_proceed && !$TextStopper.visible:
		if !current_event[textline_index].has("text") and textline_index < current_event.size()-1:
			next_textline()
		elif textline_index >= current_event.size()-1: _conclude_dialog()
		else:
			$TextStopper.visible = true
			$TextStopper/AnimationPlayer.play("ContinueBobber")
	
	if !current_event[textline_index].has("text"): return
		
	if text_count < current_event[textline_index]["text"].length():
		if text_body.text.ends_with("?") or text_body.text.ends_with(".") or text_body.text.ends_with("-") or text_body.text.ends_with("!"):
			delta_speed += delta * draw_speed * 0.2
		else:
			delta_speed += delta * draw_speed
		text_body.text += current_event[textline_index]["text"].substr(text_count, int(delta_speed))
		text_count += int(delta_speed)
		delta_speed -= int(delta_speed)
	elif !line_is_finished:
		line_finished.emit(textline_index)


# Can I put these nodes into an array instead of using find_child?
# yes, but I'd use a dictionary for your use case
#Now called when a new map is loaded, right after the splash screen. See MapManager:_on_gui_splash_finished(). Will be called in more varied ways
##SceneScripts are stored on the map associated with them. There is to be a Start and End scene to each Chapter that daisy chains things together with a moment for saving/loading in-between last End and new Start
func prepare_new_dialogue(new_event:String= ""):
	var parser = JasonParser.new()
	var eventDick : Array[Dictionary] = parser.parse_json(new_event)
	GameState.change_state(self,GameState.gState.DIALOGUE_SCENE) #Used to avoid conflicting inputs. Currently only uses ACCEPT_PROMPT input script, could extend GenericScript to make a new one specifically for this scene. You'll know what to do when you look at existing ones.
	if new_event: current_event = eventDick
	else: current_event = example_dict #subverts variable typing to give a dictionary as default, normally only want to pass ScenScript Resource
	toggle_dialog()
	set_physics_process(true) #necessary with the new triggered way to start the scene
	for speaker in speaker_setup:
		var new_portrait:PortraitRect= portrait.instantiate()
		new_portrait.name = speaker.name
		new_portrait.speaker_name = speaker.name
		new_portrait.speaker_title = speaker.title
		new_portrait.texture = load(speaker.portrait)
		new_portrait.visible = false
		new_portrait.anim_finished.connect(_on_anim_finished)
		$PortraitsNode.add_child(new_portrait)
	textline_index = -1
	next_textline()


func _on_line_finished(index):
	if !current_event[index].has("text"): return

	text_count = current_event[index]["text"].length()
	text_body.text = current_event[index]["text"]
	line_is_finished = true
	text_proceed = true


func next_textline():
	textline_index += 1
	anims_finished = 0
	text_count = 0
	line_is_finished = false
	
	text_proceed = true if !current_event[textline_index].has("text") else false
	anim_proceed = true if !current_event[textline_index].has("animations") else false
	effect_proceed = true #if !current_event[textline_index].has("effects") else false #right now, not handling
	
	delta_speed = 0.0
	text_body.text = ""
	text_body.label_settings.font_size = 24 # default size 24
	$TextStopper.visible = false
	$TextStopper/AnimationPlayer.stop()
	
	var cur_line = current_event[textline_index]
	if !cur_line.has("text"):
		$ForegroundElements.visible = false
	else:
		$ForegroundElements.visible = true
	
	if cur_line.has("active_speaker"):
		var active_speaker = $PortraitsNode.find_child(cur_line["active_speaker"],true,false)
		name_label.text = active_speaker.speaker_name
		title_label.text = active_speaker.speaker_title
		active_speaker.visible = true
	
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
	
	if cur_line.has("effects"): # TODO Add a default-to-Active_Speaker fallback if no Target is specified
		for eff in cur_line["effects"]:
			if eff.name == "portrait-sil":
				$PortraitsNode.find_child(eff.target,true,false).modulate = Color(0,0,0)
			if eff.name == "portrait-normal":
				$PortraitsNode.find_child(eff.target,true,false).modulate = Color(1,1,1)
			if eff.name == "dim":
				$PortraitsNode.find_child(eff.target,true,false).dim()
			if eff.name == "loud":
				print("lets get louder")
				text_body.label_settings.font_size = 36
			if eff.name == "quiet":
				text_body.label_settings.font_size = 16
			if eff.name == "zoom":
				$PortraitsNode.find_child(eff.target,true,false).zoom()
	
	if cur_line.has("animations"):
		for anim in cur_line["animations"]:
			if anim.name == "slide":
				$PortraitsNode.find_child(anim.target,true,false).slide(anim.pos)
			if anim.name == "shake":
				$PortraitsNode.find_child(anim.target,true,false).shake()
			if anim.name == "hop":
				$PortraitsNode.find_child(anim.target,true,false).hop()
			if anim.name == "double_hop":
				$PortraitsNode.find_child(anim.target,true,false).double_hop()
			if anim.name == "interact":
				$PortraitsNode.find_child(anim.target,true,false).interact()
			if anim.name == "toggle_fade":
				$PortraitsNode.find_child(anim.target,true,false).toggle_fade()


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


var anims_finished = 0
func _on_anim_finished():
	anims_finished += 1
	print("Animation %s of %s" % [anims_finished, current_event[textline_index]["animations"].size()])
	
	if anims_finished == current_event[textline_index]["animations"].size():
		if !current_event[textline_index].has("text"):
			await get_tree().create_timer(0.6).timeout # Delay anim-only lines
		anim_proceed = true
