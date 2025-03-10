@tool
extends Node

var focusUnit : Unit:
	set(value):
		focusUnit = value
		SignalTower.emit_signal("focus_unit_changed", value)
	get:
		return focusUnit
var aiTarget : Unit
var activeUnit : Unit
var activeSkill : StringName
var timeOfDay := Enums.TIME.DAY
var gameTime := 12
var timeFactor = 1
var trueTimeFactor = 1
var rotationFactor = 15


var rng
var unitObjs : Dictionary
var flags : Dictionary
var timePassed := 0
var language

var slamage := 5
var spdGap := 4
var critRange := [10, 20] 
var knifeCrit := [15, 25]
var slayerMulti := 3
var compCosts := {"Attack": 1, "WasHit":1, "Miss":1, "Dodge": 1, "NegEff": 1, "Healed":-1, "Move":0, "Crit": -1, "Kill": -1, "Break": 1}
#combat variables
func _init():
	language = Enums.LANGUAGE.AMERICAN
	gameTime = 0
	rng = RandomNumberGenerator.new()
	randomize()
	_init_flags()
	
#func set_flags(f):
	#pass
	
func _init_flags():
	flags = {
		"DebugMode": false,
		"gameOver": false,
		"victory": false,
		"activeUnit": false,
		"focusUnit": false,
		"gameTime": 0,
		"timeFactor": 1,
		"trueTimeFactor": 1,
		"rotationFactor": 15,
		"CurrentMap": 0
	}

func set_rich_text_params(label):
	label.set_use_bbcode(true)
	label.set_scroll_active(false)
	label.set_fit_content(true)
	label.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	label.set_autowrap_mode(TextServer.AUTOWRAP_OFF)
