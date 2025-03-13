extends Camera2D

class_name SceneCamera

var tween : Tween

#func shake_camera(duration:int = 4.0):
	#var value := Vector2(0,0)
	#var rng = Global.rng
	#var roll : float
	#var i : int = rng.randi_range(duration-1,duration+1)
	#if tween: _kill_tween()
	#tween = create_tween()
	#
	#while i > 0:
		#roll = rng.randf_range(-150,150)
		#value = Vector2(0,rng.randf_range(-100,100))
		#tween.tween_property(camera, "offset", value, 0.1)
		#tween.tween_property(camera, "offset", Vector2(0,0), 0.1)
		#i -= 1
	#_kill_tween()
