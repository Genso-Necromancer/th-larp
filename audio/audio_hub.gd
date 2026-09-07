extends Node
class_name AudioHub


@export var audio_players:Dictionary[String,AudioStreamPlayer]={}

func _ready():
	SignalTower.audio_called.connect(self._on_audio_called)
	


func _on_audio_called(type:String):
	if audio_players.has(type): audio_players[type].play(0.0)
	else: printerr(self, "Missing: ", type)
