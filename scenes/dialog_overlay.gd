extends Control

#@onready var portrait_origin = $PortraitRect.position
@onready var texturerect = $PortraitsNode/SpeakerPortrait

@export var draw_speed = 20

var text_count = 0
var textline_index = -1
var line_is_finished = false

var example_dict = {
	0: {
		"active_speaker": "Sakula",
		"text": "Just know, the milady's with me. With that out of the way, how may I be of service?",
		#"speaker": "Sakula",
		#"title": "medio",
		#"portrait": "res://sprites/SakuyaPrt.png",
		"effects": [{"name": "portrait-sil", "target": "Sakula"}]
	},
	1: {
		"text": "This was just a test... OK!",
		"effects": [{"name": "portrait-normal", "target": "Sakula"}],
		"animations": [{"name": "slide", "target": "Sakula", "pos": 0.5}]
	},
	2: {
		"active_speaker": "Pakooli",
		"text": "Hey I just ordered a pizz- oh sorry for interrupting.",
		"speaker": CutsceneManager.ACTORS.PATCHOULI,
		#"speaker": "Pakooli",
		#"title": "magical girl",
		#"portrait": "res://sprites/PatchouliPrt.png"
	},
	3: {
		"active_speaker": "Sasha",
		"text": "Erm... What the sigma?",
		"speaker": "Sasha",
		"title": "female boy",
		"portrait": "res://sprites/SashaPrt.png",
		"animations": [{"anim": "slide", "target": "Sakula", "pos": 0.9},{"anim": "slide", "target": "Pakooli", "pos": 0.5}]
	},
	4: {
		"active_speaker": "Pakooli",
		"text": "dieee!!",
		"animations": [{"anim": "slide", "target": "Pakooli", "pos": 0.15}]
	}
}


# Idea: Max of... lets say 5 speakers can be defined per "dialogue" sequence
# so here is an array of speakers to initialize
# there appears to be a sort of "speakers on screen" that cycle, and replace? in BA
var speaker_setup = [
	{
		"name": "Sasha",
		"title": "female boy",
		"portrait": "res://sprites/SashaPrt.png",
	},
	{
		"name": "Sakula",
		"title": "medio",
		"portrait": "res://sprites/SakuyaPrt.png",
	},
	{
		#"name": CutsceneManager.ACTORS.PATCHOULI
		"name": "Pakooli",
		"title": "magical girl",
		"portrait": "res://sprites/PatchouliPrt.png"
	}
]


signal text_finished
signal line_finished(textline_index)


func _ready():
	var portrait = preload("res://speaker_portrait.tscn")
	for speaker in speaker_setup:
		var new_portrait = portrait.instantiate()
		new_portrait.name = speaker.name
		new_portrait.speaker_name = speaker.name
		new_portrait.speaker_title = speaker.title
		new_portrait.texture = load(speaker.portrait)
		new_portrait.visible = false
		$PortraitsNode.add_child(new_portrait)
	
	line_finished.connect(_on_line_finished)
	next_textline()


func _unhandled_input(event):
	if event.is_action_pressed("ui_return"):
		toggle_dialog()
		
	if not visible: return
	
	if event.is_action_released("ui_accept"):
		if !$TextStopper/AnimationPlayer.is_playing():
			line_finished.emit(textline_index)
		elif textline_index < example_dict.size() - 1:
			next_textline()
		else:
			toggle_dialog()


var delta_speed = 0.0
func _physics_process(delta):
	if !example_dict[textline_index].has("text"): return
		
	if text_count < example_dict[textline_index]["text"].length():
		if $TextBody.text.ends_with("?") or $TextBody.text.ends_with("."):
			delta_speed += delta * draw_speed * 0.15
		else:
			delta_speed += delta * draw_speed
		$TextBody.text += example_dict[textline_index]["text"].substr(text_count, int(delta_speed))
		text_count += int(delta_speed)
		delta_speed -= int(delta_speed)
	elif !line_is_finished:
		line_finished.emit(textline_index)


func _on_line_finished():
	if !example_dict[textline_index].has("text"): return
	
	line_is_finished = true
	text_count = example_dict[textline_index]["text"].length()
	$TextBody.text = example_dict[textline_index]["text"]
	$TextStopper.visible = true
	$TextStopper/AnimationPlayer.play("ContinueBobber")


func next_textline():
	text_count = 0
	line_is_finished = false
	textline_index += 1
	$TextBody.text = ""
	$TextStopper.visible = false
	$TextStopper/AnimationPlayer.stop()
	
	var cur_line = example_dict[textline_index]
	if cur_line.has("active_speaker"):
		var active_speaker = $PortraitsNode.find_child(cur_line["active_speaker"],true,false)
		$HBoxContainer/NameLabel.text = active_speaker.speaker_name
		$HBoxContainer/TitleLabel.text = active_speaker.speaker_title
		active_speaker.visible = true
	
	if cur_line.has("speaker"):
		if cur_line["speaker"] is int:
			var predefined_speaker = CutsceneManager.ActorData[cur_line["speaker"]]
			$HBoxContainer/NameLabel.text = predefined_speaker["name"]
			$HBoxContainer/TitleLabel.text = predefined_speaker["title"]
			texturerect.texture = predefined_speaker["portrait"]
		elif cur_line["speaker"] == "none":
			$HBoxContainer/NameLabel.text = ""
			$HBoxContainer/TitleLabel.text = ""
		else:
			$HBoxContainer/NameLabel.text = cur_line["speaker"]
	
	if example_dict[textline_index].has("title"):
		$HBoxContainer/TitleLabel.text = cur_line["title"]
	
	if example_dict[textline_index].has("portrait"):
		texturerect.texture = load(cur_line["portrait"])
	
	if cur_line.has("effects"): # TODO Add a default-to-Active_Speaker fallback if no Target is specified
		for eff in cur_line["effects"]:
			if eff.name == "portrait-sil":
				$PortraitsNode.find_child(eff.target,true,false).modulate = Color(0,0,0)
			if eff.name == "portrait-normal":
				$PortraitsNode.find_child(eff.target,true,false).modulate = Color(1,1,1)
			#if effect == "angry": # This can probably just be an animation player effect? but...
				#$PortraitRect.position.x += 15
				#var tween = create_tween()
				#tween.tween_property($PortraitRect, "position", portrait_origin, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	
	if cur_line.has("animations"):
		for anim in cur_line["animations"]:
			if anim.name == "slide":
				$PortraitsNode.find_child(anim.target,true,false).slide(anim.pos)
			


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
