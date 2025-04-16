extends TextureRect
class_name ClockDial

##Dial is rotating too far per hour
##fuck it. Need to just make a look up table of time of day and rotation degrees
var currentTime : float = 0.0
var rotFactor := 15

func _ready():
	SignalTower.time_changed.connect(self._on_time_changed)


func set_sun(time:float):
	var rot =  time * rotFactor
	rotation_degrees = rot
	currentTime = time
	print(time)


func _on_time_changed(time:float):
	var difference = _find_difference(time)
	var degrees = _find_rotation(difference)
	tween_dial_rotation(degrees)
	currentTime = time

func tween_dial_rotation(degrees:float):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self,"rotation_degrees", -degrees, 2)


func _find_difference(time: float) -> float:
	var d : float
	var mod: float = 0.0
	if currentTime > time: mod = 24.0
	d = (time + mod) - currentTime
	return d


func _find_rotation(time_difference:float) -> float:
	var r : float
	r = time_difference * rotFactor
	return r
