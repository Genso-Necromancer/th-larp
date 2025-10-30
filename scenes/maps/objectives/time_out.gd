extends Objective
class_name TimeOut


@export var time_limit : float = 0.0 ##in game "hours" until triggered complete


func _ready():
	super()
	SignalTower.time_changed.connect(self._on_time_changed)


func _on_time_changed(time:float):
	if time_limit >= time: complete = true
