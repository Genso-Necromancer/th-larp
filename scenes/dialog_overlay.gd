extends Control

@onready var texturerect = $PortraitsNode/SpeakerPortrait
@onready var text_body = $ForegroundElements/TextBody
@onready var name_label = $ForegroundElements/HBoxContainer/NameLabel
@onready var title_label = $ForegroundElements/HBoxContainer/TitleLabel

@export var draw_speed = 30

var portrait = preload("res://speaker_portrait.tscn")
var text_count = 0
var textline_index = -1
var line_is_finished = false

var example_dict = [
	{
		"active_speaker": "Sakula",
		"text": "Just know, the milady's with me. With that out of the way, how may I be of service?",
		"effects": [{"name": "portrait-sil", "target": "Sakula"}]
	},
	{
		"text": "This was just a test... OK!",
		"effects": [{"name": "portrait-normal", "target": "Sakula"}],
		"animations": [{"name": "slide", "target": "Sakula", "pos": 0.5}]
	},
	{
		"active_speaker": "Pakooli",
		"text": "Hey I just ordered a pizz- ...oh sorry for interrupting.",
	},
	{
		"active_speaker": "Sirno",
		"text": "Erm... What the sigma?",
		"animations": [{"name": "slide", "target": "Sakula", "pos": 0.9},{"name": "slide", "target": "Pakooli", "pos": 0.5}]
	},
	{
		"animations": [{"name": "shake", "target": "Pakooli"}, {"name": "shake", "target": "Sakula"}]
	},
	{
		"active_speaker": "Pakooli",
		"text": "dieee!!",
		"animations": [{"name": "slide", "target": "Pakooli", "pos": 0.15}],
		"effects": [{"name": "dim", "target": "Sakula"}]
	},
	{
		"animations": [{"name": "shake", "target": "Sirno"}]
	},
	{
		"animations": [{"name": "slide", "target": "Sirno", "pos": -0.2}]
	},
	{
		"active_speaker": "Sirno",
		"text": "im died."
	},
	{
		"active_speaker": "Sakula",
		"text": "boy am i glad shes gone.",
		"effects": [{"name": "portrait-normal", "target": "Sakula"}],
		"animations": [{"name": "slide", "target": "Sakula", "pos": 0.6}]
	},
	{
		"active_speaker": "Sakula",
		"text": "lets get out of here.",
		"animations": [{"name": "toggle_fade", "target": "Sakula"}, {"name": "toggle_fade", "target": "Pakooli"}]
	},
	{
		"active_speaker": "Sirno",
		"text": "but spring all ways return. !!!",
		"animations": [{"name": "slide", "target": "Sirno", "pos": 0.5}]
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
		"portrait": "res://sprites/PatchouliPrt.png"
	}
]


signal dialog_finished
signal line_finished(textline_index)


func _ready():
	line_finished.connect(_on_line_finished)
	prepare_new_dialogue(example_dict)


func _unhandled_input(event):		
	if not visible: return
	
	if event.is_action_released("ui_accept"):
		if !example_dict[textline_index].has("text"): return
		if !$TextStopper/AnimationPlayer.is_playing():
			line_finished.emit(textline_index)
		elif textline_index < example_dict.size() - 1:
			next_textline()
		else:
			dialog_finished.emit()
			toggle_dialog()


var delta_speed = 0.0
var text_proceed = false
var anim_proceed = false
var effect_proceed = false
func _physics_process(delta):
	if text_proceed && anim_proceed && effect_proceed && !$TextStopper.visible:
		if !example_dict[textline_index].has("text"):
			next_textline()
		else:
			$TextStopper.visible = true
			$TextStopper/AnimationPlayer.play("ContinueBobber")
	
	if !example_dict[textline_index].has("text"): return
		
	if text_count < example_dict[textline_index]["text"].length():
		if text_body.text.ends_with("?") or text_body.text.ends_with(".") or text_body.text.ends_with("-") or text_body.text.ends_with("!"):
			delta_speed += delta * draw_speed * 0.2
		else:
			delta_speed += delta * draw_speed
		text_body.text += example_dict[textline_index]["text"].substr(text_count, int(delta_speed))
		text_count += int(delta_speed)
		delta_speed -= int(delta_speed)
	elif !line_is_finished:
		line_finished.emit(textline_index)


# Can I put these nodes into an array instead of using find_child?
func prepare_new_dialogue(_script):
	for speaker in speaker_setup:
		var new_portrait = portrait.instantiate()
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
	if !example_dict[index].has("text"): return

	text_count = example_dict[index]["text"].length()
	text_body.text = example_dict[index]["text"]
	line_is_finished = true
	text_proceed = true


func next_textline():
	textline_index += 1
	anims_finished = 0
	text_count = 0
	line_is_finished = false
	
	text_proceed = true if !example_dict[textline_index].has("text") else false
	anim_proceed = true if !example_dict[textline_index].has("animations") else false
	effect_proceed = true #if !example_dict[textline_index].has("effects") else false #right now, not handling
	
	delta_speed = 0.0
	text_body.text = ""
	$TextStopper.visible = false
	$TextStopper/AnimationPlayer.stop()
	
	var cur_line = example_dict[textline_index]
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
	#if example_dict[textline_index].has("title"):
		#title_label.text = cur_line["title"]
	#
	#if example_dict[textline_index].has("portrait"):
		#texturerect.texture = load(cur_line["portrait"])
	
	if cur_line.has("effects"): # TODO Add a default-to-Active_Speaker fallback if no Target is specified
		for eff in cur_line["effects"]:
			if eff.name == "portrait-sil":
				$PortraitsNode.find_child(eff.target,true,false).modulate = Color(0,0,0)
			if eff.name == "portrait-normal":
				$PortraitsNode.find_child(eff.target,true,false).modulate = Color(1,1,1)
			if eff.name == "dim":
				$PortraitsNode.find_child(eff.target,true,false).dim()
	
	if cur_line.has("animations"):
		for anim in cur_line["animations"]:
			if anim.name == "slide":
				$PortraitsNode.find_child(anim.target,true,false).slide(anim.pos)
			if anim.name == "shake":
				$PortraitsNode.find_child(anim.target,true,false).shake()
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


var anims_finished = 0
func _on_anim_finished():
	anims_finished += 1
	print("Animation %s of %s" % [anims_finished, example_dict[textline_index]["animations"].size()])
	
	if anims_finished == example_dict[textline_index]["animations"].size():
		if !example_dict[textline_index].has("text"):
			await get_tree().create_timer(0.6).timeout # Delay anim-only lines
		anim_proceed = true
