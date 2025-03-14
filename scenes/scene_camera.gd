extends Camera2D

class_name SceneCamera

signal camera_tween_complete

var tween : Tween

#region movements
func tween_camera(hex:Vector2i, property: String, speed:float = 1.0, setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase :Tween.EaseType = Tween.EaseType.EASE_OUT_IN):
		if tween: 
			_kill_tween() 
		tween = create_tween()
		var currMap = Global.flags.CurrentMap
		var newPosition
		#var adjSpd : float = speed/path.size()
		
		#newPosition = currMap.map_to_local(hex)
		#var testLocal = camera.global_position
		#var local = currMap.to_local(camera.global_position)
		newPosition = currMap.map_to_local(hex) - global_position
		
		tween.set_trans(setTrans)
		tween.set_ease(setEase)
		tween.tween_property(self, property, newPosition, speed)
		tween.tween_callback(_signal_complete)


func shake_camera(duration:int = 4.0):
	var value := Vector2(0,0)
	var rng = Global.rng
	var roll : float
	var i : int = rng.randi_range(duration-1,duration+1)
	if tween: _kill_tween()
	tween = create_tween()
	
	while i > 0:
		roll = rng.randf_range(-150,150)
		value = Vector2(0,rng.randf_range(-100,100))
		tween.tween_property(self, "offset", value, 0.1)
		tween.tween_property(self, "offset", Vector2(0,0), 0.1)
		i -= 1
	tween.tween_callback(_signal_complete)


func reset_camera(isTweened := false) -> void:
	if isTweened:
		if tween: 
			_kill_tween() 
		tween = create_tween()
		tween.tween_property(self, "offset", Vector2(0,0), 1)
		tween.tween_callback(_signal_complete)
		
	else: 
		offset = Vector2(0,0)
		_signal_complete()

#region utility
func skip_tween():
	if !tween: return
	tween.pause()
	tween.custom_step(10000)
	_signal_complete()


func _kill_tween() -> void:
	if !tween: return
	tween.kill()


func _signal_complete():
	_kill_tween()
	emit_signal("camera_tween_complete")
