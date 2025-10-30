extends Camera2D

class_name SceneCamera

signal camera_tween_complete

var tween : Tween

#region movements
func tween_camera(hex:Vector2i,properties:Array[String],speed:float = 1.0,zoom_value:Vector2=get_zoom(),setTrans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, setEase :Tween.EaseType = Tween.EaseType.EASE_OUT_IN):
		if tween: 
			_kill_tween() 
		tween = create_tween()
		tween.finished.connect(self._signal_complete)
		var currMap = Global.map_ref
		var newPosition
		#var adjSpd : float = speed/path.size()
		
		#newPosition = currMap.map_to_local(hex)
		#var testLocal = camera.global_position
		#var local = currMap.to_local(camera.global_position)
		
		tween.set_trans(setTrans)
		tween.set_ease(setEase)
		for property in properties:
			if property == "offset": newPosition = currMap.map_to_local(hex) - global_position
			elif property == "zoom": newPosition = zoom_value
			tween.tween_property(self, property, newPosition, speed)
		


func shake_camera(duration:int = 4):
	var value := Vector2(0,0)
	var rng = Global.rng
	var _roll : float
	var i : int = rng.randi_range(duration-1,duration+1)
	var origOffset : = offset
	if tween: _kill_tween()
	tween = create_tween()
	tween.finished.connect(self._signal_complete)
	while i > 0:
		_roll = rng.randf_range(-150,150)
		value = Vector2(0,rng.randf_range(-100,100))
		tween.tween_property(self, "offset", value, 0.1).as_relative()
		tween.tween_property(self, "offset", origOffset, 0.1)
		i -= 1


func reset_camera(isTweened:=false,speed:float=1.0,zoom_reset:Vector2=Vector2(1,1),set_trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR, set_ease:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	if isTweened:
		if tween: 
			_kill_tween() 
		tween = create_tween()
		tween.set_trans(set_trans)
		tween.set_ease(set_ease)
		tween.finished.connect(self._signal_complete)
		tween.tween_property(self, "zoom", zoom_reset, speed)
		tween.tween_property(self, "offset", Vector2(0,0), speed)
	else: 
		offset = Vector2(0,0)
		zoom = zoom_reset
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
