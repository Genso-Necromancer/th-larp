extends Label
class_name DigitalTime

func _ready():
	SignalTower.time_changed.connect(self._on_time_changed)


func set_clock_time(time:float):
	var timeUnits : Dictionary = Global.float_to_time(time)
	var timeString : String = Global.time_to_string(timeUnits.Hours, timeUnits.Minutes)
	set_text(timeString)


func _on_time_changed(time:float):
	set_clock_time(time)
