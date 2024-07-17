extends Control

var textlines: Array[String] = ["Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum. Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.","Just know, the milady's with me. With that out of the way, how may I be of service?"]
@export var draw_speed = 1
var text_count = 0
var textline_index = 0


signal text_finished


func _ready():
	text_finished.connect(_on_text_finished) 


func _unhandled_input(event):
	if event.is_action_released("ui_accept") && !$TextStopper/AnimationPlayer.is_playing():
		text_finished.emit()
	elif event.is_action_released("ui_accept"):
		if textline_index == textlines.size() - 1:
			pass
		else:
			text_count = 0
			textline_index += 1
			$TextBody.text = ""
			$TextStopper.visible = false
			$TextStopper/AnimationPlayer.stop()


func _physics_process(delta):
	# This method is a "static text speed" rather than a percentage of visible text!
	if text_count < textlines[textline_index].length():
		$TextBody.text += textlines[textline_index].substr(text_count, draw_speed)
		text_count += draw_speed
	else:
		text_finished.emit()


func _on_text_finished():
	$TextBody.text = textlines[textline_index]
	$TextStopper.visible = true
	$TextStopper/AnimationPlayer.play("ContinueBobber")
