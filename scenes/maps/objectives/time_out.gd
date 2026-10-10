extends Objective
class_name TimeOut


@export var time_limit : float = 0.0 ##in game "hours" until triggered complete


func _ready():
	super()
	SignalTower.time_changed.connect(self._on_time_changed)


func _on_time_changed(time:float):
	if time_limit >= time: complete = true


func get_display_text(map = null) -> String:
	var custom_text := super.get_display_text(map)
	if not custom_text.is_empty():
		return custom_text
	if condition_type == CONDITION_TYPES.WINNING:
		return "Survive until %.1f hours pass" % [time_limit]
	return "Win before %.1f hours pass" % [time_limit]
