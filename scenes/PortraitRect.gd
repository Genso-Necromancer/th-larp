extends Control

@onready var tex_rext = $SpeakerPortrait
var speaker_name = ""
var speaker_title = ""
var texture
var starting_pos = Vector2(28,324) #Vector2(64,400)


signal anim_finished
signal effect_finished


func _ready():
	position = starting_pos
	tex_rext.texture = texture


func _unhandled_input(_event):
	pass
	#if _event.is_action_released("ui_accept"):
		#double_hop()


func slide(screen_percent: float):
	var tween = create_tween()
	var destination = Vector2((1280*screen_percent)-(size.x/2),starting_pos.y)
	tween.tween_property(self, "position", destination, 0.5).set_ease(Tween.EASE_IN_OUT)\
	.finished.connect(func(): anim_finished.emit())


func shake():
	const TWEEN_DURATION = 0.05
	const max_shake = 24
	var start_pos = tex_rext.position
	var tween = create_tween()
	tween.tween_property(tex_rext, "position", Vector2(start_pos.x - max_shake, tex_rext.position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(start_pos.x + max_shake, tex_rext.position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(start_pos.x - (max_shake/2.0), tex_rext.position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(start_pos.x + (max_shake/2), tex_rext.position.y), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", start_pos, TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)\
	.finished.connect(func(): anim_finished.emit())


func hop():
	const TWEEN_DURATION = 0.1
	const hop_height = 24
	var start_pos = tex_rext.position
	var tween = create_tween()
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y - hop_height), TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", start_pos, TWEEN_DURATION*3.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)\
	.finished.connect(func(): anim_finished.emit())


func double_hop():
	const TWEEN_DURATION = 0.1
	const hop_height = 30
	var start_pos = tex_rext.position
	var tween = create_tween()
	#tween.tween_property(self, "position", Vector2(position.x, starting_pos.y - hop_height), TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	#tween.tween_property(self, "position", Vector2(position.x, starting_pos.y + (hop_height/2.0)), TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	#tween.tween_property(self, "position", Vector2(position.x, starting_pos.y - (hop_height/2.0)), TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	#tween.tween_property(self, "position", start_pos, TWEEN_DURATION*4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)\
	#.finished.connect(func(): anim_finished.emit())
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y - hop_height), TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y - (hop_height/4.0)), TWEEN_DURATION*2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y - hop_height), TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", start_pos, TWEEN_DURATION*4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)\
	.finished.connect(func(): anim_finished.emit())


func interact():
	const TWEEN_DURATION = 0.2
	const hop_height = 24
	var start_pos = tex_rext.position
	var tween = create_tween()
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y - hop_height/3), TWEEN_DURATION/2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y + hop_height), TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", Vector2(tex_rext.position.x, start_pos.y + hop_height), TWEEN_DURATION/2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rext, "position", start_pos, TWEEN_DURATION/1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)\
	.finished.connect(func(): anim_finished.emit())


func zoom():
	scale = Vector2(1.5, 1.5)
	position = Vector2(position.x - (size.x/4.0), position.y - (size.y/2.0))
	#tex_rext.scale = Vector2(1.5, 1.5)
	#tex_rext.position = Vector2(tex_rext.position.x, tex_rext.position.y - 128)


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

