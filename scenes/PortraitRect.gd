extends Control

var speaker_name = ""
var speaker_title = ""
var starting_pos = Vector2(64,400)

# Might use these...
signal anim_finished
signal effect_finished


func _ready():
	position = starting_pos


func _unhandled_input(_event):
	pass
	#if event.is_action_released("ui_accept"):
		#shake()


func slide(screen_percent: float):
	var tween = create_tween()
	var destination = Vector2((1280*screen_percent)-(size.x/2),400)
	tween.tween_property(self, "position", destination, 0.5).set_ease(Tween.EASE_IN_OUT)\
	.finished.connect(func(): anim_finished.emit())


func shake():
	const TWEEN_DURATION = 0.05
	const max_shake = 10
	var start_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(start_pos.x - max_shake, position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", Vector2(start_pos.x + max_shake, position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", Vector2(start_pos.x - (max_shake/2.0), position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	#tween.tween_property(self, "position", Vector2(start_pos.x + (max_shake/2), position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", start_pos, TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)\
	.finished.connect(func(): anim_finished.emit())


func dim():
	modulate = Color(0.5,0.5,0.5,1.0)


func toggle_fade():
	var toggle_dialog_tween = create_tween()
	
	var tween_dur = 0.3
	var fade_dir: Color = Color(1,1,1,1) #Default fade-in
	if visible:
		fade_dir = Color(1,1,1,0)
	else:
		visible = true
		modulate = Color(1,1,1,0)
	
	toggle_dialog_tween.tween_property(self, "modulate", fade_dir, tween_dur)
	toggle_dialog_tween.tween_callback(func(): if modulate == Color(1,1,1,0): visible = false)\
	.finished.connect(func(): anim_finished.emit())


func active():
	pass

