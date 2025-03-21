extends Control

class_name fader



@onready var anim : AnimationPlayer = $FadePlayer
#static func test_(duration:= 1.5):
	#fade_out()

func _ready():
	visible = true
	SignalTower.fader_fade_in.connect(self.fade_in)
	SignalTower.fader_fade_out.connect(self.fade_out)
	fade_in(5.0)

func fade_in(speedScale: float = 0.5) -> void:
	
	anim.speed_scale = speedScale
	anim.play("fade_in")
	await anim.animation_finished
	SignalTower.emit_signal("fade_in_complete")
	
	
func fade_out(speedScale: float = 0.5) -> void:
	anim.speed_scale = speedScale
	anim.play("fade_out")
	await anim.animation_finished
	SignalTower.emit_signal("fade_out_complete")
