extends Control
class_name PortraitRect
@onready var tex_rect = $SpeakerPortrait
@onready var question_mark = $QuestionMarkParticle
var speaker_name = ""
var speaker_title = ""
var texture
var starting_pos = Vector2(324,-100)


signal anim_finished
signal effect_finished


func _ready():
	starting_pos = position
	tex_rect.texture = texture
	var mat = question_mark.material as ShaderMaterial
	mat.set_shader_parameter("rect_size", question_mark.size)


func _unhandled_input(_event):
	pass
	#if _event.is_action_released("ui_accept"):
		#show_question()


func teleport(screen_percent: float):
	position = Vector2((get_viewport().get_visible_rect().size.x*screen_percent)-(size.x/2),starting_pos.y)


func slide(screen_percent: float, speed: float = 1.0):
	const TWEEN_DURATION = 0.5
	var tween = create_tween()
	var destination = Vector2((get_viewport().get_visible_rect().size.x*screen_percent)-(size.x/2),starting_pos.y)
	tween.tween_property(self, "position", destination, TWEEN_DURATION*speed)\
	.set_ease(Tween.EASE_IN_OUT)\
	.finished.connect(func(): anim_finished.emit())


func shake(speed: float = 1.0):
	const TWEEN_DURATION = 0.05
	var max_shake : int = tex_rect.size.x * 0.09 # 24
	var start_pos = tex_rect.position
	var tween = create_tween()
	tween.tween_property(tex_rect, "position", Vector2(start_pos.x - max_shake, tex_rect.position.y), TWEEN_DURATION*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(start_pos.x + max_shake, tex_rect.position.y), TWEEN_DURATION*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(start_pos.x - (max_shake/2.0), tex_rect.position.y), TWEEN_DURATION*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(start_pos.x + (max_shake/2), tex_rect.position.y), TWEEN_DURATION*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", start_pos, TWEEN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)\
	.finished.connect(func(): anim_finished.emit())


func hop(speed: float = 1.0):
	const TWEEN_DURATION = 0.1
	var hop_height : int = tex_rect.size.x * 0.09 # 24
	var start_pos = tex_rect.position
	var tween = create_tween()
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y - hop_height), TWEEN_DURATION*speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", start_pos, (TWEEN_DURATION*3.0)*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)\
	.finished.connect(func(): anim_finished.emit())


func double_hop(speed: float = 1.0):
	const TWEEN_DURATION = 0.1
	var hop_height : int = tex_rect.size.x * 0.09 # 30
	var start_pos = tex_rect.position
	var tween = create_tween()
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y - hop_height), TWEEN_DURATION*speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y - (hop_height/4.0)), (TWEEN_DURATION*2.0)*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y - hop_height), TWEEN_DURATION*speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", start_pos, (TWEEN_DURATION*4.0)*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)\
	.finished.connect(func(): anim_finished.emit())


func interact(speed: float = 1.0):
	const TWEEN_DURATION = 0.2
	var hop_height : int = tex_rect.size.x * 0.09 # 24
	var start_pos = tex_rect.position
	var tween = create_tween()
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y - hop_height/3), (TWEEN_DURATION/2.0)*speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y + hop_height), TWEEN_DURATION*speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", Vector2(tex_rect.position.x, start_pos.y + hop_height), (TWEEN_DURATION/2.0)*speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "position", start_pos, (TWEEN_DURATION/1.5)*speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)\
	.finished.connect(func(): anim_finished.emit())


func zoom():
	scale = Vector2(1.5, 1.5)
	position = Vector2(position.x - (size.x/4.0), position.y - (size.y/2.0))


func dim():
	modulate = Color(0.5,0.5,0.5,1.0)


func toggle_fade(speed: float = 1.0):
	var toggle_dialog_tween = create_tween()
	
	var tween_dur = 0.3 * speed
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


func show_question(speed: float = 1.0):
	question_mark.visible = true
	var _question_start_pos = question_mark.position
	question_mark.modulate = Color(1,1,1,0) # fully transparent
	question_mark.rotation = 0
	
	var tw = create_tween()
	
	# 2b) Fade-in & move down 10px (run *after* the wobble)
	tw.tween_property(question_mark, "modulate:a", 1.0, 0.30*speed)
	tw.tween_property(question_mark, "position:y", _question_start_pos.y + 10, 0.30*speed)
	
	# 2c) Move back up to original Y so next play starts consistent
	tw.tween_property(question_mark, "position:y", _question_start_pos.y, 0.10*speed)
	tw.tween_property(question_mark, "modulate:a", 0.0, 0.30*speed)
	tw.finished.connect(func(): anim_finished.emit())
