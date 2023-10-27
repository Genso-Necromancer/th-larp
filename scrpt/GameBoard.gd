#This class is what I see when I wake up in the middle of the night in a cold sweat
#It controls pretty much all facets of gameplay when within a playable "map"
#UIManager, the map itself, all units, skills and combat are manipulated from this point and acts almost like a veritable hub
#UIManager is not a true child of this class so that it can be used outside of simply maps and keep all UI elements in one place.
#signals are uses for communication between them and many of the children of this class
class_name GameBoard
extends Node2D

#signals sent from here
signal toggle_action
signal toggle_prof
signal toggle_skills
signal target_focused
signal aimove_finished
signal turn_changed

signal gb_ready

# units is used to map units to it's hex coordinate
var units := {}

#these are used to store references to actual units that are passed around this class and those it controls
var focusUnit : Unit :
	set(value):
		focusUnit = value
		Global.focusUnit = focusUnit
var activeUnit: Unit :
	set(value):
		activeUnit = value
		Global.activeUnit = activeUnit
var targetUnit: Unit

#variables related to the active map in use
var currMap: GameMap
var mapSize
var mapCellSize
var mapRect
var terrainData = []
var conditions: Array
var lastSkill

@onready var parent = get_parent()
@onready var mainCon = parent.get_parent()

#states
@onready var GameState = mainCon.GameState

#input Global.state
#var Global.state : int = 0



#related to pathfinding
var hexStar: AHexGrid2D
var walkableCells = []
var solidsArray = []
var walkable_rect : Rect2
var unitMoving = false
var snapPath = null

#game turns
var turnOrder = []
var roundCounter = 0
var turnCounter = 0
var aiTurn = false
var maxTurns = 0
var earlyEnd = false

#Global effects
var globalEffects = {}

#I don't even know if I need this
var activeSkill

#controls pseudo UI elements, like HP bars
var HpBarVis = true

#Mouse related
@export var mouseSens: float = 0.4
@export var smoothing: float = 0.2



#Nodes
@onready var unitOverlay: UnitOverlay = $UnitOverlay
@onready var unitPath: UnitPath = $UnitPath
@onready var cursor: Cursor = $Cursor
@onready var combatManager : CombatManager = $CombatManager
@onready var turnSort : TurnSort = $TurnSort
#@onready var turnTest = $Control/TurnLight
@onready var boardState: BoardState = $BoardState
@export var uiCooldown := 0.2
@onready var gameCamera = $Cursor/Camera2D
@onready var ai = $AiManager
#@onready var cTimer: Timer = $Cursor/Timer

#cursor location
var cursorCell := Vector2.ZERO:
	set(value):
		if value == cursorCell:
			return
		cursorCell = region_clamp(value)
		cursor.position = currMap.map_to_local(cursorCell)
		_on_cursor_moved(cursorCell)
#		cTimer.start()




func _ready() -> void:
	pass
	
func load_new_map(map):
	add_child(map)
	_reinitialize()
	
	
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
	hexStar = AHexGrid2D.new(currMap)
	hexStar.tileSize = mapCellSize

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
		if !unit.unit_relocated.is_connected(self.on_unit_relocated):
			unit.unit_relocated.connect(self.on_unit_relocated)
		update_unit_terrain(unit)
			
	connect_general_signals()
	#set time
	Global.gameTime = currMap.gameTime
	checkSun()
	initialize_turns(turnOrder)
	init_gamestate()
	combatManager.init_manager()
	ai.init_ai()
#	ai.rein_units(units)
#	ai.init_mapdata(terrainData)
	for unit in units:
		if units[unit].unitName == "Remilia Scarlet":
			cursorCell = units[unit].cell
#	cTimer.wait_time = uiCooldown
	var grabber = units.keys()
	focusUnit = units[grabber[0]]
#	print(units)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	emit_signal("gb_ready", mainCon.GameState.GB_DEFAULT)
	
	
func connect_general_signals():
	combatManager.warp_selected.connect(self.on_warp_selected)
	self.gb_ready.connect(mainCon.set_new_state)
	
func checkSun():
	if Global.gameTime >= 6 and Global.gameTime <= 18:
		Global.day = true
	else:
		Global.day = false
	for unit in units:
		units[unit].check_passives()
		
func init_gamestate():
	boardState.update_map_data(terrainData)
	boardState.update_unit_data(units)
	boardState.set_win(conditions)
	
func update_unit_terrain(unit):
	unit.update_terrain_data(terrainData)
	
	
func _unhandled_input(event: InputEvent) -> void: #for debugging, delete later
	#T key: Passes current turn for debugging, preventing from doing this if a unit is actively moving or it is not the player turn
	if aiTurn:
		return
	if event.is_action_pressed("debug"):
		turn_change()
		
	if event.is_action_pressed("debugHealTest"):
		for cell in units:
			units[cell].apply_dmg(2)
		
	if unitMoving:
		return
			
			
func gb_mouse_motion(event):
	var cameraScale = gameCamera.zoom
	var cursorPos = cursor.position
	var mouseDelta = event.relative * mouseSens
	var mousePos = gameCamera.get_local_mouse_position()
	
	cursorPos += mouseDelta 
	
	mouseDelta = null
	cursorCell += Vector2(currMap.local_to_map(mousePos))
	
func gb_mouse_pressed():
	cursor_accept_pressed(currMap.map_to_local(cursorCell))

## Returns `true` if the cell is occupied by a unit
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


#Initializes the astar style pathfinding class
func init_hexStar_terrain(attack: bool = false):
	solidsArray.clear()
	solidsArray = []
	hexStar.size = mapRect.size
	hexStar.cell_size = mapCellSize
	#units are split between factions, then it's opposing faction is considered "solid"
	##Plans to allow for flying units to go 'over' opposing units in the future possibly, not currently implemented
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
			hexStar.set_solid(solidsArray, units)
	else:
		hexStar.set_solid(solidsArray, units)
				
		
		
func get_walkable_cells(unit: Unit) -> Array:
	#Possibly unnecessary. 
	#It's convienent to just call using only unit variable and let the function split the necessary info
	return _flood_fill(unit.cell, unit.activeStats.MOVE, unit.moveType)

func _flood_fill(cell: Vector2, max_distance: int, moveType : String, terrain: bool = true, attack: bool = false) -> Array:
	#initializes pathfinder, calls floodfill pathfind and visual displays it all at once
	init_hexStar_terrain(attack)
#	print(moveType)
	var path = hexStar.find_all_paths(cell, max_distance, moveType, terrain)
	return path

func get_path_to_cell(cell, current, moveType: String):
	#this might be a bit unnecessary after changes. does not have convience of "get_walkable_cells"
	return hexStar.find_path(cell, current, moveType)

func is_within_bounds(cell_coordinates: Vector2) -> bool:
	#Keeps the map cursor in bounds
	var valid
	if cell_coordinates.x > mapSize.x and cell_coordinates.y > mapSize.y:
		valid = false
#	elif !neighbor.y >= mapSize.y and neighbor.y < mapSize.y:
#		out = true
	else:
		valid = true
	return valid


func _move_active_unit(new_cell: Vector2, enemy: bool = false, enemyPath = null) -> void:
	# Updates the units dictionary with the target position for the unit and asks the activeUnit to walk to it.
#	print("move_active: ", new_cell)
	var path = null
	if !new_cell == activeUnit.cell and !enemy:
		if is_occupied(new_cell) or not new_cell in walkableCells:
			return
	if !new_cell == activeUnit.cell:
		#print("it's walkable")
		# warning-ignore:return_value_discarded
		units.erase(activeUnit.cell)
		units[new_cell] = activeUnit
		if !enemy:
			path = unitPath.current_path
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



func _select_unit(cell: Vector2) -> void:
	# Selects the unit in the `cell` if there's one there.
	# Sets it as the `activeUnit` and draws its walkable cells and interactive move path. 
#	#print(units, units.has(cell))
#	print(cell)
	if not units.has(cell):
#		print("oops")
		return
	activeUnit = units[cell]
	activeUnit.is_selected = true
	walkableCells = get_walkable_cells(activeUnit)
	walkable_rect = get_region_rect(walkableCells)
	unitOverlay.draw(walkableCells)
#	set_region_border(walkableCells)


func _deselect_active_unit(confirm) -> void:
	# Deselects the active unit, clearing the cells overlay and interactive path drawing
	#confirm is used to let the game know if this is a temporary movement(can be canceled by player) 
	#or a confirmed move so it knows to retain previous position or update the units dictionary


	if activeUnit != null and units.has(activeUnit.cell):
		if !confirm: 
			units.erase(activeUnit.cell)
			var new_cell = activeUnit.return_original()
			units[new_cell] = activeUnit
			
		else:
			var new_cell = activeUnit.cell
			activeUnit.originCell = activeUnit.cell
			units[new_cell] = activeUnit
			boardState.add_acted(activeUnit)
			activeUnit.set_acted(true)
	#	#print(units)
		activeUnit.is_selected = false
	_clear_active_unit()
	unitOverlay.clear()
	unitPath.stop()
	
func on_unit_relocated(oldCell, newCell, unit): #updates unit locations with it's new location
	units.erase(oldCell)
	units[newCell] = unit

func grab_target(cell, skillState = false, skill = null):
	#Called to assign values based on unit at cursor's coordinate
	var distance
	if not units.has(cell):
		print("oops")
		return
	targetUnit = units[cell]
	distance = hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit.moveType, false)
	
	if !skillState:
		combatManager.combat_forecast(activeUnit, targetUnit, distance)
		emit_signal("target_focused", distance)
	elif skillState:
		print("Skill Manager")
		combatManager.combat_forecast(activeUnit, targetUnit, distance, skillState, skill)
		combatManager.run_skill(activeUnit, targetUnit, skill)
		combat_sequence(activeUnit, targetUnit)
		
func _clear_active_unit() -> void:
	# Clears the reference to the activeUnit and the corresponding walkable cells
	
	activeUnit = null
	walkableCells.clear()

func select_cell(): #DEFAULT STATE: If a cell has a valid unit, selects it
	if !activeUnit and is_occupied(cursorCell) and focusUnit.is_in_group("Player") and !focusUnit.acted:
		_select_unit(cursorCell)
		mainCon.previousState = mainCon.state
		mainCon.state = GameState.GB_SELECTED
	else: 
		mainCon.previousState = mainCon.state
		mainCon.state = GameState.GB_ACTION_MENU
		emit_signal("toggle_action", false, true)
		
func select_destination(): #SELECTED STATE
	if !is_occupied(cursorCell) and walkableCells.has(cursorCell):
		mainCon.previousState = mainCon.state
		mainCon.state = GameState.GB_ACTION_MENU
		_move_active_unit(cursorCell)
	elif cursorCell == activeUnit.cell:
		mainCon.previousState = mainCon.state
		mainCon.state = GameState.GB_ACTION_MENU
		emit_signal("toggle_action")

func toggle_unit_profile(): 
	if mainCon.state == GameState.GB_PROFILE:
		var stateStore = mainCon.previousState
		mainCon.previousState = mainCon.state
		mainCon.state = stateStore
		emit_signal("toggle_prof")
	elif is_occupied(cursorCell):
		mainCon.previousState = mainCon.state
		mainCon.state = GameState.GB_PROFILE
		emit_signal("toggle_prof")
	else: toggle_extra_info()
	
func request_deselect():
	wipe_region()
	if Global.actionMenu:
		emit_signal("toggle_action")
	unitOverlay.clear()
	mainCon.state = GameState.GB_DEFAULT
	_deselect_active_unit(false)

func menu_step_back():
	match mainCon.previousState:
		GameState.GB_ACTION_MENU:
			if mainCon.state == GameState.GB_SKILL_MENU:
				emit_signal("toggle_skills")
			elif mainCon.state == GameState.GB_ATTACK_TARGETING:
				emit_signal("toggle_action")
			mainCon.previousState = mainCon.state
			mainCon.state = GameState.GB_ACTION_MENU
			wipe_region()
			cursorCell = activeUnit.cell
	
	
func attack_target_selected():
	var friendly = false
	var team = null
	if activeUnit.is_in_group("Player"):
		team = "Player"
	if activeUnit.is_in_group("Enemy"):
		team = "Enemy"
	if focusUnit.is_in_group(team):
		friendly = true
	if is_occupied(cursorCell) and !friendly:
		mainCon.previousState = mainCon.state
		mainCon.state = GameState.GB_COMBAT_FORECAST
#				$Cursor.visible = false
		grab_target(cursorCell)
		
func skill_target_selected(): #find way to simplify and merge with attack targeting. See your notes, you fucking schizo
	var friendly = false
	var team = null
	var targeting = activeSkill.Target
	if activeUnit.is_in_group("Player"):
		team = "Player"
	if activeUnit.is_in_group("Enemy"):
		team = "Enemy"
	match targeting:
		"Self":
			if is_occupied(cursorCell) and activeUnit == focusUnit:
				mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
				grab_target(cursorCell, true, activeSkill)
		"Enemy":
			if focusUnit.is_in_group(team):
				friendly = true
			if is_occupied(cursorCell) and !friendly:
				mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
				grab_target(cursorCell, true, activeSkill)
		"Ally":
			if focusUnit.is_in_group(team):
				friendly = true
			if is_occupied(cursorCell) and friendly and activeUnit != focusUnit:
				mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
				grab_target(cursorCell, true, activeSkill)
		"Self+":
			if focusUnit.is_in_group(team):
				friendly = true
			if is_occupied(cursorCell) and friendly:
				mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
				grab_target(cursorCell, true, activeSkill)
		"Other":
			if is_occupied(cursorCell) and activeUnit != focusUnit:
				mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
				grab_target(cursorCell, true, activeSkill)

func return_targeting():
	emit_signal("target_focused")
	_on_gui_manager_action_selected(mainCon.previousState, lastSkill)
			
func cursor_accept_pressed(cell: Vector2) -> void:
	# Controls what happens when an element is selected by the player based on input Global.state
	#Includes: Selecting Unit, Destinations; Targets
	#Currently also checks if selection is valid
	
	
	cell = currMap.local_to_map(cell)
#	print(cell, activeUnit)
	match mainCon.state:
		GameState.GB_DEFAULT: 
			if !activeUnit and is_occupied(cell) and focusUnit.is_in_group("Player") and !focusUnit.acted:
				
				mainCon.state = GameState.GB_SELECTED
				_select_unit(cell)
			else: 
				mainCon.previousState = mainCon.state
				mainCon.state = GameState.GB_ACTION_MENU
				emit_signal("toggle_action", false, true)
		GameState.GB_SELECTED: 
			if !is_occupied(cell) and walkableCells.has(cell):
				mainCon.state = GameState.GB_ACTION_MENU
				_move_active_unit(cell)
			elif cell == activeUnit.cell:
				mainCon.previousState = mainCon.state
				mainCon.state = GameState.GB_ACTION_MENU
				emit_signal("toggle_action")
			else:
				return
		GameState.GB_ATTACK_TARGETING: #Attacks
			var friendly = false
			var team = null
			if activeUnit.is_in_group("Player"):
				team = "Player"
			if activeUnit.is_in_group("Enemy"):
				team = "Enemy"
			if focusUnit.is_in_group(team):
				friendly = true
			if is_occupied(cell) and !friendly:
				mainCon.previousState = mainCon.state
				mainCon.state = GameState.GB_COMBAT_FORECAST
#				$Cursor.visible = false
				grab_target(cell)
				
				
			else: return
		GameState.GB_COMBAT_FORECAST:
			return
#			Global.state = 0
#			combatManager.start_the_justice(activeUnit, focusUnit)
#			emit_signal("target_focused")
#			combat_sequence(activeUnit, focusUnit)
		GameState.GB_SKILL_TARGETING: 
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
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, true, activeSkill)
				"Enemy":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and !friendly:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, true, activeSkill)
				"Ally":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly and activeUnit != focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, true, activeSkill)
				"Self+":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, true, activeSkill)
				"Other":
					if is_occupied(cell) and activeUnit != focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, true, activeSkill)
	



func _on_cursor_moved(new_cell: Vector2) -> void:
	# Updates the dynamic visual path if there's an active and selected unit.
#	print(currMap.map_to_local(new_cell))
	var drawPath = false
	if units.has(new_cell) and units[new_cell] == null: #safety measure, catches any uncleared cell storage that slips through the cracks
		units.erase(new_cell)
	if is_occupied(new_cell): #let's the game know what unit is the player's focus, and remains as such until a new unit is focused.
		focusUnit = units[new_cell]
	
	if activeUnit and activeUnit.is_selected:
		drawPath = true
		
	if !drawPath:
		return
	elif !walkableCells.has(new_cell):
		return
	elif new_cell == activeUnit.cell:
		unitPath.clear()
	else:
		var path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit.moveType)
		unitPath.draw(path)
#	match mainCon.state:
#		mainCon.GameState.GB_SELECTED:
#			if new_cell == activeUnit.cell:
#				unitPath.clear()
#			if activeUnit and activeUnit.is_selected:
#				if !walkableCells.has(new_cell):
#					return
#				var path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit.moveType)
#				unitPath.draw(path)

func on_directional_press(direction):
		cursorCell += direction

func on_warp_selected(actor, target, range):
	
	attack_targeting(actor, false, null, true, range)

func attack_targeting(unit: Unit, usingSkill = false, skill = null, rangeOnly = false, rangeOverwrite = 0):
	#draws a visual representation of a unit's attack range, and binds the cursor within this space(snapPath)
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
			if wepData[wep].LIMIT and wepData[wep].DUR == 0:
				continue
			maxRange = max(maxRange, wepData[wep].MAXRANGE, maxRange)
			minRange = min(minRange, wepData[wep].MINRANGE, minRange)
	elif usingSkill:
		maxRange = skill.RangeMax
		minRange = skill.RangeMin
	elif rangeOnly:
		maxRange = rangeOverwrite
		minRange = 1
	var path = _flood_fill(unit.cell, maxRange, unit.moveType, false, true)
	minRange = minRange - 1
	minRange = clampi(minRange, 0, 1000)
	var invalid = _flood_fill(unit.cell, minRange, unit.moveType, false, true)
	if path.size() != 1:
		path = hexStar.trim_path(path, invalid)
	snapPath = path
	bump_cursor()
	unitOverlay.draw_attack(path)
	unitPath.stop()
	

func combat_sequence(a,t):
	#Place holder for when combat has a visual component, currently handles end of combat duties that would occur right after
	wipe_region()
	_deselect_active_unit(true)
	a.update_stats()
	t.update_stats()
	if a.needDeath:
		await a.deathDone
	turn_change()

func _on_gui_manager_action_selected(selection, skill = null):
	#Controls what to do based on the action selected, GUIManager passes that information via Signal
#	var cell = cursor.cell
	lastSkill = skill
	match selection:
		GameState.GB_ATTACK_TARGETING: 
			mainCon.previousState = mainCon.state
			mainCon.state = GameState.GB_ATTACK_TARGETING
			attack_targeting(activeUnit)
		GameState.GB_SKILL_TARGETING: 
			mainCon.previousState = mainCon.state
			mainCon.state = GameState.GB_SKILL_TARGETING
			attack_targeting(activeUnit, true, skill)
		"Wait": 
			mainCon.previousState = mainCon.state
			mainCon.state = GameState.GB_DEFAULT
			_deselect_active_unit(true)
			turn_change()
#			Input.warp_mouse(currMap.map_to_local(activeUnit.position))
		"End":
			mainCon.state = GameState.GB_ROUND_END
			earlyEnd = true
			turn_change()
			

func toggle_extra_info():
	#Toggles HP bars
	if HpBarVis == true: 
		get_tree().set_group("HPBar", "visible", false)
		HpBarVis = false
	elif HpBarVis == false: 
		get_tree().set_group("HPBar", "visible", true)
		HpBarVis = true
	return

func region_clamp(grid_position: Vector2) -> Vector2:
	#Keeps cursor inside temporary boundaries without messing with it's map boundaries
	var out := grid_position
	
	if snapPath != null:
		if !snapPath.has(grid_position):
			return cursorCell
		
	else:
		out.x = clamp(out.x, 0, mapSize.x - 1.0)
		out.y = clamp(out.y, 0, mapSize.y - 1.0)
	return out
	
func wipe_region():
	snapPath = null
	
func bump_cursor():
	var seek = false
	var bumpTo
	var shortest = 1000
	var bumpFound = false
	if !snapPath.has(cursorCell):
		seek = true
	if seek:
		for cell in snapPath:
			var distance = hexStar.find_distance(cursorCell, cell, "Foot", true)
			if units.has(cell) and distance < shortest:
				bumpTo = cell
				shortest = distance
				bumpFound = true
				
	if seek and bumpFound:
		cursorCell = bumpTo
	elif seek:
		cursorCell = snapPath[0]
	
	
func free_up():	#Free Up, worst show on television
	#Not really used atm, exists for when a map is completed
	#Prevents memory leaks by freeing the pathfinding and combat manage from memory
	#SKill Manager, turn sorter, etc will need to be added to this later, unless things fundamentally change down the line once the game is threaded together
	if hexStar != null:
		hexStar.qeue_free()
	if combatManager.rng != null:
		combatManager.rng.qeue_free()
		
func on_imdead(unit: Unit):
	#When Unit signals that it has died, this removes it from units and free's it's coordinates
	#Plan to alter this down the line for Seiga fight, where fallen units will be cached instead of completely removed
	#Intention would be for Seiga to "reanimate" fallen units as part of her "danmaku"
	var remove = unit.cell
	units.erase(remove)
#	var filterDick = []
#	for entry in units:
#		filterDick.append(entry)
#	units = filterDick
#	print(units)



func _on_menu_cursor_wep_updated():
	#required for updating combat forecast as the player hovers weapon selection before combat. Signal is sent from /menu_cursor class
	var distance = hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit.moveType, false)
	combatManager.combat_forecast(activeUnit, targetUnit, distance)
	
	
func turn_change():
	#change turn
#	ai.rein_units(units)
	boardState.update_unit_data(units)
	turnOrder.pop_front()
	turnCounter += 1
	if turnOrder.size() == 0:
		round_change()
	if turnOrder[0][1] == "Enemy":
		mainCon.state = GameState.LOADING
		aiTurn = true
		print("Enemy Turn")
#		turnTest.self_modulate = Color(1,0,0)
		cursor.visible = false
	elif turnOrder[0][1] == "Player":	
		mainCon.state = GameState.GB_DEFAULT
		aiTurn = false
		print("Player Turn")
#		turnTest.self_modulate = Color(0,0,1)
		cursor.visible = true
#	print(turnCounter, " ", turnOrder[0][1], " aiTurn:", aiTurn, "
#	", turnOrder)
	round_duration_tick()
	boardState.update_remaining_turns(turnOrder)
	
	if Global.gameTime >= 24 - Global.timeFactor:
		var timeMod = Global.gameTime - 24
		timeMod += Global.timeFactor
		Global.gameTime = timeMod
	else: Global.gameTime += Global.timeFactor
	checkSun()
	
	if aiTurn:
		await get_tree().create_timer(0.5).timeout
		start_ai_turn()
	emit_signal("turn_changed")
	if !aiTurn and earlyEnd:
		
		set_next_acted()
		turn_change()
	
func round_change():
	#Changes the round and reloads the "turn order" magazine
	earlyEnd = false
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
	boardState.clear_acted()
#	print(units)
	initialize_turns(turnOrder)
	
func initialize_turns(turns):
	#this calls the turn sorter, which is better explain within it's class
#	turnOrder.clear()
	turnOrder = turnSort.sort_turns(turns)
	aiTurn = false
#	turnTest.self_modulate = Color(0,0,1)
	boardState.update_remaining_turns(turnOrder)
#	print(turnOrder)

func set_next_acted():
	for cell in units:
		if !units[cell].acted and units[cell].faction == "Player":
			units[cell].set_acted(true)
			return
	

func start_ai_turn():
	#Gets the ball rolling for the AI to take actions
	init_hexStar_terrain(false)
	if boardState.enemy.size() > 0:
		var result = ai.get_move(boardState)
		
		
		match result["Best Move"]["action"]:
			"Attack": ai_attack(result)
			"Move": ai_move(result)
	else: turn_change()
		
	
#The next three functions process the AI's decided action based on which one is taken
##Attacking, Move without attacking; waiting in place
func ai_attack(result):
	var actor = result["Unit"]
	var target = result["Best Move"]["target"]
	var destination = Vector2(result["Best Move"]["launch"])
	var weapon = result["Best Move"]["weapon"]
	var distance = hexStar.compute_cost(actor.cell, target.cell, actor.moveType, false)
	_select_unit(actor.cell)
#	var closestCell = hexStar.find_closest(actor.cell, target.cell, actor.moveType, walkableCells)
	var path = get_path_to_cell(actor.cell, destination, actor.moveType)
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
	actor.set_equipped(weapon)
	actor.update_stats()
	combatManager.combat_forecast(actor, target, distance)
	combatManager.start_the_justice(actor,target)
#	print(activeUnit)
	
	boardState.add_acted(activeUnit)
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
	boardState.add_acted(actor)
	actor.set_acted(true)
	_deselect_active_unit(true)
	turn_change()
	
func ai_wait(result):
	var actor = result["Unit"]
	_select_unit(actor.cell)
	boardState.add_acted(actor)
	activeUnit.set_acted(true)
	_deselect_active_unit(true)
	turn_change()
	

func _on_gui_manager_start_the_justice():
	#Called via Singal from GUIManager when player initiaties combat
	#Sends necessary data to the combat manager, then initiates the visual representation after results are returned
	#Currently does not return the results, nor pass them due to having no implemented visual representation
	#next step to this will be implementing an ingame text read out of combat to set up framework without need for actual animations yet
	mainCon.state = GameState.LOADING
	combatManager.start_the_justice(activeUnit, focusUnit)
	emit_signal("target_focused")
	boardState.add_acted(activeUnit)
	activeUnit.set_acted(true)
	combat_sequence(activeUnit, focusUnit)
	mainCon.state = GameState.GB_DEFAULT


func _on_combat_manager_combat_resolved():
	#Makes the map cursor visible again after combat manager signals that combat is over
	#Probably unecessary, would be better to move this to the turn change function, as cursor visibility in all other cases are handled else where
	#Left over from very early development
	$Cursor.visible = true

func set_time_factor(effId, factor, duration, type):
	Global.timeFactor = factor
	globalEffects[effId] = {}
	globalEffects[effId]["Type"] = type
	globalEffects[effId]["Factor"] = factor
	globalEffects[effId]["Duration"] = duration
	
func reset_time_factor():
	Global.timeFactor = Global.trueTimeFactor
	
func round_duration_tick(): #tracks duration of round based effects, removing them when duration is up
	var keys = globalEffects.keys()
	for effId in keys:
		globalEffects[effId].Duration -= 1
		if globalEffects[effId].Duration <= 0 and globalEffects[effId].Type == "Time":
			reset_time_factor()
			globalEffects.erase(effId)
		else: #no other global effects exist, this needs to be expanded if a new one is made
			globalEffects.erase(effId)


func _on_combat_manager_time_factor_changed(effId, factor, duration, type):
	set_time_factor(effId, factor, duration, type)
