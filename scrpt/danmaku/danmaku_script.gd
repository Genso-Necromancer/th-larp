extends Resource
class_name DanmakuScript

@export var pattern_steps: Array[PackedScene] = []
var map : GameMap
var master : Unit

var step := 0:
	set(value):
		if value >= pattern_steps.size():
			step = 0
		else: step = value

func get_step() -> PackedScene:
	var nextStep : PackedScene
	nextStep = pattern_steps[step]
	step += 1
	return nextStep
