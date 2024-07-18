extends Control

@onready var portrait_origin = $PortraitRect.position

@export var draw_speed = 1

var text_count = 0
var textline_index = -1
var text_is_finished = false

var example_dict = {
	0: {
		"text": "Just know, the milady's with me. With that out of the way, how may I be of service?",
		"speaker": "Sakula",
		"title": "medio",
		"portrait": "res://sprites/SakuyaPrt.png",
		"effects": ["portrait-sil"]
	},
	1: {
		"text": "This was just a test... OK!",
		"effects": ["portrait-normal","angry"]
	},
	2: {
		"text": "Hey I just ordered a pizz- oh sorry for interrupting.",
		"speaker": CutsceneManager.ACTORS.PATCHOULI,
		#"speaker": "Pakooli",
		#"title": "magical girl",
		#"portrait": "res://sprites/PatchouliPrt.png"
	},
	3: {
		"text": "Erm... What the sigma?",
		"speaker": "Sasha",
		"title": "female boy",
		"portrait": "res://sprites/SashaPrt.png",
	}
}


signal text_finished


func _ready():
	text_finished.connect(_on_text_finished)
	next_textline()


func _unhandled_input(event):
	if event.is_action_pressed("ui_return"):
		toggle_dialog()
		
	if not visible: return
	
	if event.is_action_released("ui_accept"):
		if !$TextStopper/AnimationPlayer.is_playing():
			text_finished.emit()
		elif textline_index < example_dict.size() - 1:
			next_textline()
		else:
			toggle_dialog()


func _physics_process(delta):
	if text_count < example_dict[textline_index]["text"].length():
		$TextBody.text += example_dict[textline_index]["text"].substr(text_count, draw_speed)
		text_count += draw_speed
	elif !text_is_finished:
		text_finished.emit()


func _on_text_finished():
	text_is_finished = true
	text_count = example_dict[textline_index]["text"].length()
	$TextBody.text = example_dict[textline_index]["text"]
	$TextStopper.visible = true
	$TextStopper/AnimationPlayer.play("ContinueBobber")


func next_textline():
	text_count = 0
	text_is_finished = false
	textline_index += 1
	$TextBody.text = ""
	$TextStopper.visible = false
	$TextStopper/AnimationPlayer.stop()
	
	var cur_line = example_dict[textline_index]
	if cur_line.has("speaker"):
		if cur_line["speaker"] is int:
			var predefined_speaker = CutsceneManager.ActorData[cur_line["speaker"]]		
			$HBoxContainer/NameLabel.text = predefined_speaker["name"]
			$HBoxContainer/TitleLabel.text = predefined_speaker["title"]
			$PortraitRect.texture = predefined_speaker["portrait"]
		else:
			$HBoxContainer/NameLabel.text = cur_line["speaker"]
	if example_dict[textline_index].has("title"):
		$HBoxContainer/TitleLabel.text = cur_line["title"]
	if example_dict[textline_index].has("portrait"):
		$PortraitRect.texture = load(cur_line["portrait"])
	
	if cur_line.has("effects"):
		for effect in cur_line["effects"]:
			if effect == "portrait-sil":
				$PortraitRect.modulate = Color(0,0,0)
			if effect == "portrait-normal":
				$PortraitRect.modulate = Color(1,1,1)
			if effect == "angry": # This can probably just be an animation player effect? but...
				$PortraitRect.position.x += 15
				var tween = create_tween()
				tween.tween_property($PortraitRect, "position", portrait_origin, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)


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
