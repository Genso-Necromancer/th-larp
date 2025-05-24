extends Node
class_name AudioHub


@export var audio_players:Dictionary[String,AudioStreamPlayer]={}

func _ready():
	SignalTower.audio_called.connect(self._on_audio_called)
	


func _on_audio_called(type:String):
	audio_players[type].play(0.0)
