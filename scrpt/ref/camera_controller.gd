extends RefCounted

##
class_name CameraController

##fires off every time a manipulation task is completed
signal camera_control_complete
signal camera_fade_in_complete
signal camera_fade_out_complete

var camera : SceneCamera
var origCam : SceneCamera
var originPoint := Vector2.ZERO
var prevCamera : SceneCamera
var viewPort : Viewport


#func _init(newCamera : Camera2D):
	#camera = newCamera

##Checks for the currently active camera, sets it as the "original camera" and the target camera
func _init(view_port:Viewport):
	viewPort = view_port
	var active : Camera2D = viewPort.get_camera_2d()
	if active:
		camera = active
		camera.camera_tween_complete.connect(self._on_tween_complete)
	else:
		print("camera controller: ready: no active camera detected")

	


		
#region Camera Movement Functions
##moves camera offset based on map co-ordinates
func move_camera_map(hex:Vector2i, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	if !_check_valid(hex): return
	camera.tween_camera(hex, "offset", speed, setTrans, setEase)
	
	
##same as move_camera_map, but uses UnitID for coordinates
func move_camera_unit(unitID:String, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	var hex : Vector2i
	var map : GameMap = Global.flags.CurrentMap
	var units = map.get_active_units()
	
	for cell in units:
		if units[cell].unitId == unitID: hex = cell
		
	if !_check_valid(hex): 
		print("Camer Controller: move_camera_unit: invalid coordinates")
		return
	
	camera.tween_camera(hex, "offset", speed, setTrans, setEase)


##same as move_camera_map, but retrieves location from sceneTile with id matching given int value.
func move_camera_cameratile(cameraTileId:int, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	var map : GameMap = Global.flags.CurrentMap
	var hex : Vector2i = map.get_narrative_tile(cameraTileId)

	if !_check_valid(hex): 
		print("Camer Controller: move_camera_cameratile: invalid coordinates")
		return
	
	camera.tween_camera(hex, "offset", speed, setTrans, setEase)


#region camer effects
##Shake it baby
func shake_camera(duration:int = 4.0):
	camera.shake_camera(duration)



##Fade out camera
func fade_out(speedScale:=1.5):
	SignalTower.emit_signal("fader_fade_out", speedScale)
	await SignalTower.fade_out_complete
	emit_signal("camera_fade_out_complete")


##Guess lol
func fade_in(speedScale:=1.5):
	SignalTower.emit_signal("fader_fade_in", speedScale)
	await  SignalTower.fade_in_complete
	emit_signal("camera_fade_in_complete")


#endregion

##resets the target camera's offset, Pass true to tween the return.
func reset_camera(isTweened := false, speed:float = 1.0) -> void:
	camera.reset_camera(isTweened)

#endregion

#region utility funcs
##assigns the target camera, by default it grabs the currently active camera. Ready automatically assigns the currently active camera, this function is only necessary for switching.
func set_camera(newCamera : Camera2D = viewPort.get_camera_2d()):
	camera = newCamera
	if !camera.camera_tween_complete.is_connected(self._on_tween_complete):
		camera.camera_tween_complete.connect(self._on_tween_complete)


##Skips the tween
func skip_tween():
	camera.skip_tween

func _on_tween_complete():
	call_deferred("emit_signal","camera_control_complete")


func _check_valid(point:Vector2i) -> bool:
	var mapSize = Global.flags.CurrentMap.get_used_rect().size
	if point.x < 0 or point.x >= (mapSize.x) or point.y < 0 or point.y >= (mapSize.y):
		print("Cursor: path_camer: point in cameraPath out of bounds")
		return false
	else: return true

#endregion
