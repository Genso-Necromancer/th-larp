extends TextureRect
class_name ClockDial

##Dial is rotating too far per hour
##fuck it. Need to just make a look up table of time of day and rotation degrees
var currentTime : float = 0.0
var rotFactor := 15
var rot_deg : float = 0.0:
	set(value):
		rot_deg = value
		rotation_degrees = value
		if rot_deg == 360.0 or rot_deg == -360.0:
			rot_deg = 0
			rotation_degrees = 0


func _ready():
	SignalTower.time_changed.connect(self._on_time_changed)
	SignalTower.time_reset.connect(self._reset_sun)

func _reset_sun()->void:
	rotation_degrees = 0
	print("Sun Rotated:[", rotation_degrees,"]")

func set_sun(time:float):
	var rot =  time * rotFactor
	rotation_degrees = rot
	currentTime = time
	print("(set_sun)Time changed:[",time,"]")
	print("(set_sun)Sun Rotated:[", rotation_degrees,"]")

func _on_time_changed(time:float):
	var difference := _find_difference(time)
	var degrees := _find_rotation(difference)
	tween_dial_rotation(degrees)
	currentTime = time
	print("(tween)Sun Rotated:[", rotation_degrees,"]")
	print("(time_changed)Time changed:[",time,"]")

func tween_dial_rotation(degrees:float):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self,"rot_deg", degrees, 2)
	


func _find_difference(time: float) -> float:
	var d : float
	var mod: float = 0.0
	if currentTime > time: mod = 24.0
	d = (time + mod) - currentTime
	print("find_difference: ", d)
	return d


func _find_rotation(time_difference:float) -> float:
	var r : float
	r = rotation_degrees - (time_difference * rotFactor)

	print("find_rotation: ", r)
	return r
