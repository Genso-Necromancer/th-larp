extends Node

##
class_name CameraController

##fires off every time a manipulation task is completed
signal camera_control_complete

signal camera_fade_complete

var camera : Camera2D
var origCam : Camera2D
var tween : Tween
var originPoint := Vector2.ZERO
var prevCamera : Camera2D



#func _init(newCamera : Camera2D):
	#camera = newCamera

##When ready: Checks for the currently active camera, sets it as the "original camera" and the target camera
func _ready():
	var active : Camera2D = get_viewport().get_camera_2d()
	if active:
		origCam = active
		camera = active


		
#region Camera Movement Functions

##moves camera offset based on map co-ordinates
func move_camera_map(hex:Vector2i, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	if !_check_valid(hex): return
	_tween_camera(hex, "offset", speed, setTrans, setEase)
	
	
##same as move_camera_map, but uses UnitID for coordinates
func move_camera_unit(unitID:String, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	var hex : Vector2i
	var map : GameMap = Global.flags.CurrentMap
	var units = map.get_active_units()
	
	for cell in units:
		if units[cell].unitId == unitID: hex = cell
		
	if !_check_valid(hex): return
	
	_tween_camera(hex, "offset", speed, setTrans, setEase)


##same as move_camera_map, but retrieves location from sceneTile with id matching given int value.
func move_camera_scenetile(sceneTile:int, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	var hex : Vector2i
	var map : GameMap = Global.flags.CurrentMap
	var units = map.get_active_units()
	
	for cell in units:
		if units[cell].unitId == unitID: hex = cell
		
	if !_check_valid(hex): return
	
	_tween_camera(hex, "offset", speed, setTrans, setEase)

#region camer effects
##Shake it baby
func shake_camera(duration:int = 4.0):
	#camera.shake_camera(duration)
	#emit_signal("camera_control_complete")
	
	var value := Vector2(0,0)
	var rng = Global.rng
	var roll : float
	var i : int = rng.randi_range(duration-1,duration+1)
	if tween: _kill_tween()
	tween = create_tween()
	
	while i > 0:
		roll = rng.randf_range(-150,150)
		value = Vector2(0,rng.randf_range(-100,100))
		tween.tween_property(camera, "offset", value, 0.1)
		tween.tween_property(camera, "offset", Vector2(0,0), 0.1)
		i -= 1
	tween.tween_callback(_signal_complete)



##Fade out camera
func fade_out(speedScale:=1.5):
	SignalTower.emit_signal("fader_fade_out", speedScale)
	await SignalTower.fade_complete
	emit_signal("camera_fade_complete")


##Guess lol
func fade_in(speedScale:=1.5):
	SignalTower.emit_signal("fader_fade_in", speedScale)
	await  SignalTower.fade_complete
	emit_signal("camera_fade_complete")


#endregion

##resets the target camera's offset, Pass true to tween the return.
func reset_map_camera(isTweened := false) -> void:
	if isTweened:
		if tween: 
			_kill_tween() 
		tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(0,0), 1)
		tween.tween_callback(_signal_complete)
		
	else: 
		camera.offset = Vector2(0,0)
		_signal_complete()


func _tween_camera(hex:Vector2i, property: String, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase :Tween.EaseType = Tween.EaseType.EASE_OUT_IN):
		if tween: 
			_kill_tween() 
		tween = create_tween()
		var currMap = Global.flags.CurrentMap
		var newPosition
		#var adjSpd : float = speed/path.size()
		
		#newPosition = currMap.map_to_local(hex)
		#var testLocal = camera.global_position
		#var local = currMap.to_local(camera.global_position)
		newPosition = currMap.map_to_local(hex) - camera.global_position
		
		tween.set_trans(setTrans)
		tween.set_ease(setEase)
		tween.tween_property(camera, property, newPosition, speed)
		tween.tween_callback(_signal_complete)
		#tween.tween_method(_move_cursor.bind(path), 0, (path.size() - 1), 2).set_trans(Tween.TRANS_LINEAR)

#endregion

#region utility funcs
##assigns the target camera, by default it grabs the currently active camera
func set_camera(newCamera : Camera2D = get_viewport().get_camera_2d()):
	camera = newCamera


##Skips the tween
func skip_tween():
	if !tween: return
	tween.pause()
	tween.custom_step(10000)
	_signal_complete()


##Kills the tween
func _kill_tween() -> void:
	if !tween: return
	tween.kill()


func _signal_complete():
	_kill_tween()
	emit_signal("camera_control_complete")


func _check_valid(point:Vector2i) -> bool:
	var mapSize = Global.flags.CurrentMap.get_used_rect().size
	if point.x < 0 or point.x >= (mapSize.x) or point.y < 0 or point.y >= (mapSize.y):
		print("Cursor: path_camer: point in cameraPath out of bounds")
		return false
	else: return true

func activate_camera():
	camera = load("res://scenes/map_camera.tscn").instantiate()
	add_child(camera)
	prevCamera = get_viewport().get_camera_2d()
	camera.global_position = prevCamera.get_screen_center_position()
	camera.make_current()


func revert_camera():
	_kill_camera()
	camera = prevCamera
	camera.make_current()


func _kill_camera():
	var oldCam = camera
	oldCam.queue_free()

#endregion
