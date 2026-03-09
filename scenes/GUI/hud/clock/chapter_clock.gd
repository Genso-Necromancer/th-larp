extends Control
class_name ChapterClock

@onready var clock_player:AnimationPlayer = $ClockPlayer
@onready var m_bone:Bone2D = $Skeleton2D/center/mHand
@onready var h_bone:Bone2D = $Skeleton2D/center/hHand
@onready var sun_dial:Bone2D = $Skeleton2D/center/SunDial
@onready var time_box:DigitalDisplay = $Assets/Digital/TimeBox
var saved_time:float = 0.0

#debug values
var debug_start:Dictionary[String,int] = {"Hours":0,"Minutes":0,"Seconds":0}
var debug_advance:Dictionary[String,int] = {"Hours":0,"Minutes":40,"Seconds":0}

func _ready():
	visible = false
	SignalTower.time_changed.connect(self.advance_clock)
	hide_clock()
	#grab_focus()
	


#func _unhandled_key_input(event):
	##print("input detected")
	#if event is not InputEventKey or event.is_echo(): return
	#
	#if event.is_action_pressed("ui_confirm"):
		#Global.game_time = debug_start
		#set_time(Global.game_time)
	#elif event.is_action_pressed("ui_return"): 
		#Global.progress_time(debug_advance.Hours,debug_advance.Minutes)
		#advance_clock(Global.game_time)
	#accept_event()


func hide_clock(): 
	clock_player.play("exit")


func show_clock():
	visible = true
	clock_player.play("enter")


func advance_clock(game_time:Dictionary[String,int]):
	time_box.set_time(game_time)
	_progress_clock_hands(game_time)
	


func _progress_clock_hands(split_time:Dictionary[String,int]):
	#var time_dif:= Global.find_time_difference(saved_time,game_time)
	var minutes:float = float(split_time.Minutes)
	var hours:float = float(split_time.Hours)
	var seconds:float = (
		(minutes * 60)
		+ ((hours * 60)*60)
	)
	var minuteRot:float
	var dayRot:float
	var hourRot:float
	
	
	minuteRot= fmod(seconds/60.0,60.0) * TAU / 60.0
	dayRot= (fmod(seconds / 3600.0, 24.0) * TAU / 24.0)
	hourRot=fmod(seconds / 3600.0, 12.0) * TAU / 12.0
	var tween = get_tree().create_tween().set_parallel(true)
	
	print(minuteRot)
	print(hourRot)
	print(dayRot)
	#if value >= 30 do tween + subtween at double speed?
	# HOW THE FUCK DOES A SUBTWEEN EVEN WORK?
	#if minutes >= 30:
		#
		#tween.tween_method(_rotate_bone.bind(m_bone,minuteRot/2),0.0,1.0,0.5)
		#tween.tween_method(_rotate_bone.bind(m_bone,minuteRot),0.0,1.0,0.5)
	#else: 
	tween.tween_method(_rotate_bone.bind(m_bone,minuteRot),0.0,1.0,1.0)
	
	#if hours>=6:
		#var subtween = get_tree().create_tween()
		#subtween.tween_method(_rotate_bone.bind(h_bone,hourRot),0.0,1.0,0.5)
		#tween.tween_method(_rotate_bone.bind(h_bone,hourRot/2),0.0,1.0,0.5)
		#tween.tween_subtween(subtween)
	#else:
	tween.tween_method(_rotate_bone.bind(h_bone,hourRot),0.0,1.0,1.0)
	
	#if hours>=12:
		#var subtween = get_tree().create_tween()
		#subtween.tween_method(_rotate_bone.bind(sun_dial,dayRot),0.0,1.0,0.5)
		#tween.tween_method(_rotate_bone.bind(sun_dial,dayRot/2),0.0,1.0,0.5)
		#tween.tween_subtween(subtween)
	#else: 
	tween.tween_method(_rotate_bone.bind(sun_dial,dayRot),0.0,1.0,1.0)
	#tween.tween_property(m_bone,"rotation",minuteRot,1.0)
	#tween.tween_property(h_bone,"rotation",hourRot,1.0)
	#tween.tween_property(sun_dial,"rotation",dayRot,1.0)


func _rotate_bone(weight:float,bone:Bone2D,rot:float):
	var start := bone.rotation
	bone.rotation = lerp_angle(start,rot,weight)


func set_time(game_time:Dictionary[String,int]):
	time_box.set_time(game_time)
	var minutes:float = float(game_time.Minutes)
	var hours:float = float(game_time.Hours)
	var minuteRot:= fmod(minutes, 60) * TAU / 60
	var dayRot:= fmod(hours, 24) * TAU / 24
	var hourRot:float
	if hours > 12.0: hours = hours - 12.0
	hourRot = fmod(hours, 12) * TAU / 12
	m_bone.rotation = minuteRot
	h_bone.rotation = hourRot
	sun_dial.rotation = dayRot
	





#func _test_func(game_time:float):
	#var splitTime:Dictionary[String,int]=Global.float_to_time(game_time)
	#var minutes:float = float(splitTime.Minutes)
	#var hours:float = float(splitTime.Hours)
	#
	#var m_start:float = 0.0
	#var m_end:= minutes * 60
	#var h_start:float = 0.0
	#var h_end:= (hours * 60)*60
	#
	#while m_start <= m_end:
		#_rotate_m_bone()
		#m_start += 1.0
	#
	#while h_start <= h_end:
		#_rotate_h_bone()
		#h_start += 1.0
	#
	#
#
#func _rotate_m_bone():
	#var increment:= (1/60)*TAU/60
	#m_bone.rotation += increment
#
#
#func _rotate_h_bone():
	#var increment:= (1/60)*TAU/60
	#h_bone.rotation += increment
	#
	


#func sync_to_gametime():
	#var dial : ClockDial = $ClockMargin/PivotPoint/ClockDial
	#var digital : DigitalTime = $ClockMargin/DigitalMargin/DigitalTime
	#var time = Global.game_time
	#dial.set_sun(Global.game_time)
	#digital.set_clock_time(Global.game_time)
