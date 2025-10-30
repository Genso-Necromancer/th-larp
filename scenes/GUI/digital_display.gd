extends HBoxContainer
class_name DigitalDisplay

@onready var hour_10s : Label = $Hour10s
@onready var hour_1s : Label = $Hour1s
@onready var minute_10s : Label = $Minute10s
@onready var minute_1s : Label = $Minute1s


func set_time(game_time:Dictionary[String, int]):
	var hours:= game_time.Hours
	var minutes:= game_time.Minutes
	if hours > 12: hours = hours - 12
	if hours == 0: hours = 12
	var h10s:int = int(floorf(hours / 10))
	var m10s:int = int(floorf(minutes / 10))
	var h1s:int = int(floorf(hours % 10))
	var m1s:int = int(floorf(minutes % 10))
	#print("h10s:%d h1s:%d m10s:%d m1s:%d" % [h10s,h1s,m10s,m1s])
	hour_10s.set_text(str(h10s))
	hour_1s.set_text(str(h1s))
	minute_10s.set_text(str(m10s))
	minute_1s.set_text(str(m1s))
