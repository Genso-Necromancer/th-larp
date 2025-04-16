extends Control
class_name ChapterSplash

signal splash_player_finished

@onready var animPlayer := $AnimationPlayer

func _ready():
	animPlayer.animation_finished.connect(self._on_animation_finished)
	SignalTower.prompt_accepted.connect(self._on_prompt_accepted)

func _on_prompt_accepted():
	skip_animation()


func play_splash(chNum :int, chTitle:String, timeString:String):
	var num := $TitleNode/ChPanel/ChHBox/ChNum
	var title := $TitleNode/TitlePanel/ChTitle
	var time := $TitleNode/TimePanel/ChTime
	var dayHalf : String = ""
	match Global.timeOfDay:
		Enums.TIME.DAY: dayHalf = "AM"
		Enums.TIME.NIGHT: dayHalf = "PM"
	num.set_text(str(chNum))
	title.set_text(chTitle)
	time.set_text(timeString+dayHalf)
	animPlayer.play("Splash")

func skip_animation():
	if animPlayer.is_playing():
		animPlayer.advance(3.5)
	else:
		end_splash()


func _on_animation_finished(anim):
	if anim == "Splash":
		await get_tree().create_timer(2).timeout
		animPlayer.play("FadeOut")
	elif anim == "FadeOut":
		end_splash()


func end_splash():
	emit_signal("splash_player_finished")
	queue_free()
