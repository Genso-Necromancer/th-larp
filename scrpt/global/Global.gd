@tool
extends Node
const validation:= "9808110206"
#region persistant variables


var focusUnit : Unit:
	set(value):
		focusUnit = value
		SignalTower.emit_signal("focus_unit_changed", value)
	get:
		return focusUnit
var focusDanmaku : Danmaku:
	set(value):
		focusDanmaku = value
		SignalTower.emit_signal("focus_danmaku_changed", value)
	get:
		return focusDanmaku
var aiTarget : Unit
var activeUnit : Unit
var activeSkill : Skill
var time_of_day := Enums.TIME.DAY
var game_time :float = 12.00:
	set(value):
		game_time = value
		if game_time >= 6.0 and game_time <= 18.0:
			time_of_day = Enums.TIME.DAY
		else:
			time_of_day = Enums.TIME.NIGHT
		SignalTower.emit_signal("time_changed", game_time)
var time_factor : float = 1.0
const true_time_factor : float = 1.0
const hour : float = 1.0
const minute : float = 0.01666666666666666666666666666667
var play_time:= 0
## RngTool stores the RandomNumberGenerator here to keep a reference loaded.
## use RngTool to actually use the RandomNumberGenerator.
var rng:RandomNumberGenerator
#endregion
var map_ref:GameMap
var flags : Dictionary

var timePassed := 0
var language

const slamage := 5
const spdGap := 4
const critRange := [10, 20]
const knifeCrit := [15, 25]
const slayerMulti := 3
const compCosts := {"Attack": 1, "WasHit":1, "Miss":1, "Dodge": 1, "NegEff": 1, "Healed":-1, "Move":0, "Crit": -1, "Kill": -1, "Break": 1}


func _init():
	language = Enums.LANGUAGE.AMERICAN
	_init_flags()

#region saving/loading
func save()->Dictionary:
	var RNG := RngTool.new()
	var pers : Dictionary = {
		"DataType": "Global",
		"game_time":game_time,
		"time_factor":time_factor,
		"RngState":RNG.save_state(),
		"flags":flags,
		"time_of_day":time_of_day,
		#"TimePassed":timePassed, #Move to MapManager?
		#"Language":language, #Move to Config eventually
		#"CurrentMap":currentMapPath, #Move to MapManager
		#"ChapterNumber":chapterNumber, #Move to MapManager
		#"NextMap":nextMap, #Move to MapManager
		#"ChaptersComplete":chapters_complete #Move to Player Data
	}
	#var pers : Dictionary = {
		#"DataType": "Globals",
		#"time_of_day":time_of_day,
		#"GameTime":game_time,
		#"time_factor":time_factor,
		#"RNG":rng,
		#"UnitObjs":unitObjs,
		#"Flags":flags,
		#"TimePassed":timePassed,
		#"Language":language,
		#"CurrentMap":currentMapPath,
		#"ChapterNumber":chapterNumber,
		#"NextMap":nextMap,
		#"ChaptersComplete":chapters_complete
	#}
	return pers


func load_persistant(Data:Dictionary):
	var RNG := RngTool.new()
	if Data.DataType != "Global": 
		print("ERROR: ATTEMPTED TO LOAD NON-GLOBAL DATA IN GLOBAL")
		return
	#time_of_day = Data.time_of_day
	game_time = Data.game_time
	time_factor = Data.time_factor
	RNG.load_state(Data.RngState)
	#unitObjs = Data.UnitObjs
	flags = Data.flags
	#timePassed = Data.TimePassed
	#language = Data.Language
	#currentMap = Data.CurrentMapPath
	#chapterNumber = Data.ChapterNumber
	#nextMap = Data.NextMap
	#chapters_complete = Data.ChaptersComplete


func reset_values():
	time_of_day = Enums.TIME.DAY
	game_time = 12.00
	time_factor = 1.0
	_init_flags()
	timePassed = 0
	#language = Data.Language
#endregion


func _init_flags():
	flags = {
		"DebugMode": true,
		"gameOver": false, #Move to MapManager?
		"victory": false, #Move to MapManager?
		"ObjectiveComplete": false, #Move to Map?
		"traded": false, #Move to Unit?
		"itemUsed" : false, #Move to Unit?
	}


func set_rich_text_params(label):
	label.set_use_bbcode(true)
	label.set_scroll_active(false)
	label.set_fit_content(true)
	label.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	label.set_autowrap_mode(TextServer.AUTOWRAP_OFF)




#region Time bullshitery
##Passively progresses time, factoring any time_factor
func progress_time():
	var timeProgress = hour * time_factor
	if game_time + timeProgress > 23:
		game_time = 0.0 + timeProgress
	else:
		game_time += timeProgress


func reset_time_factor():
	time_factor = true_time_factor


##multiplies time_factor by value given, clamps value between 0.25 and 2
func apply_time_factor(effectValue:float):
	var newFactor :float = time_factor * effectValue
	time_factor = clampf(newFactor, 0.25, 2)

##converts number of hours and minutes into a float value usable for Global.game_time to track time
func time_to_float(hours:int,minutes:int) -> float:
	var h :float= hours * hour
	var m :float= minutes * minute
	return (h+m)


##converts a float value usable for Global.game_time to time values, and returns a dictionary[string, int] {Hours:number of, Minutes:number of}
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
#endregion
