#This class is what I see when I wake up in the middle of the night in a cold sweat
#It controls pretty much all facets of gameplay when within a playable "map"
#UIManager, the map itself, all units, skills and combat are manipulated from this point and acts almost like a veritable hub
#UIManager is not a true child of this class so that it can be used outside of simply maps and keep all UI elements in one place.
#signals are uses for communication between them and many of the children of this class
class_name GameBoard
extends Node2D

#signals sent from here
signal menu_canceled
signal player_lost
signal player_win
signal cell_selected
signal unit_selected(unit)
signal unit_move_ended(unit)
signal unit_deselected
signal cmbData_updated(cmbData)
signal walk_complete
signal map_loaded
signal skill_target_canceled


signal toggle_prof
signal toggle_skills
signal target_focused
signal aimove_finished
signal turn_changed
signal exp_display
signal continue_turn
signal call_setup
signal deploy_toggled
signal formation_closed
signal gb_ready
signal turn_order_updated

enum ACTION_TYPE {ATTACK, SKILL, WAIT, END}

@onready var yaBoy = $"."
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
var targetUnit : Unit

#set up variables
var forcedDeploy : Dictionary
var deploymentCells : Array
var filledSlots : int = 0
var storedUnit : Unit
var storedCell : Vector2i = Vector2i(-1,-1)

#variables related to the active map in use
var currMap: GameMap
var mapSize
var mapCellSize
var mapRect
var terrainData := []
var lastSkill
var warpTarget
var deathList = []

#Units by UnitID
var unitObjs : Dictionary = Global.unitObjs

@onready var parent = get_parent()
@onready var mainCon = parent.get_parent()

#states
@onready var GameState = mainCon.GameState




#ready() is the gayest fucking shit ever
var defineUnits = false

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

#Process variables
var turnComplete : bool = false


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
var cursor: Cursor
@onready var combatManager : CombatManager = $CombatManager
@onready var turnSort : TurnSort = $TurnSort
#@onready var turnTest = $Control/TurnLight
@onready var boardState: BoardState = $BoardState
@export var uiCooldown := 0.2
@onready var gameCamera = $Cursor/Camera2D
@onready var ai = $AiManager

#@onready var cTimer: Timer = $Cursor/Timer
var unitScn := preload("res://scenes/Unit.tscn")

#cursor location
var cursorCell := Vector2i.ZERO:
	set(value):
		if value == cursorCell:
			return
		cursorCell = region_clamp(value)

		cursor.position = currMap.map_to_local(cursorCell)
#		print(cursor.position)
		_on_cursor_moved(cursorCell)
#		cTimer.start()

	
func _process(_delta):
	if mainCon.state != GameState.ACCEPT_PROMPT:
		_check_flags()
	if deathList.size() >= 0:
		_wipe_dead()
	if mainCon.state == GameState.ACCEPT_PROMPT:
		pass
	elif mainCon.state == GameState.FAIL_STATE:
		pass
	elif mainCon.state == GameState.WIN_STATE:
		pass
	elif turnComplete and deathList.size() == 0:
		turnComplete = false
		turn_change()
		
func _toggle_pause():
	get_tree().paused = !get_tree().paused
	
func _on_jobs_done(id, node):
	match id:
		"Cursor": 
			cursor = node
		"CmbMng":
			combatManager = node
			
#Map Functions
func _get_current_map():
	for mapChild in get_children(): #mapchild
		var map := mapChild as GameMap
		if not map:
			continue
		return map
		
	
func _change_state(state):
	var newState = state
	mainCon.newSlave = [self]
	if state == mainCon.state:
		return
	mainCon.previousState = mainCon.state
	mainCon.state = newState
	

	
func change_map(map):
	_reset_map_flags()
	turnComplete = false # find a better place to reinitialize this and above value HERE
	if currMap:
		currMap.queue_free()
		await currMap.tree_exited
	self.call_deferred("_load_new_map", map)
		
func _load_new_map(map):
	var newMap = map.instantiate()
	add_child(newMap)
	
func on_map_ready():
	emit_signal("map_loaded")
	self.call_deferred("_initialize_new_map")
	
#func on_map_gone():
	#self.call_deferred("_initialize_new_map")
	
	
func _initialize_new_map():
	_connect_general_signals()
	currMap = _get_current_map()
	_initialize_terrain_data()
	_initialize_hexstar()
	units.clear()
	_set_game_time()
	_store_enemy_units()
	_load_units()
	_init_gamestate()
	combatManager.init_manager()
	ai.init_ai()
	_cursor_toggle(true)
	_cursor_toggle(false)

func _initialize_terrain_data():
	terrainData.clear()
	var tiles0 = currMap.get_used_cells(0) #terrainData
	for tile in tiles0: 
		terrainData.append([tile, currMap.get_movement_cost(tile), currMap.get_bonus(tile)])
	
func _initialize_hexstar():
	mapRect = currMap.get_used_rect() #initializing hexStar
	mapSize = mapRect.size
	mapCellSize = currMap.tileSize
	
	#start up pathfinder
	hexStar = AHexGrid2D.new(currMap)
	hexStar.tileSize = mapCellSize
	
func _store_enemy_units():
	units.clear()
	for child in currMap.get_children(): #grab enemy unit locations
		var unit := child as Unit
		if not unit:
			continue
		
		match unit.is_in_group("Player"): #turn order initializing
			true: 
				continue
			false: 
				units[unit.cell] = unit
		if !self.turn_changed.is_connected(unit.on_turn_changed): #unit signals
			self.turn_changed.connect(unit.on_turn_changed)
		if !unit.unit_relocated.is_connected(self.on_unit_relocated): 
			unit.unit_relocated.connect(self.on_unit_relocated)
#		if !unit.exp_gained.is_connected(self.on_exp_gained):
#			unit.exp_gained.connect(self.on_exp_gained)
		_update_unit_terrain(unit) #update terrain data
		
func _load_units(): #merge with store enemy units
	
	var roster = UnitData.rosterData
	#var spawnLoc
	filledSlots = 0
	deploymentCells = currMap.get_deployment_cells()
	var depCount = deploymentCells.size()
	forcedDeploy = currMap.get_forced_deploy()
	var forcedUnits = forcedDeploy.keys()
	
	
	for unit in roster:
		var newUnit = unitScn.instantiate().init_unit(true, Enums.FACTION_ID.PLAYER, unit)
		currMap.add_child(newUnit)
		#newUnit.add_to_group("Player")
		unitObjs[newUnit.unitId] = newUnit
	for child in currMap.get_children(): #grab unit children
		var unit := child as Unit
		if not unit:
			continue
		_connect_unit_signals(unit)
		var isPlayable : bool
		if unit.FACTION_ID == Enums.FACTION_ID.PLAYER:
			isPlayable = true
		else:
			isPlayable = false
		if isPlayable and forcedDeploy.has(unit.unitId):
			unit.forced = true
			_deploy_unit(unit, true, forcedDeploy[unit.unitId])
		elif isPlayable and filledSlots < deploymentCells.size():
			_deploy_unit(unit)
		elif isPlayable and filledSlots >= deploymentCells.size():
			_undeploy_unit(unit, true)
	
		if !isPlayable:
			unit.init_unit()
			units[unit.cell] = unit
			unitObjs[unit.unitId] = unit
			
		_update_unit_terrain(unit)
		unit.set_process(true)
	_update_roster_label()
	emit_signal("call_setup", depCount, forcedUnits)



func _connect_unit_signals(unit):
#	if !combatManager.combat_resolved.is_connected(unit.on_combat_resolved):
#		combatManager.combat_resolved.connect(unit.on_combat_resolved)
	if !unit.death_done.is_connected(self.on_death_done):
		unit.death_done.connect(self.on_death_done)
	if !self.turn_changed.is_connected(unit.on_turn_changed): 
		self.turn_changed.connect(unit.on_turn_changed)
	if !unit.unit_relocated.is_connected(self.on_unit_relocated): 
		unit.unit_relocated.connect(self.on_unit_relocated)
	if !unit.exp_gained.is_connected(self.on_exp_gained) and unit.FACTION_ID == Enums.FACTION_ID.PLAYER:
		unit.exp_gained.connect(self.on_exp_gained)
	if !self.turn_order_updated.is_connected(unit.on_turn_order_updated):
		self.turn_order_updated.connect(unit.on_turn_order_updated)
	
		
func _set_game_time():
	Global.gameTime = currMap.gameTime #setting game time
	checkSun()
		
#func _reinitialize() -> void:
#	units.clear()
#	terrainData.clear()
#	#gets the map
#
#
#	#process map data
#
#	var tiles0 = currMap.get_used_cells(0) #terrainData
#	for tile in tiles0: 
#		terrainData.append([tile, currMap.get_movement_cost(tile), currMap.get_bonus(tile)])
#
#	mapRect = currMap.get_used_rect() #initializing hexStar
#	mapSize = mapRect.size
#	mapCellSize = currMap.tileSize
#	conditions = currMap.lossConditions
#	#start up pathfinder
#	hexStar = AHexGrid2D.new(currMap)
#	hexStar.tileSize = mapCellSize
#
#	#grab units from map
#	for child in currMap.get_children(): #grab enemy unit locations
#		var unit := child as Unit
#		if not unit:
#			continue
#		units[unit.cell] = unit
#		match unit.is_in_group("Player"): #turn order initializing
#			true: 
#				turnOrder.append([false, "Player"])
#			false: 
#				turnOrder.append([true, "Enemy"])
##		if !combatManager.combat_resolved.is_connected(unit.on_combat_resolved):
##			combatManager.combat_resolved.connect(unit.on_combat_resolved)
##		if !unit.imdead.is_connected(self.on_imdead):
##			unit.imdead.connect(self.on_imdead)
#		if !self.turn_changed.is_connected(unit.on_turn_changed): #unit signals
#			self.turn_changed.connect(unit.on_turn_changed)
#		if !unit.unit_relocated.is_connected(self.on_unit_relocated): 
#			unit.unit_relocated.connect(self.on_unit_relocated)
#		if !unit.exp_gained.is_connected(self.on_exp_gained):
#			unit.exp_gained.connect(self.on_exp_gained)
#		update_unit_terrain(unit) #update terrain data
#
##	connect_general_signals() #general signal connect
#	#set time
#	Global.gameTime = currMap.gameTime #setting game time
#	checkSun()
#	initialize_turns(turnOrder)
##	init_gamestate()
#	combatManager.init_manager()
#	ai.init_ai()
##	ai.rein_units(units)
##	ai.init_mapdata(terrainData)
#	for unit in units: #focus set and cursor default
#		if units[unit].unitName == "Remilia Scarlet":
#			cursorCell = units[unit].cell
##	cTimer.wait_time = uiCooldown
#	var grabber = units.keys()
#	focusUnit = units[grabber[0]] 
##	print(units)
#	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN) #mouse confined
#	emit_signal("gb_ready", mainCon.GameState.GB_DEFAULT)
	
	
func _connect_general_signals():
	self.gb_ready.connect(mainCon.set_new_state)
	#self.cell_selected.connect(mainCon.on_cell_selected)
	
func checkSun():
	if Global.gameTime >= 6.0 and Global.gameTime <= 18.0:
		Global.day = true
	else:
		Global.day = false
	for unit in units:
		units[unit].check_passives()
		
func _init_gamestate():
	boardState.update_map_data(terrainData)
	boardState.update_unit_data(units)
	
	
func _update_unit_terrain(unit):
	unit.update_terrain_data(terrainData)
	
	
func _unhandled_input(_event: InputEvent) -> void: #for debugging, delete later
	#T key: Passes current turn for debugging, preventing from doing this if a unit is actively moving or it is not the player turn
	if aiTurn:
		return
		
	if unitMoving:
		return
			
			
func gb_mouse_motion(_event):
	var mousePos: Vector2i = currMap.get_local_mouse_position()
	var toMap = currMap.local_to_map(mousePos)
#	print(toMap)

	cursorCell = Vector2i(toMap)
	
func gb_mouse_pressed():
	cursor_accept_pressed(currMap.map_to_local(cursorCell))

## Returns `true` if the cell is occupied by a unit
func is_occupied(cell: Vector2i) -> bool:
		return units.has(cell)
	


## Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_region_rect(region: Array) -> Rect2:
	var minPos = Vector2i(INF, INF)
	var maxPos = Vector2i(-INF, -INF)
	
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
	if !mainCon.state == GameState.GB_AI_TURN:
		if activeUnit.is_in_group("Player"):
			team = "Player"
		if activeUnit.is_in_group("Enemy"):
			team = "Enemy"
	else:
		team = "Enemy"
	if !attack:
		for y in mapRect.size.y:
			for x in mapRect.size.x:
					var unit = Vector2i(x,y)
					var friendly = false
					if unit == null:
						continue
					if units.has(unit):
							if units[unit].is_in_group(team):
								friendly = true
					if units.has(Vector2i(x,y)) and !friendly:
						solidsArray.append(Vector2i(x,y))
		if solidsArray.size() > 0:
			hexStar.set_solid(solidsArray, units)
	else:
		hexStar.set_solid(solidsArray, units)
				
		

	
		
func get_walkable_cells(unit: Unit) -> Array:
	#Possibly unnecessary. 
	#It's convienent to just call using only unit variable and let the function split the necessary info
	return _flood_fill(unit.cell, unit.activeStats.MOVE, unit.unitData.MoveType)

func _flood_fill(cell: Vector2i, max_distance: int, moveType : int, terrain: bool = true, attack: bool = false) -> Array:
	#initializes pathfinder, calls floodfill pathfind and visual displays it all at once
	init_hexStar_terrain(attack)
#	print(moveType)
	var path = hexStar.find_all_paths(cell, max_distance, moveType, terrain)
	return path

func get_path_to_cell(cell, current, moveType: int = Enums.MOVE_TYPE.FOOT):
	#this might be a bit unnecessary after changes. does not have convience of "get_walkable_cells"
	return hexStar.find_path(cell, current, moveType)

func is_within_bounds(cell_coordinates: Vector2i) -> bool:
	#Keeps the map cursor in bounds
	var valid
	if cell_coordinates.x > mapSize.x and cell_coordinates.y > mapSize.y:
		valid = false
#	elif !neighbor.y >= mapSize.y and neighbor.y < mapSize.y:
#		out = true
	else:
		valid = true
	return valid



func select_cell(): #DEFAULT STATE: If a cell has a valid unit, selects it
	var occupied = is_occupied(cursorCell)
	if !occupied:
		_change_state(GameState.GB_ACTION_MENU)
		emit_signal("cell_selected", cursorCell)
	elif units[cursorCell].FACTION_ID == Enums.FACTION_ID.PLAYER:
		_select_unit(cursorCell)
	else:
		pass #TO-DO: seperate selection that just toggles a unit's movement and reach
		

func _move_active_unit(new_cell: Vector2i, enemy: bool = false, enemyPath = null) -> void:
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
		emit_signal("unit_move_ended", activeUnit)
	else:
		emit_signal("aimove_finished")



func _select_unit(cell: Vector2i) -> void:
	# Selects the unit in the `cell` if there's one there.
	# Sets it as the `activeUnit` and draws its walkable cells and interactive move path. 
#	#print(units, units.has(cell))
#	print(cell)
	if units.has(cell):
		activeUnit = units[cell]
		#activeUnit.save_equip()
		activeUnit.is_selected = true
		walkableCells = get_walkable_cells(activeUnit)
		walkable_rect = get_region_rect(walkableCells)
		unitOverlay.draw(walkableCells)
		_change_state(GameState.GB_SELECTED)
		emit_signal("unit_selected", units[cell])
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
			activeUnit.restore_equip()
			
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
	if units.has(oldCell):
		units.erase(oldCell)
	units[newCell] = unit
	

func grab_target(cell, skillId = false):
	#Called to assign values based on unit at cursor's coordinate
	var distance : float
	var foreCast : Dictionary
	var mode : int
	if not units.has(cell):
		print("oops")
		return
	targetUnit = units[cell]
	distance = hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit.unitData.MoveType, false)
	if !skillId:
		foreCast = combatManager.get_forecast(activeUnit, targetUnit, distance)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mode = 0
	else:
		foreCast = combatManager.get_forecast(activeUnit, targetUnit, distance, skillId)
		mode = 1
	emit_signal("target_focused", foreCast, mode, distance)
			
func _activate_skill():
	#print("Skill Manager")
	combatManager.run_skill(activeUnit, targetUnit, activeSkill)
	if warpTarget == null:
		combat_sequence(activeUnit, targetUnit)
		
func _clear_active_unit() -> void:
	# Clears the reference to the activeUnit and the corresponding walkable cells
	
	activeUnit = null
	walkableCells.clear()


		
func select_destination(): #SELECTED STATE
	var isOccupied = is_occupied(cursorCell)
	var isWalkable = walkableCells.has(cursorCell)
	if !isOccupied and isWalkable:
		_change_state(GameState.GB_ACTION_MENU)

		_move_active_unit(cursorCell)
	elif cursorCell == activeUnit.cell:
		_change_state(GameState.GB_ACTION_MENU)

		emit_signal("unit_move_ended", activeUnit)

func select_formation_cell():
	if deploymentCells.has(cursorCell) and is_occupied(cursorCell) and storedUnit == null:
		storedUnit = units[cursorCell]
		storedCell = cursorCell
		storedUnit.is_selected = true
	elif deploymentCells.has(cursorCell) and is_occupied(cursorCell):
		_deploy_swap(storedUnit, units[cursorCell])
		# swap function here
	elif deploymentCells.has(cursorCell) and storedCell != Vector2i(-1,-1):
		storedCell = cursorCell
	elif deploymentCells.has(cursorCell):
		_deploy_swap(storedUnit, storedCell)
		#swap function
		
func _deploy_swap(start, end):
	#var defValue = Vector2i(-1,-1)
	var swap = false
	if end is Unit:
		swap = true
	if !swap:
		start.relocate_unit(end)
		deselect_formation_cell()
	else:
		var cell1 = start.cell
		var cell2 = end.cell
		var unit1 = start
		var unit2 = end
		start.relocate_unit(cell2, false)
		end.relocate_unit(cell1, false)
		units[cell1] = unit2
		units[cell2] = unit1
		deselect_formation_cell()

func deselect_formation_cell():
	var defValue = Vector2i(-1,-1)
	if storedUnit == null and storedCell == defValue:
		emit_signal("formation_closed")
	if storedUnit != null:
		storedUnit.is_selected = false
		storedUnit = null
	if storedCell != defValue:
		storedCell = defValue

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
	emit_signal("unit_deselected")
	unitOverlay.clear()
	_change_state(GameState.GB_DEFAULT)
	_deselect_active_unit(false)
	
func skill_target_cancel():
	wipe_region()
	unitOverlay.clear()
	_change_state(GameState.GB_ACTION_MENU)
	_snap_cursor(activeUnit.cell)
	emit_signal("skill_target_canceled")
	

func end_targeting():
	_change_state(GameState.GB_ACTION_MENU)
	wipe_region()
	unitOverlay.clear()
	cursorCell = activeUnit.cell
	emit_signal("unit_move_ended", activeUnit)

func menu_step_back():
	match mainCon.state:
		GameState.GB_COMBAT_FORECAST:
			emit_signal("action_called", activeUnit)
			_change_state(GameState.GB_ACTION_MENU)
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
		
func skill_target_selected():
	if !UnitData.skillData.has(activeSkill):
		print("No Valid SkillID")
		return
	var friendly := false
	var valid := false
	var skill = UnitData.skillData[activeSkill]
	if focusUnit.FACTION_ID == activeUnit.FACTION_ID or focusUnit.FACTION_ID == Enums.FACTION_ID.NPC:
		friendly = true
	match skill.Target:
		"Self":
			if is_occupied(cursorCell) and activeUnit == focusUnit:
				valid = true
		"Enemy":
			if is_occupied(cursorCell) and !friendly:
				valid = true
		"Ally":
			if is_occupied(cursorCell) and friendly and activeUnit != focusUnit:
				valid = true
		"Self+":
			if is_occupied(cursorCell) and friendly:
				valid = true
		"Other":
			if is_occupied(cursorCell) and activeUnit != focusUnit:
				valid = true
	if valid:
		_change_state(GameState.GB_COMBAT_FORECAST)
		grab_target(cursorCell, activeSkill)

func return_targeting():
	#var s
	emit_signal("menu_canceled")
	match mainCon.previousState:
		GameState.GB_ATTACK_TARGETING: 
			#s = "Attack"
			activeUnit.restore_equip()
			attack_targeting(activeUnit)
		GameState.GB_SKILL_TARGETING:
			attack_targeting(activeUnit, activeSkill)
			
func cursor_accept_pressed(cell: Vector2i) -> void: #IS THIS EVEN RELEVANT ANYMORE???
	# Controls what happens when an element is selected by the player based on input Global.state
	#Includes: Selecting Unit, Destinations; Targets
	#Currently also checks if selection is valid
	
	
	cell = currMap.local_to_map(cell)
#	print(cell, activeUnit)
	match mainCon.state:
		GameState.GB_DEFAULT: 
			if !activeUnit and is_occupied(cell) and focusUnit.is_in_group("Player") and !focusUnit.status.Acted:
				
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
						grab_target(cell, activeSkill)
				"Enemy":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and !friendly:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, activeSkill)
				"Ally":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly and activeUnit != focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, activeSkill)
				"Self+":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, activeSkill)
				"Other":
					if is_occupied(cell) and activeUnit != focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell, activeSkill)
	



func _on_cursor_moved(new_cell: Vector2i) -> void:
	# Updates the dynamic visual path if there's an active and selected unit.
#	print(currMap.map_to_local(new_cell))
#	print(new_cell)
	var drawPath = false
	if units.has(new_cell) and units[new_cell] == null: #safety measure, catches any uncleared cell storage that slips through the cracks
		units.erase(new_cell)
	if is_occupied(new_cell): #let's the game know what unit is the player's focus, and remains as such until a new unit is focused.
		focusUnit = units[new_cell]
	
	if activeUnit and activeUnit.is_selected and mainCon.state == GameState.GB_SELECTED:
		drawPath = true
		
	if !drawPath:
		return
	elif !walkableCells.has(new_cell):
		return
	elif new_cell == activeUnit.cell:
		unitPath.clear()
	else:
		var path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit.unitData.MoveType)
		unitPath.draw(path)
#	match mainCon.state:
#		mainCon.GameState.GB_SELECTED:
#			if new_cell == activeUnit.cell:
#				unitPath.clear()
#			if activeUnit and activeUnit.is_selected:
#				if !walkableCells.has(new_cell):
#					return
#				var path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit.unitData.MoveType)
#				unitPath.draw(path)

func on_directional_press(direction: Vector2i):
	var nextCell = cursorCell + direction
	var newCell
	
	if snapPath != null and !snapPath.has(nextCell):
		newCell = find_next_best_cell(cursorCell, nextCell)
		cursorCell = newCell
	else: cursorCell += direction



func attack_targeting(unit: Unit, skillId := ""): 
	var maxRange := 0
	var minRange := 1000
	var wepData :Dictionary = UnitData.itemData
			
	if skillId != "":
		var skillData = UnitData.skillData[skillId]
		activeSkill = skillId
		maxRange = skillData.RangeMax
		minRange = skillData.RangeMin
		_change_state(GameState.GB_SKILL_TARGETING)
	else:
		for wep in unit.unitData.Inv:
			if wep.DUR == 0:
				continue
			maxRange = max(maxRange, wepData[wep.ID].MAXRANGE, maxRange)
			minRange = min(minRange, wepData[wep.ID].MINRANGE, minRange)
		_change_state(GameState.GB_ATTACK_TARGETING)
			
	_draw_range(unit, maxRange, minRange)
	
func warp_targeting(unit, wRange):
	_draw_range(unit, wRange)
	_change_state(GameState.GB_WARP)
	
func _draw_range(unit : Unit, maxRange : int, minRange := 0):
	#draws a visual representation of a unit's attack range, and binds the cursor within this space(snapPath)
	var path = _flood_fill(unit.cell, maxRange, unit.unitData.MoveType, false, true)
	
	if path.size() != 1 and minRange > 0:
		minRange = minRange - 1
		minRange = clampi(minRange, 0, 1000)
		var invalid = _flood_fill(unit.cell, minRange, unit.unitData.MoveType, false, true)
		path = hexStar.trim_path(path, invalid)
	snapPath = path
	bump_cursor()
	unitOverlay.draw_attack(path)
	unitPath.stop()
	
func initiate_warp():
	#var friendly = false
#	var team = null
	if !is_occupied(cursorCell) and !solidsArray.has(cursorCell) and snapPath.has(cursorCell):
		combatManager.warp_to(warpTarget, cursorCell)
		combat_sequence(activeUnit, warpTarget, "warp")
		warpTarget = null

func combat_sequence(a,t, _scenario = null):
	#Place holder for when combat has a visual component, currently handles end of combat duties that would occur right after
	var addingExp = false
	
	wipe_region()
	_deselect_active_unit(true)
	a.update_stats()
	t.update_stats()
	if a.needDeath:
		
		await a.death_done
		addingExp = t.add_exp("Kill", a)
	if t.needDeath:
		
		await t.death_done
		addingExp = a.add_exp("Kill", t)
	if addingExp:
		await self.continue_turn
	turnComplete = true

func toggle_extra_info():
	#Toggles HP bars
	if HpBarVis == true: 
		get_tree().set_group("HPBar", "visible", false)
		HpBarVis = false
	elif HpBarVis == false: 
		get_tree().set_group("HPBar", "visible", true)
		HpBarVis = true
	return

func region_clamp(grid_position: Vector2i) -> Vector2i:
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
			var distance = hexStar.find_distance(cursorCell, cell, Enums.MOVE_TYPE.FOOT, true)
			if units.has(cell) and distance < shortest:
				bumpTo = cell
				shortest = distance
				bumpFound = true
				
	if seek and bumpFound:
		cursorCell = bumpTo
	elif seek:
		cursorCell = snapPath[0]
	
func find_next_best_cell(currentCell, nextCell): #it's still pretty jank, but atleast you can reach cells using direction keys using this. Without it, some cannot be reached during targeting.
	var shortestNext = 1000
	var shortestCurrent = 1000
	var nextBest
	for cell in snapPath:
		var distanceNext = hexStar.find_distance(nextCell, cell, Enums.MOVE_TYPE.FOOT, true)
		var distanceCurrent= hexStar.find_distance(currentCell, cell, Enums.MOVE_TYPE.FOOT, true)
		if distanceNext <= shortestNext and distanceCurrent <= shortestCurrent and cell != currentCell:
			shortestNext = distanceNext
			shortestCurrent = distanceCurrent
			nextBest = cell
	return nextBest
	
#func free_up():	#Free Up, worst show on television
#	#Not really used atm, exists for when a map is completed
#	#Prevents memory leaks by freeing the pathfinding and combat manage from memory
#	#SKill Manager, turn sorter, etc will need to be added to this later, unless things fundamentally change down the line once the game is threaded together
#	if hexStar != null:
#		hexStar.qeue_free()
#	if combatManager.rng != null:
#		combatManager.rng.qeue_free()
		
func on_death_done(unit: Unit):
	
	#Plan to alter this down the line for Seiga fight, where fallen units will be cached instead of completely removed
	#Intention would be for Seiga to "reanimate" fallen units as part of her "danmaku"
	deathList.append(unit)
	currMap.check_event("death", unit)
	
	
#	var filterDick = []
#	for entry in units:
#		filterDick.append(entry)
#	units = filterDick
#	print(units)
func _wipe_dead():
	for dead in deathList:
		_clear_unit(dead)
	deathList.clear()

func _clear_unit(unit):
	var remove = unit.cell
	units.erase(remove)
	unit.queue_free()
	#clear non-player units from unitData HERE!!!
	
func _remove_from_grid(unit: Unit):
	var remove = unit.cell
	if units.has(remove):
		units.erase(remove)
	
	
	
func turn_change():
	#change turn
#	ai.rein_units(units)
	boardState.update_unit_data(units)
	turnOrder.pop_front()
	turnCounter += 1
	if turnOrder.size() == 0:
		round_change()
	if turnOrder[0] == "Enemy":
		mainCon.state = GameState.LOADING
		aiTurn = true
		print("Enemy Turn")
		_cursor_toggle(false)
	elif turnOrder[0] == "Player":	
		mainCon.state = GameState.GB_DEFAULT
		aiTurn = false
		print("Player Turn")
		_cursor_toggle(true)
	elif turnOrder[0] == "NPC": #Currently, NPC turns aren't a feature of the AI
		mainCon.state = GameState.LOADING
#		aiTurn = true
		print("NPC Turn")
		_cursor_toggle(false)	
#	print(turnCounter, " ", turnOrder[0], " aiTurn:", aiTurn, "
#	", turnOrder)
	round_duration_tick()
	boardState.update_remaining_turns(turnOrder)
	_progress_time()
	checkSun()
	emit_signal("turn_changed")
	if !aiTurn and earlyEnd:
		_change_state(GameState.ACCEPT_PROMPT)
		set_next_acted()
		turnComplete = true
	emit_signal("turn_order_updated", turnOrder)
	
func round_change():
	#Changes the round and reloads the "turn order" magazine
	earlyEnd = false
	_initialize_turns()
	boardState.clear_acted()
#	print(units)
	
	
func _initialize_turns():
	var groups = ["Player", "Enemy", "NPC"]
	turnOrder.clear()
	for cell in units: #grab unit locations
		var unit = units[cell]
		unit.set_acted(false)
		var uGroups = unit.get_groups()
		var gIndex = -1
		var i = 0
		while gIndex == -1:
			gIndex = uGroups.find(groups[i])
			i += 1
		match uGroups[gIndex]: #turn order initializing
			"Player": turnOrder.append("Player")
			"Enemy": turnOrder.append("Enemy")
			"NPC": turnOrder.append("NPC")
		_update_unit_terrain(unit) #update terrain data
	turnOrder = turnSort.sort_turns(turnOrder)
	aiTurn = false
	boardState.update_remaining_turns(turnOrder)
	emit_signal("turn_order_updated", turnOrder)
	print(turnOrder)

func set_next_acted():
	for cell in units:
		if !units[cell].status.Acted and units[cursorCell].FACTION_ID == Enums.FACTION_ID.PLAYER:
			units[cell].set_acted(true)
			return
	

func start_ai_turn():
	#Gets the ball rolling for the AI to take actions
	init_hexStar_terrain(false)
	if boardState.enemy.size() > 0:
		var result = ai.get_move(boardState)
		
		
		match result["Best Move"]["Action"]:
			"Attack": ai_attack(result)
			"Move": ai_move(result)
	else: turnComplete = true
		
	
#The next three functions process the AI's decided action based on which one is taken
##Attacking, Move without attacking; waiting in place
func ai_attack(result):
	var actor = result["Unit"]
	var target = result["Best Move"]["target"]
	var destination = Vector2i(result["Best Move"]["launch"])
	var weapon = result["Best Move"]["weapon"]
	var wInd = actor.unitData.Inv.find(weapon)
	var distance = hexStar.compute_cost(destination, target.cell, actor.moveType, false)
	_select_unit(actor.cell)
#	var closestCell = hexStar.find_closest(actor.cell, target.cell, actor.moveType, walkableCells)
	var path = get_path_to_cell(actor.cell, destination, actor.moveType)
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
	
	actor.set_equipped(wInd)
	actor.update_stats()
	combatManager.get_forecast(actor, target, distance)
	combatManager.start_the_justice(actor,target)
#	print(activeUnit)
	
	boardState.add_acted(activeUnit)
	activeUnit.set_acted(true)
	combat_sequence(activeUnit, target)
	
func ai_move(result):
	var actor = result["Unit"]
	var destination = Vector2i(result["Best Move"]["tile"])
	_select_unit(actor.cell)
	var path = get_path_to_cell(actor.cell, destination, actor.moveType)
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
	boardState.add_acted(actor)
	actor.set_acted(true)
	_deselect_active_unit(true)
	turnComplete = true
	
func ai_wait(result):
	var actor = result["Unit"]
	_select_unit(actor.cell)
	boardState.add_acted(actor)
	activeUnit.set_acted(true)
	_deselect_active_unit(true)
	turnComplete = true
	




func _on_combat_manager_combat_resolved():
	#Makes the map cursor visible again after combat manager signals that combat is over
	#Probably unecessary, would be better to move this to the turn change function, as cursor visibility in all other cases are handled else where
	#Left over from very early development
	_cursor_toggle(true, false)

func set_time_factor(effId, factor, duration, type):
	Global.timeFactor -= factor
	Global.timeFactor = clampf(Global.timeFactor, 0, 2)
	globalEffects[effId] = {}
	globalEffects[effId]["Type"] = type
	globalEffects[effId]["Factor"] = factor
	globalEffects[effId]["Duration"] = duration

func _progress_time():
	if Global.gameTime >= 24 - Global.timeFactor:
		var timeMod = Global.gameTime - 24
		timeMod += Global.timeFactor
		Global.gameTime = timeMod
	else: Global.gameTime += Global.timeFactor
	
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


func _on_combat_manager_warp_selected(actor, target, reach):
	warpTarget = target
	warp_targeting(actor, reach)

func on_exp_gained(oldExp, expSteps, results, portrait, unitName):
	emit_signal("exp_display", oldExp, expSteps, results, portrait, unitName)

	
	

func _first_available_dep_cell():
	var firstCell = null
	var filled = units.keys()
	for cell in deploymentCells:
		if !filled.has(cell):
			firstCell = cell
			break
		
	return firstCell

func _deploy_unit(unit, forced = false, spawnLoc = Vector2i(0,0)):
	var i = 0
	if !forced:
		spawnLoc = _first_available_dep_cell()
		i = 1
	if filledSlots < deploymentCells.size():
		unit.visible = true
		unit.relocate_unit(spawnLoc)
		filledSlots += i
		_update_roster_label()
	else:
		print("Roster Full")
	
func _undeploy_unit(unit, ini = false):
	var spawnLoc = Vector2i(0,0)
	if !unit.forced:
		unit.visible = false
		_remove_from_grid(unit)
		unit.relocate_unit(spawnLoc, false)
	else:
		print("Must deploy: " + unit.unitId)
	if !unit.forced and !ini:
		filledSlots -= 1
		_update_roster_label()

func _update_roster_label():
	emit_signal("deploy_toggled", filledSlots, deploymentCells.size())

			
			
func _cursor_toggle(enable, snapLeader = true): #lmao gay retard fix HERE
	var forcedUnits = forcedDeploy.keys()
	var leader = forcedUnits[0]
	
	
	
	
	if enable:
		cursor.visible = true
	else:
		cursor.visible = false
	if snapLeader:
		_snap_cursor()

func _snap_cursor(cell: Vector2i = unitObjs[forcedDeploy.keys()[0]].cell):
	cursorCell = cell
	cursor.align_camera()

#GUI Signal Functions
func _on_exp_gain_exp_finished():
	_change_state(GameState.LOADING)
	emit_signal("continue_turn")

	
func _on_gui_manager_start_the_justice(button):
	var i = button.get_meta("index")
	activeUnit.set_equipped(i)
	_change_state(GameState.LOADING)
	combatManager.start_the_justice(activeUnit, focusUnit) #Why is durability going down by 2??
	boardState.add_acted(activeUnit)
	activeUnit.set_acted(true)
	combat_sequence(activeUnit, focusUnit)
#	mainCon.state = GameState.GB_DEFAULT

func _on_win_screen_win_finished():
	_change_state(GameState.LOADING)
	change_map(currMap.next_map)
	#currMap.progress_next_map()
	#self.call_deferred("_load_next_map")
	
func _on_gui_manager_deploy_toggled(unit, deployed):
#	var unit = unitObjs[unitId]
	if deployed:
		_undeploy_unit(unit)
	else:
		_deploy_unit(unit)

func _on_gui_manager_formation_toggled():
	match mainCon.state:
		GameState.GB_SETUP:
			_cursor_toggle(true, true)
			mainCon.newSlave = [self]
			mainCon.state = GameState.GB_FORMATION
		GameState.GB_FORMATION:
			_cursor_toggle(false)
	
func _on_gui_manager_item_used(unit, item):
	combatManager.use_item(unit, item)

func _on_gui_manager_map_started():
	for unit in units:
		units[unit].map_start_init()
	_cursor_toggle(true)
	currMap.hide_deployment()
	_change_state(GameState.GB_DEFAULT)
	_initialize_turns()
	

func _on_action_menu_action_selected(selection, skillId = null):
	lastSkill = skillId #lastSkill?????????????????
	match selection:
		"Attack": 
			
			attack_targeting(activeUnit)
		"Skill": 
			
			attack_targeting(activeUnit, skillId)
		"Wait": 
			_change_state(GameState.GB_DEFAULT)
			_deselect_active_unit(true)
			turnComplete = true
#			Input.warp_mouse(currMap.map_to_local(activeUnit.position))
		"End":
			_change_state(GameState.GB_ROUND_END)
			earlyEnd = true
			turnComplete = true

func _on_action_menu_weapon_changed(button):
	var i = button.get_meta("index")
	var distance = hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit.unitData.MoveType, false)
	var cmbData
	activeUnit.set_temp_equip(i)
	cmbData = combatManager.get_forecast(activeUnit, targetUnit, distance)
	emit_signal("cmbData_updated", cmbData)
	
	

#Objective related code
func _check_flags():
	var flags = Global.flags
	
	if flags.gameOver: #consider saving reason for loss in later versions
		emit_signal("player_lost")
		
	if flags.victory:
		emit_signal("player_win")
		
func _reset_map_flags():
	Global.flags.gameOver = false
	Global.flags.victory = false
	
	
#Debug Functions
func _kill_lady():
	var lady = unitObjs["Remilia"]
	lady.apply_dmg(9999)

