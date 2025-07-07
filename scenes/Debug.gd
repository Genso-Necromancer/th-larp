extends Control
class_name DebugScript

#@onready var board = get_node("root/Main/Gameboard/TestMap0")
#@onready var astar = board.astar if board else null

func _ready():
	get_viewport().gui_focus_changed.connect(self._on_gui_focused_changed)
	

func _process(_delta):
	var state = GameState.state
	var keys = GameState.gState.keys()
	var prevState = GameState.previousState
	var pString : StringName
	var cString : StringName
	var actSlave : StringName
	var prevSlave : StringName
	if state != null:
		cString = str(keys[state])
	else:
		cString = "--"
	if prevState:
		pString = str(keys[prevState[0]])
	else:
		pString = "--"
	
	if GameState.activeSlave: actSlave = GameState.activeSlave.name
	else: actSlave = "missing"
	if GameState.previousSlave.has(null): 
		GameState.previousSlave.erase(null)
	elif GameState.previousSlave and GameState.previousSlave[-1] != null: prevSlave = GameState.previousSlave[-1].name
	else: prevSlave = "empty"
		
	$PanelContainer/VBoxContainer/StateDebug.set_text("Slave: " + str(actSlave) + " | Prev.Slave:" + str(prevSlave) + " 
	| State: " + cString + " | " + "Previous State: " + pString)
	
	if Global.focusUnit: $PanelContainer/VBoxContainer/UnitFocus.set_text("focusUnit : [" + str(Global.focusUnit.unit_name)+"]")
	else: $PanelContainer/VBoxContainer/UnitFocus.set_text("focusUnit : [none]")
	
	if Global.focusDanmaku: $PanelContainer/VBoxContainer/DanmakuFocus.set_text("focusDanmaku : [" + str(Global.focusDanmaku)+"]")
	else: $PanelContainer/VBoxContainer/DanmakuFocus.set_text("focusDanmaku : [none]")

func _on_gui_focused_changed(f):
	$PanelContainer/VBoxContainer/focus.set_text("GUI Focus: [" + str(f.name) + "]")
	#print("Current Focus: [" + str(f) + "]")
#func position_has_obstacle(obstacle_position):
	#return board.position_has_obstacle(obstacle_position) or board.position_has_unit(obstacle_position)
#
#func _draw():
	#if not astar is AStar2D: return
	#var offset = board.cell_size/2
	#for point in astar.get_points():
		#if astar.is_point_disabled(point): continue
		#var point_position = astar.get_point_position(point)
		#if position_has_obstacle(point_position): continue
		#
		#draw_circle(point_position+offset, 4, Color.WHITE)
		#
		#var point_connections = astar.get_point_connections(point)
		#var connected_positions = []
		#for connected_point in point_connections:
			#if astar.is_point_disabled(connected_point): continue
			#var connected_point_position = astar.get_point_position(connected_point)
			#if position_has_obstacle(connected_point_position): continue
			#connected_positions.append(connected_point_position)
			#
		#for connected_position in connected_positions:
			#draw_line(point_position+offset, connected_position+offset, Color.WHITE, 2)
