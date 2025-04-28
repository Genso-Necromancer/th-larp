@tool
extends Node

var focusUnit : Unit:
	set(value):
		focusUnit = value
		SignalTower.emit_signal("focus_unit_changed", value)
	get:
		return focusUnit
var focusDanmaku : Danmaku:
	set(value):
		focusDanmaku = value
		#SignalTower.emit_signal("focus_unit_changed", value)
	get:
		return focusDanmaku
var aiTarget : Unit
var activeUnit : Unit
var activeSkill : Skill
var timeOfDay := Enums.TIME.DAY
var gameTime :float = 12.00:
	set(value):
		gameTime = value
		if gameTime >= 6.0 and gameTime <= 18.0:
			timeOfDay = Enums.TIME.DAY
		else:
			timeOfDay = Enums.TIME.NIGHT
		SignalTower.emit_signal("time_changed", gameTime)
var timeFactor : float = 1.0
const trueTimeFactor : float = 1.0
var hour : float = 1.0
var minute : float = 0.01666666666666666666666666666667


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
	rng = RandomNumberGenerator.new()
	randomize()
	_init_flags()
	
#func set_flags(f):
	#pass
	
func _init_flags():
	flags = {
		"DebugMode": true,
		"gameOver": false,
		"victory": false,
		"ObjectiveComplete": false,
		"activeUnit": false,
		"focusUnit": false, #Does this get used?
		"gameTime": 0,
		"timeFactor": 1,
		"trueTimeFactor": 1,
		"rotationFactor": 15,
		"CurrentMap": 0,
		"NextMap": null,
		"traded": false,
		"itemUsed" : false,
		"ChaptersCompleted": []
	}

func set_rich_text_params(label):
	label.set_use_bbcode(true)
	label.set_scroll_active(false)
	label.set_fit_content(true)
	label.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	label.set_autowrap_mode(TextServer.AUTOWRAP_OFF)


#region Time bullshitery
##Passively progresses time, factoring any timeFactor
func progress_time():
	var timeProgress = hour * timeFactor
	if gameTime + timeProgress > 23:
		gameTime = 0.0 + timeProgress
	else:
		gameTime += timeProgress


func reset_time_factor():
	timeFactor = trueTimeFactor


##multiplies timeFactor by value given, clamps value between 0.25 and 2
func apply_time_factor(effectValue:float):
	var newFactor :float = timeFactor * effectValue
	timeFactor = clampf(newFactor, 0.25, 2)

##converts number of hours and minutes into a float value usable for Global.gameTime to track time
func time_to_float(hours:int,minutes:int) -> float:
	var h :float= hours * hour
	var m :float= minutes * minute
	return (h+m)


##converts a float value usable for Global.gameTime to time values, and returns a dictionary[string, int] {Hours:number of, Minutes:number of}
func float_to_time(game_time:float) -> Dictionary[String, int]:
	var splitTime:Dictionary[String, int]= {"Hours": 0, "Minutes": 0}
	splitTime.Hours = floori(game_time)
	splitTime.Minutes = floori((game_time - floori(game_time)) / minute)
	return splitTime


##converts time units into a digital clock style string
func time_to_string(hours:int, minutes:int) -> String:
	var timeString := "%s:%s"
	var timeH :String = ""
	var timeM :String = ""
	if hours < 10:
		timeH = "0%d" % [hours]
	elif hours > 12:
		timeH = str(hours - 12)
	else: timeH = str(hours)
	if minutes < 10:
		timeM = "0%d" % [minutes]
	else: timeM = str(minutes)
	timeString = timeString % [timeH, timeM]
	return timeString
#endregion

#region flag shit
func reset_map_flags():
	Global.flags.gameOver = false
	Global.flags.victory = false
	Global.flags.traded = false
	Global.flags.itemUsed = false
	Global.flags.gameOver = false
	Global.flags.victory = false
	Global.flags.ObjectiveComplete = false
#endregion
