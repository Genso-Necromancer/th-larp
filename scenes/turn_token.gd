extends Node2D
class_name TurnToken
signal animation_finished(animation:StringName, token:TurnToken)
signal tween_finished(token:TurnToken)
@onready var anim_player :AnimationPlayer= $TokenSprite/AnimationPlayer
@onready var token :Sprite2D = $TokenSprite
var is_exiting := false
var is_entering := true
var frame := 0
var set_scale := Vector2(0,0)

func _ready():
	anim_player.animation_finished.connect(self._on_animation_finished)
	token.frame = frame
	token.scale = set_scale
	anim_player.play("enter_list")
	

func set_animation(anim:StringName) -> void:
	anim_player.play(anim)


func _on_animation_finished(anim)->void:
	animation_finished.emit(anim, self)


func rise_up()->void:
	if is_entering or is_exiting: return
	var tween :Tween = get_tree().create_tween()
	var new_pos := global_position
	new_pos.y =  global_position.y - (75)
	tween.finished.connect(self._on_tween_finished)
	tween.tween_property(self,"global_position",new_pos,0.5)
	

func _on_tween_finished()->void:
	tween_finished.emit(self)
