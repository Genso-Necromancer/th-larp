extends Control

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
		"effects": ["portrait-normal"]
	}
}


signal text_finished


func _ready():
	text_finished.connect(_on_text_finished)
	next_textline()


func _unhandled_input(event):
	if event.is_action_released("ui_accept") && !$TextStopper/AnimationPlayer.is_playing():
		text_finished.emit()
	elif event.is_action_released("ui_accept") && textline_index < example_dict.size() - 1:
		next_textline()



func _physics_process(delta):
	# This method is a "static text speed" rather than a percentage of visible text!
	if text_count < example_dict[textline_index]["text"].length():
		$TextBody.text += example_dict[textline_index]["text"].substr(text_count, draw_speed)
		text_count += draw_speed
	elif !text_is_finished:
		text_finished.emit()


func _on_text_finished():
	print("Text finished drawing")
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
	
	if example_dict[textline_index].has("speaker"):
		$HBoxContainer/NameLabel.text = example_dict[textline_index]["speaker"]
	if example_dict[textline_index].has("title"):
		$HBoxContainer/TitleLabel.text = example_dict[textline_index]["title"]
	if example_dict[textline_index].has("portrait"):
		$PortraitRect.texture = load(example_dict[textline_index]["portrait"])
	
	if example_dict[textline_index].has("effects"):
		for effect in example_dict[textline_index]["effects"]:
			if effect == "portrait-sil":
				$PortraitRect.modulate = Color(0,0,0)
			if effect == "portrait-normal":
				$PortraitRect.modulate = Color(1,1,1)
