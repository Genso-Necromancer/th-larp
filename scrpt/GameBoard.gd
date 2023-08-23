## Represents and manages the game board. Stores references to entities that are in each cell and
## tells whether cells are occupied or not.
## Units can only move around the grid one at a time.
class_name GameBoard
extends Node2D
signal toggle_action
signal toggle_prof
signal target_focused
signal aimove_finished
signal turn_changed


const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
var oddq_directions = [
	[[+1,  0], [+1, -1], [ 0, -1], 
	[-1, -1], [-1,  0], [ 0, +1]],
	[[+1, +1], [+1,  0], [ 0, -1], 
	[-1,  0], [-1, +1], [ 0, +1]],
]

## Resource of type Grid.
#@export var grid: Resource

## Mapping of coordinates of a cell to a reference to the unit it contains.
var units := {}
var focusUnit : Unit :
	set(value):
		focusUnit = value
		Global.focusUnit = focusUnit
var activeUnit: Unit :
	set(value):
		activeUnit = value
		Global.activeUnit = activeUnit
var targetUnit: Unit
var currMap: GameMap
var _walkable_cells = []
var HpBarVis = true
var _astar: AHexGrid2D
#misc Variables
var mapSize
var canter = false
#var _used_cells
var mapCellSize
var mapRect
var testPath = false
var solidsArray = []
var walkable_rect : Rect2
var unitMoving = false
var snapPath = null
var state : int = 0
var previousState : int = 0
var turnOrder = []
var roundCounter = 0
var turnCounter = 0
var aiTurn = false
var maxTurns = 0
var terrainData = []
var conditions: Array
var prevMousePos: Vector2
var smoothedMouseDelta: Vector2 = Vector2.ZERO
var activeSkill
#Time
@export var mouseSens: float = 0.4
@export var smoothing: float = 0.2
#control Variables
var profileMenu = Global.profileMenu
var actionMenu = Global.actionMenu
#Nodes
@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var cursor: Cursor = $Cursor
@onready var combatManager : CombatManager = $CombatManager
@onready var turnSort : TurnSort = $TurnSort
@onready var turnTest = $Control/TurnLight
@onready var gameState = $gameState
@export var ui_cooldown := 0.2
@onready var gameCamera = $Cursor/Camera2D

var cursorCell := Vector2.ZERO:
	set(value):
		if value == cursorCell:
			return
		cursorCell = region_clamp(value)
		cursor.position = currMap.map_to_local(cursorCell)
		_on_cursor_moved(cursorCell)
		_timer.start()
@onready var _timer: Timer = $Cursor/Timer
@onready var Ai = $AiManager

func _ready() -> void:
	_reinitialize()
	initialize_turns(turnOrder)
	init_gamestate()
	Ai.init_Ai()
#	Ai.rein_units(units)
#	Ai.init_mapdata(terrainData)
	
	for unit in units:
		if units[unit].unitName == "Remilia Scarlet":
			cursorCell = units[unit].cell
	_timer.wait_time = ui_cooldown
	var grabber = units.keys()
	focusUnit = units[grabber[0]]
#	print(units)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	
	
func _reinitialize() -> void:
	units.clear()
	terrainData.clear()
	#gets the map
	for mapChild in get_children():
		var map := mapChild as GameMap
		if not map:
			continue
		currMap = map
	
	#process map data
	mapRect = currMap.get_used_rect()
	var tiles0 = currMap.get_used_cells(0)
	for tile in tiles0:
		terrainData.append([tile, currMap.get_movement_cost(tile), currMap.get_bonus(tile)])
	mapSize = mapRect.size
	mapCellSize = currMap.tileSize
	conditions = currMap.lossConditions
	#start up pathfinder
	_astar = AHexGrid2D.new(currMap)
	_astar.tileSize = mapCellSize

	#grab units from map
	for child in currMap.get_children():
		var unit := child as Unit
		if not unit:
			continue
		units[unit.cell] = unit
		match unit.is_in_group("Player"):
			true: 
				turnOrder.append([false, "Player"])
			false: 
				turnOrder.append([true, "Enemy"])
#		if !combatManager.combat_resolved.is_connected(unit.on_combat_resolved):
#			combatManager.combat_resolved.connect(unit.on_combat_resolved)
		if !unit.imdead.is_connected(self.on_imdead):
			unit.imdead.connect(self.on_imdead)
		if !self.turn_changed.is_connected(unit.on_turn_changed):
			self.turn_changed.connect(unit.on_turn_changed)
		update_unit_terrain(unit)
			
	#grab dice
	combatManager.init_rng()
	#set time
	Global.gameTime = currMap.gameTime
	checkSun()
	
	
func checkSun():
	if Global.gameTime >= 6 and Global.gameTime <= 18:
		Global.day = true
	else:
		Global.day = false
	for unit in units:
		units[unit].check_passives()
		
func init_gamestate():
	gameState.update_map_data(terrainData)
	gameState.update_unit_data(units)
	gameState.set_win(conditions)
	
func update_unit_terrain(unit):
	unit.update_terrain_bonus(terrainData)
	
func _unhandled_input(event: InputEvent) -> void:
	#States:
	#0: default- no menues open, nothing is happening.
	#1: unit has been selected
	#2: action menu is open
	#3: profile menu is open
	#4: Attack targeting
	#5: Combat Forecast
	
	
	
	#T key
	
	if aiTurn:
		return
	if event.is_action_pressed("debug"):
		turn_change()
	if unitMoving:
		return
#	if state == 2 or state == 5:
#		return
	if event is InputEventMouseMotion:
#			var cameraPos = gameCamera.position
			var cameraScale = gameCamera.zoom
			var cursorPos = cursor.position
			var mouseDelta = event.relative * mouseSens
			var mousePos = gameCamera.get_local_mouse_position()
			
			cursorPos += mouseDelta 
#			if event.relative.x != 0 and event.relative.y != 0:
#				cursorPos.x += 10
#				cursorPos.y += 10
			
			mouseDelta = null
			match state:
				0, 1, 3, 4, 6: 
#					print(cursorCell, " + ", currMap.local_to_map(mousePos))
					cursorCell += Vector2(currMap.local_to_map(mousePos))
#					print(cursorCell)
				2: return
				5: return
	if event is InputEventMouseButton:
			if event.is_action_pressed("ui_accept"):
				match state:
					0: cursor_accept_pressed(currMap.map_to_local(cursorCell))
					1: cursor_accept_pressed(currMap.map_to_local(cursorCell))
					2, 3: return
					4, 6: cursor_accept_pressed(currMap.map_to_local(cursorCell))
					5: return
					
	if event is InputEventKey:
			if event.is_action_pressed("ui_accept"):
				match state:
					0: cursor_accept_pressed(currMap.map_to_local(cursorCell))
					1: cursor_accept_pressed(currMap.map_to_local(cursorCell))
					2, 3: return
					4, 6: cursor_accept_pressed(currMap.map_to_local(cursorCell))
					5: return
			elif event.is_action_pressed("ui_info"):
				match state:
					0, 1, 2, 4, 6: 
						if is_occupied(cursorCell):
							previousState = state
							state = 3
							emit_signal("toggle_prof")
						else: toggle_extra_info()
					3: 
						state = previousState
						emit_signal("toggle_prof")
						
			elif event.is_action_pressed("ui_return"):
				match state:
					0: return
					1:
						snapPath = null
						state = 0
						_deselect_active_unit(false)
					2: 
						snapPath = null
						state = 0
						emit_signal("toggle_action")
						_deselect_active_unit(false)
					3: 
						state = previousState
						emit_signal("toggle_prof")
					4, 6: 
						snapPath = null
						state = 2
						_unit_overlay.clear()
						emit_signal("toggle_action")
					5: 
						state = 4
						cursor.visible = true
						attack_targeting(activeUnit)
						emit_signal("target_focused")
						
			elif event.is_action_pressed("ui_scroll_left"):
				pass
			elif event.is_action_pressed("ui_scroll_right"):
				pass
			var shouldMove := event.is_pressed()
			if event.is_echo():
				shouldMove = shouldMove and _timer.is_stopped()
				_timer.wait_time -= 0.05
				_timer.wait_time = clampf(_timer.wait_time, 0.05, 0.2)
			elif !event.is_echo():
				_timer.wait_time = ui_cooldown
			if not shouldMove:
				return
			if event.is_action("ui_right"):
				match state: 
					0, 1, 3, 4, 6: cursorCell += Vector2.RIGHT
					2: return
			elif event.is_action("ui_up"):
				match state: 
					0, 1, 3, 4, 6: cursorCell += (Vector2.UP)
					2: return
				
			elif event.is_action("ui_left"):
				match state: 
					0, 1, 3, 4, 6: cursorCell += (Vector2.LEFT)
					2: return
			elif event.is_action("ui_down"):
				match state: 
					0, 1, 3, 4, 6: cursorCell += (Vector2.DOWN)
					2: return
			else: return
			
## Returns `true` if the cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
		return units.has(cell)
	


## Returns an array of cells a given unit can walk using the flood fill algorithm.

	
func get_region_rect(region: Array) -> Rect2:
	var minPos = Vector2(INF, INF)
	var maxPos = Vector2(-INF, -INF)
	
	for hex in region:
		minPos.x = min(minPos.x, hex.x)
		minPos.y = min(minPos.y, hex.y)
		maxPos.x = max(maxPos.x, hex.x)
		maxPos.y = max(maxPos.y, hex.y)
	var rectSize = maxPos - minPos
	return Rect2(minPos, rectSize)


## Clears, and refills the `units` dictionary with game objects that are on the board.


func init_astar_terrain(attack: bool = false):
	solidsArray.clear()
	solidsArray = []
	_astar.size = mapRect.size
	_astar.cell_size = mapCellSize
	var team = null
	if !aiTurn:
		if activeUnit.is_in_group("Player"):
			team = "Player"
		if activeUnit.is_in_group("Enemy"):
			team = "Enemy"
	else:
		team = "Enemy"
	if !attack:
		for y in mapRect.size.y:
			for x in mapRect.size.x:
				
					var unit = Vector2(x,y)
					var friendly = false
					if unit == null:
						continue
					if units.has(unit):
							if units[unit].is_in_group(team):
								friendly = true
					if units.has(Vector2(x,y)) and !friendly:
						solidsArray.append(Vector2(x,y))
		if solidsArray.size() > 0:
			_astar.set_solid(solidsArray)
	else:
		_astar.set_solid(solidsArray)
				
		

#func set_region_border(cells):
#	for y in mapRect.size.y:
#		for x in mapRect.size.x:
#			if not cells.has(Vector2(x,y)):
#				solidsArray.append(Vector2(x,y))
#	if solidsArray.size() > 0:
#		_astar.set_solid(solidsArray)
#	solidsArray.clear()
#	solidsArray = []
		
func get_walkable_cells(unit: Unit) -> Array:
	
	return _flood_fill(unit.cell, unit.unitData.Stats.MOVE, unit.moveType)

func _flood_fill(cell: Vector2, max_distance: int, moveType : String, terrain: bool = true, attack: bool = false) -> Array:
	init_astar_terrain(attack)
#	print(moveType)
	var path = _astar.find_all_paths(cell, max_distance, moveType, terrain,)
	return path

func get_path_to_cell(cell, current, moveType: String):
	return _astar.find_path(cell, current, moveType)

func is_within_bounds(cell_coordinates: Vector2) -> bool:
	var valid
	if cell_coordinates.x > mapSize.x and cell_coordinates.y > mapSize.y:
		valid = false
#	elif !neighbor.y >= mapSize.y and neighbor.y < mapSize.y:
#		out = true
	else:
		valid = true
	return valid

## Updates the units dictionary with the target position for the unit and asks the activeUnit to walk to it.
func _move_active_unit(new_cell: Vector2, enemy: bool = false, enemyPath = null) -> void:
#	print("move_active: ", new_cell)
	var path = null
	if !new_cell == activeUnit.cell and !enemy:
		if is_occupied(new_cell) or not new_cell in _walkable_cells:
			return
	if !new_cell == activeUnit.cell:
		#print("it's walkable")
		# warning-ignore:return_value_discarded
		units.erase(activeUnit.cell)
		units[new_cell] = activeUnit
		if !enemy:
			path = _unit_path.current_path
		else:
			path = enemyPath
		activeUnit.walk_along(path)
		unitMoving = true
		await activeUnit.walk_finished
		unitMoving = false
		
	if !enemy:
		emit_signal("toggle_action")
	else:
		emit_signal("aimove_finished")


## Selects the unit in the `cell` if there's one there.
## Sets it as the `activeUnit` and draws its walkable cells and interactive move path. 
func _select_unit(cell: Vector2) -> void:
#	#print(units, units.has(cell))
#	print(cell)
	if not units.has(cell):
#		print("oops")
		return
	activeUnit = units[cell]
	activeUnit.is_selected = true
	_walkable_cells = get_walkable_cells(activeUnit)
	walkable_rect = get_region_rect(_walkable_cells)
	_unit_overlay.draw(_walkable_cells)
#	set_region_border(_walkable_cells)
	
	



## Deselects the active unit, clearing the cells overlay and interactive path drawing.
func _deselect_active_unit(confirm) -> void:
#	#print(confirm)
#	print(units)
	if units.has(activeUnit.cell):
		if !confirm: 
			units.erase(activeUnit.cell)
			var new_cell = activeUnit.return_original()
			units[new_cell] = activeUnit
			
		else:
			var new_cell = activeUnit.cell
			activeUnit.originCell = activeUnit.cell
			units[new_cell] = activeUnit
			gameState.add_acted(activeUnit)
			activeUnit.set_acted(true)
	#	#print(units)
		activeUnit.is_selected = false
	_clear_active_unit()
	_unit_overlay.clear()
	_unit_path.stop()

func grab_target(cell, skillState = false):
	var distance
	if not units.has(cell):
		print("oops")
		return
	targetUnit = units[cell]
	if !skillState:
		combatManager.combat_forecast(activeUnit, targetUnit)
		distance = _astar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit.moveType, false)
		emit_signal("target_focused", distance)
	elif skillState:
		print("Skill Manager")
	
## Clears the reference to the activeUnit and the corresponding walkable cells.
func _clear_active_unit() -> void:
	activeUnit = null
	_walkable_cells.clear()


## Selects or moves a unit based on where the cursor is.
func cursor_accept_pressed(cell: Vector2) -> void:
	
	cell = currMap.local_to_map(cell)
#	print(cell, activeUnit)
	match state:
		0: 
			if !activeUnit and is_occupied(cell) and focusUnit.is_in_group("Player") and !focusUnit.acted:
				state = 1
				_select_unit(cell)
			else: return
		1: 
			if !is_occupied(cell):
				state = 2
				_move_active_unit(cell)
			elif cell == activeUnit.cell:
				state = 2
				emit_signal("toggle_action")
			else:
				return
		4: #Attacks
			var friendly = false
			var team = null
			if activeUnit.is_in_group("Player"):
				team = "Player"
			if activeUnit.is_in_group("Enemy"):
				team = "Enemy"
			if focusUnit.is_in_group(team):
				friendly = true
			if is_occupied(cell) and !friendly:
				state = 5
				$Cursor.visible = false
				grab_target(cell)
				
				
			else: return
		5:
			return
#			state = 0
#			combatManager.start_the_justice(activeUnit, focusUnit)
#			emit_signal("target_focused")
#			combat_sequence(activeUnit, focusUnit)
		6: 
			var friendly = false
			var team = null
			var targeting = activeSkill.Target
			if activeUnit.is_in_group("Player"):
				team = "Player"
			if activeUnit.is_in_group("Enemy"):
				team = "Enemy"
			match targeting:
				"Self":
					if is_occupied(cell) and activeUnit == focusUnit:
						state = 5
						$Cursor.visible = false
						grab_target(cell, true)
				"Enemy":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and !friendly:
						state = 5
						$Cursor.visible = false
						grab_target(cell, true)
				"Ally":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly:
						state = 5
						$Cursor.visible = false
						grab_target(cell, true)

## Updates the interactive path's drawing if there's an active and selected unit.
func _on_cursor_moved(new_cell: Vector2) -> void:
#	print(currMap.map_to_local(new_cell))
	
	if units.has(new_cell) and units[new_cell] == null:
					units.erase(new_cell)
	if is_occupied(new_cell):
			focusUnit = units[new_cell]
	
	match state:
		1:
			if new_cell == activeUnit.cell:
				_unit_path.clear()
			if activeUnit and activeUnit.is_selected:
				if !_walkable_cells.has(new_cell):
					return
				var path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit.moveType)
				_unit_path.draw(path)

func attack_targeting(unit: Unit, usingSkill = false, skill = null):
	var maxRange = 0
	var minRange = 1000
	var wepData
	var skillData = UnitData.skillData
	activeSkill = skill
	if unit.is_in_group("Enemy"):
		wepData = UnitData.npcInv
	elif unit.is_in_group("Player"):
		wepData = UnitData.plrInv
	if !usingSkill:
		for wep in unit.unitData.Inv:
			if wepData[wep].LIMIT and wepData[wep].USES == 0:
				continue
			maxRange = max(maxRange, wepData[wep].MAXRANGE, maxRange)
			minRange = min(minRange, wepData[wep].MINRANGE, minRange)
	elif usingSkill:
		maxRange = max(maxRange, skill.RangeMax, maxRange)
		minRange = min(minRange, skill.RangeMin, minRange)
	var path = _flood_fill(unit.cell, maxRange, unit.moveType, false, true)
	minRange = minRange - 1
	minRange = clampi(minRange, 0, 1000)
	var invalid = _flood_fill(unit.cell, minRange, unit.moveType, false, true)
	path = _astar.trim_path(path, invalid)
	snapPath = path
	_unit_overlay.draw_attack(path)
	_unit_path.stop()
	

func combat_sequence(a,_t):
	state = 0
	snapPath = null
	_deselect_active_unit(true)
	a.update_stats()
	if a.needDeath:
		await a.deathDone
	
	turn_change()

func _on_gui_manager_action_selected(selection, skill = null):
#	var cell = cursor.cell
	match selection:
		0: 
			previousState = state
			state = 4
			attack_targeting(activeUnit)
		1: 
			previousState = state
			state = 6
			attack_targeting(activeUnit, true, skill)
		2: 
			previousState = state
			state = 0
			_deselect_active_unit(true)
			turn_change()
#			Input.warp_mouse(currMap.map_to_local(activeUnit.position))
			

func toggle_extra_info():
	if HpBarVis == true: 
		get_tree().set_group("HPBar", "visible", false)
		HpBarVis = false
	elif HpBarVis == false: 
		get_tree().set_group("HPBar", "visible", true)
		HpBarVis = true
	return

func region_clamp(grid_position: Vector2) -> Vector2:
	var out := grid_position
	
	if snapPath != null:
		if !snapPath.has(grid_position):
			return cursorCell
		
	else:
		out.x = clamp(out.x, 0, mapSize.x - 1.0)
		out.y = clamp(out.y, 0, mapSize.y - 1.0)
	return out
	
func free_up():
	if _astar != null:
		_astar.qeue_free()
	if combatManager.rng != null:
		combatManager.rng.qeue_free()
func on_imdead(unit: Unit):
	var remove = unit.cell
	units.erase(remove)
#	var filterDick = []
#	for entry in units:
#		filterDick.append(entry)
#	units = filterDick
#	print(units)



func _on_menu_cursor_wep_updated():
	combatManager.combat_forecast(activeUnit, targetUnit)
	
	
	

	
func turn_change():
#	Ai.rein_units(units)
	gameState.update_unit_data(units)
	turnOrder.pop_front()
	turnCounter += 1
	if turnOrder.size() == 0:
		round_change()
	if turnOrder[0][1] == "Enemy":
		aiTurn = true
		print("Enemy Turn")
		turnTest.self_modulate = Color(1,0,0)
		cursor.visible = false
	elif turnOrder[0][1] == "Player":	
		aiTurn = false
		print("Player Turn")
		turnTest.self_modulate = Color(0,0,1)
		cursor.visible = true
#	print(turnCounter, " ", turnOrder[0][1], " aiTurn:", aiTurn, "
#	", turnOrder)
	gameState.update_remaining_turns(turnOrder)
	
	if aiTurn:
		await get_tree().create_timer(0.5).timeout
		start_ai_turn()
	if Global.gameTime >= 24 - Global.timeFactor:
		var timeMod = Global.gameTime - 24
		timeMod += Global.timeFactor
		Global.gameTime = timeMod
	else: Global.gameTime += Global.timeFactor
	checkSun()
	emit_signal("turn_changed")
		
func round_change():
	turnOrder.clear()
	for child in currMap.get_children():
		var unit := child as Unit
		if not unit:
			continue
		if unit.needDeath:
			unit.queue_free()
			continue
		units[unit.cell] = unit
		
		unit.set_acted(false)
		match unit.is_in_group("Player"):
			true: 
				turnOrder.append([false, "Player"])
			false: 
				turnOrder.append([true, "Enemy"])
	gameState.clear_acted()
	print(units)
	initialize_turns(turnOrder)
	
func initialize_turns(turns):
#	turnOrder.clear()
	turnOrder = turnSort.sort_turns(turns)
	aiTurn = false
	turnTest.self_modulate = Color(0,0,1)
	gameState.update_remaining_turns(turnOrder)
#	print(turnOrder)

func start_ai_turn():
	init_astar_terrain(false)
	if gameState.enemy.size() > 0:
		var result = Ai.get_move(gameState)
		
		
		match result["Best Move"]["action"]:
			"Attack": ai_attack(result)
			"Move": ai_move(result)
	else: turn_change()
		
	

func ai_attack(result):
	var actor = result["Unit"]
	var target = result["Best Move"]["target"]
	var destination = Vector2(result["Best Move"]["launch"])
	var weapon = result["Best Move"]["weapon"]
	_select_unit(actor.cell)
#	var closestCell = _astar.find_closest(actor.cell, target.cell, actor.moveType, _walkable_cells)
	var path = get_path_to_cell(actor.cell, destination, actor.moveType)
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
	actor.set_equipped(weapon)
	actor.update_combatdata()
	combatManager.combat_forecast(actor, target)
	combatManager.start_the_justice(actor,target)
#	print(activeUnit)
	
	gameState.add_acted(activeUnit)
	activeUnit.set_acted(true)
	combat_sequence(activeUnit, focusUnit)
	
func ai_move(result):
	var actor = result["Unit"]
	var destination = Vector2(result["Best Move"]["tile"])
	_select_unit(actor.cell)
	var path = get_path_to_cell(actor.cell, destination, actor.moveType)
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
	gameState.add_acted(actor)
	actor.set_acted(true)
	_deselect_active_unit(true)
	turn_change()
	
func ai_wait(result):
	var actor = result["Unit"]
	_select_unit(actor.cell)
	gameState.add_acted(actor)
	activeUnit.set_acted(true)
	_deselect_active_unit(true)
	turn_change()
	

func _on_gui_manager_start_the_justice():
	state = 0
	combatManager.start_the_justice(activeUnit, focusUnit)
	emit_signal("target_focused")
	gameState.add_acted(activeUnit)
	activeUnit.set_acted(true)
	combat_sequence(activeUnit, focusUnit)


func _on_combat_manager_combat_resolved():
	$Cursor.visible = true

