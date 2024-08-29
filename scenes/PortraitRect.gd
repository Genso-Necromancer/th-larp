extends TextureRect

var speaker_name = ""
var speaker_title = ""
var starting_pos = Vector2(64,400)


func _ready():
	pass


func _process(delta):
	pass


func slide(screen_percent: float):
	var tween = create_tween()
	var destination = Vector2((1280*screen_percent)-(size.x/2),400)
	tween.tween_property(self, "position", destination, 0.5).set_ease(Tween.EASE_IN_OUT)#.set_trans(Tween.TRANS_BOUNCE)

