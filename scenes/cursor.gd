#This is just the gameboard cursor for selecting units see "menu_cursor" for the one used in menus
@tool
extends Node2D
class_name Cursor


signal camera_path_complete
signal cursor_moved(cell)

@onready var cursorSprite: Sprite2D = $Sprite2D
#do I even need this?
var canter = false
# Coordinates of the current cell the cursor is hovering.
var cell := Vector2i.ZERO:
	set(value):
		var newCell
		if value == cell:
			return
		newCell = region_clamp(value)

		position = Global.flags.CurrentMap.map_to_local(newCell)
		cell = newCell
		
#		print(cursor.position)
		emit_signal("cursor_moved", cell)
#		cTimer.start()

var tick = 1
var originPoint := Vector2i.ZERO
var tween : Tween
	

func _process(_delta):
	if tick == 0:
		var coord = $Cell
		coord.set_text(str(cell))
		tick = 1
	else:
		tick -= 1


func align_camera():
	var camera = $Camera2D
	camera.align()


#Camera Manipulation Functions
##Stores the camera's current cell as an origin point, used for reverting after manipulating the camera
func store_origin():
	originPoint = cell


##Returns camera to stored originPoint and the clears originPoint, retuires store_origin() to have been called first. Pass true to tween the return.
func return_origin(isTweened := false) ->void:
	if originPoint == Vector2i.ZERO: 
		print("Cursor: return_origin: no originPoint value set")
		return
	
	if isTweened:
		visible = false
		cell_path_camera([originPoint], 1)
		visible = true
	else: 
		cell = originPoint
		emit_signal("camera_path_complete")
	originPoint = Vector2i.ZERO


##Tweens the camera along a path consisting of the cell coordinates given in that Array.
func cell_path_camera(cameraPath:Array[Vector2i], speed:float = 1.0, ease:Tween.EaseType = Tween.EaseType.EASE_OUT_IN) -> void:
	#var path : Array
	
	if cameraPath.size() < 1:
		print("Cursor: path_camera: no points found in cameraPath.")
		return
	var mapSize = Global.flags.CurrentMap.get_used_rect().size
	for point in cameraPath:
		if point.x < 0 or point.x >= (mapSize.x) or point.y < 0 or point.y >= (mapSize.y):
			print("Cursor: path_camer: point in cameraPath out of bounds")
			return
	
	#visible = false
	_toggle_drag()
	#path = _create_camera_path(cameraPath)
	_tween_camera(cameraPath, speed)
	

##Skips the tween
func skip_tween():
	if tween.is_running():
		tween.pause()
		tween.custom_step(10000)
	

##Kills the tween
func kill_tween() -> void:
	if !tween: return
	tween.kill()
	_toggle_drag()
	visible = true
	emit_signal("camera_path_complete")


func _create_camera_path(path:Array[Vector2i]) -> Array[Vector2i]:
	var pathFinder := AHexGrid2D.new(Global.flags.CurrentMap)
	var cameraPath := []
	cameraPath.append(pathFinder.find_path(cell, path.pop_front()))
	for point in path:
		var start = path.pop_back()
		cameraPath.append(pathFinder.find_path(start, point))
	return cameraPath


func _tween_camera(path:Array[Vector2i], speed:float = 1.0, ease:Tween.EaseType = Tween.EaseType.EASE_OUT_IN):
		if tween: tween.kill()
		tween = get_tree().create_tween()
		var currMap = Global.flags.CurrentMap
		var newPosition
		#var adjSpd : float = speed/path.size()
		for point in path:
			newPosition = currMap.map_to_local(point)
			tween.tween_property(self, "position", newPosition, speed)
		tween.tween_callback(kill_tween)
		#tween.tween_method(_move_cursor.bind(path), 0, (path.size() - 1), 2).set_trans(Tween.TRANS_LINEAR)


func _move_cursor(destination:Vector2):
	pass



func _toggle_drag():
	$Camera2D.drag_horizontal_enabled = !$Camera2D.drag_horizontal_enabled
	$Camera2D.drag_vertical_enabled = !$Camera2D.drag_vertical_enabled
