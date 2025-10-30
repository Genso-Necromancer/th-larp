@tool
extends Node
const validation:= "9808110206"
#region persistant variables


enum META_STATES {NONE,GAME_OVER,VICTORY}
var meta_state:META_STATES = META_STATES.NONE
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

#time
const true_time_factor : float = 1.0
#const hour : float = 1.0
#const minute : float = 0.01
var time_of_day := Enums.TIME.DAY
#var game_time :float = 00.00:
	#set(value):
		#game_time = value
		#value = _clamp_time(value)
		#if value >= 6.0 and value <= 18.0:
			#time_of_day = Enums.TIME.DAY
		#else:
			#time_of_day = Enums.TIME.NIGHT
		#SignalTower.emit_signal("time_changed", value)
##Never change this value directly, use Global.progess_time() or Global.set_time()
var game_time :Dictionary[String,int]={"Minutes":0,"Hours":0,"Seconds":0}:
	set(value):
		#if value.Minute >= 60: 
			#value.Minute = value.Minute-60
			#value.Hour + 1
		#if value.Hour >=24: value.Hour = value.Hour - 24
		if value.Hour >= 6 and value.Hour <= 18:
			time_of_day = Enums.TIME.DAY
		else:
			time_of_day = Enums.TIME.NIGHT
		game_time = value
		print("time_changed %s" % [game_time])
		SignalTower.emit_signal("time_changed", game_time)
var time_factor : float = 1.0
var time_passed := 0.0

var play_time:= 0
## RngTool stores the RandomNumberGenerator here to keep a reference loaded.
## use RngTool to actually use the RandomNumberGenerator.
var rng:RandomNumberGenerator
#endregion
var map_ref:GameMap
var flags : Dictionary


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
		"meta_state":meta_state,
		"time_of_day":time_of_day,
		#"time_passed":time_passed, #Move to MapManager?
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
		#"time_passed":time_passed,
		#"Language":language,
		#"CurrentMap":currentMapPath,
		#"ChapterNumber":chapterNumber,
		#"NextMap":nextMap,
		#"ChaptersComplete":chapters_complete
	#}
	return pers


func load_persistant(Data:Dictionary):
	var RNG := RngTool.new()
	var mStateKey :String = META_STATES.find_key(Data.meta_state)
	if Data.DataType != "Global": 
		print("ERROR: ATTEMPTED TO LOAD NON-GLOBAL DATA IN GLOBAL")
		return
	#time_of_day = Data.time_of_day
	game_time = Data.game_time
	time_factor = Data.time_factor
	RNG.load_state(Data.RngState)
	#unitObjs = Data.UnitObjs
	flags = Data.flags
	meta_state = META_STATES[mStateKey]
	#time_passed = Data.time_passed
	#language = Data.Language
	#currentMap = Data.CurrentMapPath
	#chapterNumber = Data.ChapterNumber
	#nextMap = Data.NextMap
	#chapters_complete = Data.ChaptersComplete


func reset_values():
	game_time.Hours = 12
	game_time.Minutes = 0
	#game_time = 0.0
	time_factor = 1.0
	_init_flags()
	time_passed = 0
	#language = Data.Language
#endregion


func _init_flags():
	flags = {
		"DebugMode": true,
	}
	meta_state = META_STATES.NONE


func set_rich_text_params(label):
	label.set_use_bbcode(true)
	label.set_scroll_active(false)
	label.set_fit_content(true)
	label.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	label.set_autowrap_mode(TextServer.AUTOWRAP_OFF)




#region Time bullshitery
##Passively progresses time, factoring any time_factor
func progress_time(add_hours:int=0,add_minutes:int=0):
	var seconds:float = (
		float(add_minutes * 60)
		+ (float(add_hours * 60)*60)
	)
	seconds = seconds * time_factor
	var minutes := fmod(seconds/60.0,60.0)
	var hours := floorf(fmod(seconds / 3600.0, 120.0))
	var fract := minutes - floorf(minutes)
	seconds =  60 * fract
	
	if seconds: print("seconds:%d, game_time:%d, combo:%d" % [minutes,game_time.Minutes,(game_time.Minutes + minutes)])
	while (game_time.Seconds + seconds) >=60:
		seconds = seconds - 60
		minutes += 1
		print("Loop: seconds:%d, game_time:%d, combo:%d" % [minutes,game_time.Minutes,(game_time.Minutes + minutes)])
	
	if add_minutes: print("add_minutes:%d, game_time:%d, combo:%d" % [minutes,game_time.Minutes,(game_time.Minutes + minutes)])
	while (game_time.Minutes + minutes) >=60:
		minutes = minutes - 60
		hours += 1
		print("Loop: add_minutes:%d, game_time:%d, combo:%d" % [minutes,game_time.Minutes,(game_time.Minutes + minutes)])
	
	if add_hours: print("add_hours:%d, game_time:%d, combo:%d" % [hours,game_time.Hours,(game_time.Hours + hours)])
	while (game_time.Hours + hours) >= 24:
		hours = hours - 24
		print("Loop: add_hours:%d, game_time:%d, combo:%d" % [hours,game_time.Hours,(game_time.Hours + hours)])
	
	
	game_time.Hours += int(hours)
	game_time.Minutes += int(minutes)
	game_time.Seconds += int(seconds)
	print("Final Time: H:%d, M:%d, S:%d" % [game_time.Hours, game_time.Minutes, game_time.Seconds])


func set_time(hours:int=0,minutes:int=0,seconds:int=0):
	hours = clampi(hours,0,23)
	minutes = clampi(minutes,0,59)
	seconds = clampi(seconds,0,59)
	game_time.Hours = hours
	game_time.Minutes = minutes
	game_time.Seconds = seconds


func reset_time_factor():
	time_factor = true_time_factor


##multiplies time_factor by value given, clamps value between 0.25 and 2
func apply_time_factor(effectValue:float):
	var newFactor :float = time_factor * effectValue
	time_factor = clampf(newFactor, 0.25, 2)

##converts number of hours and minutes into a float value usable for Global.game_time to track time
#func time_to_float(hours:int,minutes:int) -> float:
	#var h :float= hours * hour
	#var m :float= minutes * minute
	#return (h+m)


##converts a float value usable for Global.game_time to time values, and returns a dictionary[string, int] {Hours:number of, Minutes:number of}
#func float_to_time(time:float) -> Dictionary[String, int]:
	#var splitTime:Dictionary[String, int]= {"Hours": 0, "Minutes": 0}
	#splitTime.Hours = floori(time)
	#splitTime.Minutes = floori((time - floori(time)) / minute)
	#return splitTime


func find_time_difference(prev_time:float,new_time: float) -> float:
	var d : float
	var mod: float = 0.0
	if prev_time > new_time: mod = 24.0
	d = (new_time + mod) - prev_time
	print("find_difference: ", d)
	return d

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
	meta_state = META_STATES.NONE
#endregion
