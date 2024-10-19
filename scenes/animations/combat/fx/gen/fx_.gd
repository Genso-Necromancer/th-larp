extends Node2D
class_name FxPlayer

func play_action():
	$AnimationPlayer.play("Action")

func connect_signal(connector):
	var player = $AnimationPlayer
	player.animation_finished.connect(connector._on_fx_animation_finished)
