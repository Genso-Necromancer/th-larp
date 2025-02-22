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
signal unit_selected(unit:Unit)
signal unit_move_ended(unit:Unit)
signal unit_deselected
signal sequence_concluded
signal sequence_initiated(sequence:Dictionary)
signal post_queue_cleared
signal continue_queue
signal danmaku_pathing_complete


signal map_loaded(map)
signal skill_target_canceled
signal forecast_confirmed
signal time_set


signal toggle_prof
signal toggle_skills
signal target_focused
signal aimove_finished
signal turn_changed
signal round_changed
signal exp_display
signal continue_turn
signal deploy_toggled
signal formation_closed
signal gb_ready
signal turn_order_updated

enum ACTION_TYPE {ATTACK, SKILL, WAIT, END}

@onready var yaBoy = $"."
# Mapping locations of units and danmaku {cell:node}
var units := {} 
var danmaku := {}
var danmakuMotion := []
var collisionQue := []


#these are used to store references to actual units that are passed around this class and those it controls
var focusUnit : Unit :
	set(value):
		focusUnit = value
		Global.focusUnit = focusUnit
		
var aiTarget : Unit :
	set(value):
		aiTarget = value
		Global.aiTarget = aiTarget
		
var activeUnit: Unit :
	set(value):
		activeUnit = value
		Global.activeUnit = activeUnit
		
var targetUnit : Unit
var sequencingUnits = {}


#set up variables
var forcedDeploy : Dictionary
var deploymentCells : Array
var depCap : int = 0
var filledSlots : int = 0
var storedUnit : Unit
var storedCell : Vector2i = Vector2i(-1,-1)

#variables related to the active map in use
var currMap: GameMap
var warpTarget
var deathList = []
var turnLoss = []

#Units by UnitID
var unitObjs : Dictionary = Global.unitObjs

@onready var parent = get_parent()
@onready var mainCon = parent.get_parent()

#states
@onready var GameState = mainCon.GameState




#ready() is the gayest fucking shit ever
var defineUnits = false

#related to pathfinding
#var hexStar: AHexGrid2D #HEX REF
var walkableCells = []
var solidsArray = [] #Deprecated, remove after fixing FIX
var unitMoving = false
var snapPath = null
var pathingArray := []

#game turns
var turnOrder = []
var roundCounter = 0
var turnCounter = 0
var maxTurns = 0
var earlyEnd = false

#Turn/Round variables
var turnComplete := false
var endOfRound := false
var startNextTurn := false


#Global effects
var globalEffects = {}




#unit variables
var activeAction
var postQueue = []

#controls pseudo UI elements, like HP bars
var HpBarVis = true

#AI Variables
var aiTurn = false
var aiNeedAct = false

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
var unitScn := preload("res://scenes/Unit.tscn")

#cursor location
var cursorCell := Vector2i.ZERO:
	set(value):
		if value == cursorCell:
			return
		cursorCell = region_clamp(value)

		cursor.position = currMap.map_to_local(cursorCell)
		cursor.cell = cursorCell
#		print(cursor.position)
		_on_cursor_moved(cursorCell)
#		cTimer.start()

	
func _process(_delta):
	_check_flags()
	
	if deathList.size() > 0 and turnComplete:
		_wipe_dead()
	elif endOfRound:
		_check_eor_events()
	elif collisionQue.size() > 0 and mainCon.state == GameState.GB_END_OF_ROUND:
		_pause_danmaku_phase()
		_process_danmaku_collision()
	elif collisionQue.size() == 0 and danmakuMotion.size() == 0 and mainCon.state == GameState.GB_END_OF_ROUND:
		emit_signal("danmaku_pathing_complete")
	elif mainCon.state == GameState.ACCEPT_PROMPT or mainCon.state == GameState.FAIL_STATE or mainCon.state == GameState.WIN_STATE or mainCon.state == GameState.GB_END_OF_ROUND:
		pass
	elif turnComplete:
		turnComplete = false
		
		_post_turn_events()
	elif startNextTurn:
		startNextTurn = false
		_start_next_turn()
	elif aiTurn and aiNeedAct:
		start_ai_turn(turnOrder[0])
			
		
func _toggle_pause():
	get_tree().paused = !get_tree().paused
	
#func _on_jobs_done(id, node):
	#match id:
		#"Cursor": 
			#cursor = node
			
#Map Functions
func _get_current_map():
	for mapChild in get_children(): #mapchild
		var map := mapChild as GameMap
		if not map:
			continue
		return map
		
	
func _change_state(state):
	var prev = mainCon.previousSlave
	mainCon.previousSlave = mainCon.newSlave
	if state == mainCon.state:
		return
	elif state == mainCon.previousState:
		mainCon.newSlave = prev
	else:
		mainCon.newSlave = [self]
	
	mainCon.previousState = mainCon.state
	mainCon.state = state
	
	
func change_map(map):
	_reset_map_flags()
	turnComplete = false # find a better place to reinitialize this and above value HERE
	if currMap:
		currMap.queue_free()
		await currMap.tree_exited
	call_deferred("_load_new_map", map)
		
		
func _load_new_map(map):
	var newMap = map.instantiate()
	Global.timePassed = 0
	add_child(newMap)
	
	
func on_map_ready():
	call_deferred("_initialize_new_map")
	
#func on_map_gone():
	#self.call_deferred("_initialize_new_map")
	
func _initialize_new_map():
	_connect_general_signals()
	currMap = _get_current_map()
	#_initialize_terrain_data()
	#_initialize_hexstar() #HEX REF
	units.clear()
	_set_game_time()
	_store_enemy_units()
	_load_units()
	_init_gamestate()
	combatManager.init_manager()
	ai.init_ai()
	_cursor_toggle(true)
	_cursor_toggle(false)
	emit_signal("map_loaded", currMap)
	
#func _initialize_terrain_data():
	#terrainData.clear()
	#var tiles0 = currMap.get_used_cells(0) #terrainData
	#for tile in tiles0: 
		#terrainData.append([tile, currMap.get_movement_cost(tile), currMap.get_bonus(tile)])
	
#func _initialize_hexstar() ->: #HEX REF
	#mapRect = currMap.get_used_rect() #initializing hexStar
	#mapSize = mapRect.size
	##mapCellSize = currMap.tileSize
	#
	##start up pathfinder
	#hexStar = AHexGrid2D.new(currMap)
	##hexStar.tileSize = mapCellSize
	
#func get_hex_star() -> AHexGrid2D: #HEX REF
	#return hexStar
	
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
		_connect_unit_signals(unit)
		#if !self.turn_changed.is_connected(unit.on_turn_changed): #unit signals
			#self.turn_changed.connect(unit.on_turn_changed)
		#if !unit.unit_relocated.is_connected(self.on_unit_relocated): 
			#unit.unit_relocated.connect(self.on_unit_relocated)
		#if !unit.turn_complete.is_connected(self.on_turn_complete):
			#unit.turn_complete.connect(self.on_turn_complete)
#		if !unit.exp_gained.is_connected(self.on_exp_gained):
#			unit.exp_gained.connect(self.on_exp_gained)
		_update_unit_terrain(unit) #update terrain data
		
func _load_units(): #merge with store enemy units
	
	var roster = UnitData.rosterData
	#var spawnLoc
	filledSlots = 0
	deploymentCells = currMap.get_deployment_cells()
	forcedDeploy = currMap.get_forced_deploy()
	depCap = deploymentCells.size() + forcedDeploy.size()
	var forcedUnits = forcedDeploy.keys()
	
	
	for unit in roster:
		var newUnit = unitScn.instantiate().init_unit(currMap, true, Enums.FACTION_ID.PLAYER, unit)
		currMap.add_child(newUnit)
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
		elif isPlayable and filledSlots < depCap:
			_deploy_unit(unit)
		elif isPlayable and filledSlots >= depCap:
			_undeploy_unit(unit, true)
	
		if !isPlayable:
			unit.init_unit(currMap,)
			units[unit.cell] = unit
			unitObjs[unit.unitId] = unit
			
		_update_unit_terrain(unit)
		unit.set_process(true)
	
	_update_roster_label()
	


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
	if !self.sequence_concluded.is_connected(unit.on_sequence_concluded):
		self.sequence_concluded.connect(unit.on_sequence_concluded)
	if !unit.turn_complete.is_connected(self.on_turn_complete):
			unit.turn_complete.connect(self.on_turn_complete)
	if !unit.effect_complete.is_connected(self.on_effect_complete):
		unit.effect_complete.connect(self.on_effect_complete)
	if !unit.item_targeting.is_connected(self._on_unit_item_targeting):
		unit.item_targeting.connect(self._on_unit_item_targeting)
	if !unit.item_activated.is_connected(self._on_unit_item_activated):
		unit.item_activated.connect(self._on_unit_item_activated)

func _connect_danmaku_signals(bullet):
	if !bullet.danmaku_relocated.is_connected(self.on_danmaku_relocated):
		bullet.danmaku_relocated.connect(self.on_danmaku_relocated)
	if !bullet.collision_detected.is_connected(self.on_danmaku_collision):
		bullet.collision_detected.connect(self.on_danmaku_collision)
	if !bullet.animation_completed.is_connected(self._on_danmaku_animation):
		bullet.animation_completed.connect(self._on_danmaku_animation)

func _set_game_time():
	Global.gameTime = currMap.gameTime #setting game time
	emit_signal("time_set")
	checkSun()
	
	
func _connect_general_signals():
	self.gb_ready.connect(mainCon.set_new_state)
	
	#self.danmaku_pathing_complete.connect()
	#self.round_changed.connect(currMap.on_round_changed)
	#self.cell_selected.connect(mainCon.on_cell_selected)
	
func checkSun():
	if Global.gameTime >= 6.0 and Global.gameTime <= 18.0:
		Global.timeOfDay = Enums.TIME.DAY
	else:
		Global.timeOfDay = Enums.TIME.NIGHT
	for unit in units:
		units[unit].check_passives()
		#if units[unit] != null:
			#units[unit].check_passives()
		#else: units.erase(unit)
		
func _init_gamestate():
	#boardState.update_map_data(terrainData)
	boardState.update_unit_data(units)
	
	
func _update_unit_terrain(unit): #HERE BROKEN
	unit.update_terrain_data()
	
			
			
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
##SHIT DONT WORK FOR FUCK
func get_region_rect(region: Array) -> Rect2i:
	var minPos = Vector2i.MAX
	var maxPos = Vector2i.MIN
	
	for hex in region:
		minPos = _minv(minPos, hex)
		maxPos = _maxv(maxPos, hex)
	
	#for hex in region:
		#minPos.x = min(minPos.x, hex.x)
		#minPos.y = min(minPos.y, hex.y)
		#maxPos.x = max(maxPos.x, hex.x)
		#maxPos.y = max(maxPos.y, hex.y)
	var rectSize = maxPos - minPos
	var rect = Rect2i(minPos, rectSize)
	#var exp = Vector2i(maxPos.x+1,maxPos.y+1)
	#rect = rect.expand(exp)
	return rect


func _maxv(a:Vector2i, b:Vector2i) -> Vector2i:
	var al = a.length()
	var bl = b.length()
	
	return b if a < b else a
	

func _minv(a:Vector2i, b:Vector2i) -> Vector2i:
	var al = a.length()
	var bl = b.length()
	
	return b if a > b else a


func get_walkable_cells(unit: Unit) -> Array: #Pathing
	var hexStar = AHexGrid2D.new(currMap)
	var path = hexStar.find_all_unit_paths(unit)
	
	return path


func _update_walkable_range(moveRemain:int = 0):
	var hexStar = AHexGrid2D.new(currMap)
	var newArea :Array = hexStar.find_remaining_unit_paths(activeUnit, pathingArray[-1], moveRemain)
	unitOverlay.clear()
	unitOverlay.draw(newArea)


func _update_pathing_array(wayPoint:Vector2i): #Pathing
	var path := []
	var start : Vector2i = activeUnit.cell
	if pathingArray: start = pathingArray[-1]
	path = get_path_to_cell(start, wayPoint, activeUnit)
	pathingArray.append_array(path)
	
	
func get_path_to_cell(start:Vector2i, end:Vector2i, unit = false): #Pathing
	var hexStar = AHexGrid2D.new(currMap)
	return hexStar.find_path(start, end, unit) #HEX REF


func is_within_bounds(cell_coordinates: Vector2i) -> bool: #Pathing
	#Keeps the map cursor in bounds
	var mapSize = currMap
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
		

func _move_active_unit(new_cell: Vector2i, enemy: bool = false, enemyPath = null) -> void: #pathing related
	# Updates the units dictionary with the target position for the unit and asks the activeUnit to walk to it.
#	print("move_active: ", new_cell)
	var path = null
	if !new_cell == activeUnit.cell and !enemy:
		if is_occupied(new_cell) or not new_cell in walkableCells:
			return
	
	if !enemy:
		_change_state(GameState.ACCEPT_PROMPT)
	
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
		pathingArray.clear()
		unitMoving = false
		
		
	if !enemy:
		_change_state(GameState.GB_ACTION_MENU)
		emit_signal("unit_move_ended", activeUnit)
	else:
		emit_signal("aimove_finished")



func _select_unit(cell: Vector2i, isAi = false) -> void:
	# Selects the unit in the `cell` if there's one there.
	# Sets it as the `activeUnit` and draws its walkable cells and interactive move path. 
#	#print(units, units.has(cell))
#	print(cell)
	if !units.has(cell): return
	activeUnit = units[cell]
	#activeUnit.save_equip()
	activeUnit.is_selected = true
	walkableCells = get_walkable_cells(activeUnit)
	
	unitOverlay.draw(walkableCells)
	if !isAi: _change_state(GameState.GB_SELECTED)
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
	pathingArray.clear()
	
	
func on_unit_relocated(oldCell, newCell, unit): #updates unit locations with it's new location
	if units.has(oldCell):
		units.erase(oldCell)
	units[newCell] = unit


func on_danmaku_relocated(oldCell, newCell, bullet): #updates unit locations with it's new location
	var hexStar = AHexGrid2D.new(currMap)
	if danmaku.has(oldCell):
		danmaku.erase(oldCell)
	danmaku[newCell] = bullet
	bullet.set_path(hexStar.get_danmaku_path(bullet)) #HEX REF
	if danmakuMotion.has(bullet):
		danmakuMotion.erase(bullet)


func on_danmaku_collision(bullet):
	collisionQue.append(bullet)
	#if danmakuMotion.has(bullet):
		#danmakuMotion.erase(bullet)


func _on_danmaku_animation(anim, bullet):
	match anim:
		"Collision": 
			_remove_danmaku(bullet)
			_process_danmaku_collision()


func _pause_danmaku_phase():
	set_process(false)
	for b in danmakuMotion:
		if b.isMoving: b.pause_move()


func _remove_danmaku(bullet):
	var keys = danmaku.keys()
	if keys.has(bullet.originCell):
		danmaku.erase(bullet.originCell)
	if danmakuMotion.has(bullet):
		danmakuMotion.erase(bullet)
	bullet.queue_free()


func _process_danmaku_collision():
	if collisionQue.size() == 0:
		_resume_danmaku_phase()
		return
	var bullet = collisionQue.pop_front()
	_snap_cursor(bullet.cell)
	bullet.play_collide()


func _resume_danmaku_phase():
	set_process(true)
	for b in danmakuMotion:
		b.start_move()


func grab_target(cell): #HERE Add "Action" compatability
	#Called to assign values based on unit at cursor's coordinate
	var hexStar = AHexGrid2D.new(currMap)
	if not units.has(cell):
		print("oops")
		return
	var mode : int
	targetUnit = units[cell]
	var distance := hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit) #HEX REF
	var reach := [distance, distance]
	if activeAction.Weapon:
		combatManager.get_forecast(activeUnit, targetUnit, activeAction)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mode = 0
	else:
		combatManager.get_forecast(activeUnit, targetUnit, activeAction)
		mode = 1
	emit_signal("target_focused", mode, reach)
			

		
func _clear_active_unit() -> void:
	# Clears the reference to the activeUnit and the corresponding walkable cells
	
	activeUnit = null
	walkableCells.clear()


func select_destination(): #SELECTED STATE Pathing Related
	var isOccupied = is_occupied(cursorCell)
	var isWalkable = walkableCells.has(cursorCell)
	var moveRemain :int = activeUnit.activeStats.Move - pathingArray.size()
	if !isOccupied and isWalkable and moveRemain > 0 and !pathingArray.has(cursorCell):
		_update_pathing_array(cursorCell)
		moveRemain = activeUnit.activeStats.Move - pathingArray.size()
		_update_walkable_range(moveRemain)
	elif pathingArray[-1] == cursorCell:
		_move_active_unit(cursorCell)
	elif cursorCell == activeUnit.cell:
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
		emit_signal("toggle_prof")
	elif focusUnit:
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
	if is_occupied(cursorCell) and !_check_friendly(activeUnit, focusUnit):
		_change_state(GameState.GB_COMBAT_FORECAST)
#				$Cursor.visible = false
		grab_target(cursorCell)
		
func confirm_forecast():
	emit_signal("forecast_confirmed")
		
func skill_target_selected():
	if !is_occupied(cursorCell):
		return
	if !UnitData.skillData.has(activeAction.Skill):
		print("No Valid SkillID")
		return
	var friendly := false
	var valid := false
	var skill = UnitData.skillData[activeAction.Skill]
	
	if focusUnit.FACTION_ID == activeUnit.FACTION_ID or focusUnit.FACTION_ID == Enums.FACTION_ID.NPC:
		friendly = true
	match skill.Target:
		"Self":
			if activeUnit == focusUnit:
				valid = true
		"Enemy":
			if !friendly:
				valid = true
			#if skill.RuleType:
				#match skill.RuleType:
					#Enums.RULE_TYPE.TARGET_SPEC:
						#if skill.Rule != focusUnit.SPEC_ID:
							#valid = false
		"Ally":
			if friendly and activeUnit != focusUnit:
				valid = true
		"Self+":
			if friendly:
				valid = true
		"Other":
			if activeUnit != focusUnit:
				valid = true
				
	
					
	if valid:
		_change_state(GameState.GB_COMBAT_FORECAST)
		grab_target(cursorCell)

func _check_friendly(unit1, unit2) ->bool:
	if unit1.FACTION_ID == unit2.FACTION_ID:
		return true
	elif unit1.FACTION_ID != Enums.FACTION_ID.ENEMY and unit2.FACTION_ID != Enums.FACTION_ID.ENEMY:
		return true
	return false


func return_targeting():
	#var s
	emit_signal("menu_canceled")
	match mainCon.previousState:
		GameState.GB_ATTACK_TARGETING: 
			#s = "Attack"
			activeUnit.restore_equip()
			attack_targeting(activeUnit, activeAction)
		GameState.GB_SKILL_TARGETING:
			attack_targeting(activeUnit, activeAction)
			
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
			var targeting = UnitData.skillData[activeAction.Skill].Target
			if activeUnit.is_in_group("Player"):
				team = "Player"
			if activeUnit.is_in_group("Enemy"):
				team = "Enemy"
			match targeting:
				"Self":
					if is_occupied(cell) and activeUnit == focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell)
				"Enemy":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and !friendly:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell)
				"Ally":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly and activeUnit != focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell)
				"Self+":
					if focusUnit.is_in_group(team):
						friendly = true
					if is_occupied(cell) and friendly:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell)
				"Other":
					if is_occupied(cell) and activeUnit != focusUnit:
						mainCon.state = GameState.GB_COMBAT_FORECAST
#						$Cursor.visible = false
						grab_target(cell)
	



func _on_cursor_moved(new_cell: Vector2i) -> void: #Pathing
	# Updates the dynamic visual path if there's an active and selected unit.
#	print(currMap.map_to_local(new_cell))
#	print(new_cell)
	
	var area = get_region_rect(walkableCells)
	var path := []
	
	area = area.abs()
	
	if units.has(new_cell) and units[new_cell] == null: #safety measure, catches any uncleared cell storage that slips through the cracks
		units.erase(new_cell)
	
	if !activeUnit or !activeUnit.is_selected or mainCon.state != GameState.GB_SELECTED:
		return
	elif pathingArray and walkableCells.has(new_cell):
		path = pathingArray + get_path_to_cell(pathingArray[-1], new_cell, activeUnit)
	elif walkableCells.has(new_cell):
		path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit)
	elif new_cell == activeUnit.cell:
		unitPath.clear()
	else:
		return
		
	unitPath.draw(path)


func on_directional_press(direction: Vector2i):
	var nextCell = cursorCell + direction
	var newCell
	
	if mainCon.state == GameState.GB_PROFILE:
		return
		
	if snapPath != null and !snapPath.has(nextCell):
		newCell = find_next_best_cell(cursorCell, nextCell)
		cursorCell = newCell
	else: cursorCell += direction

#Targeting Code
func attack_targeting(unit: Unit, action): 
	var minRange := 1000
	var maxRange := 0
	var wepData :Dictionary = UnitData.itemData
	var skillData = UnitData.skillData
	var isAugment := false
	activeAction = action
			
	if action.Weapon and action.Skill:
		var reach = _get_aug_range(unit, action)
		minRange = reach[0]
		maxRange = reach[1]
		_change_state(GameState.GB_ATTACK_TARGETING)
	elif action.Skill:
		minRange = skillData[action.Skill].RangeMin
		maxRange = skillData[action.Skill].RangeMax
		_change_state(GameState.GB_SKILL_TARGETING)
	else:
		for wep in unit.unitData.Inv:
			if wep.Dur == 0:
				continue
			minRange = min(minRange, wepData[wep.ID].MinRange, minRange)
			maxRange = max(maxRange, wepData[wep.ID].MaxRange, maxRange)
		if  unit.unitData.Weapons.Sub and unit.unitData.Weapons.Sub.has("NATURAL"):
			var id = unit.natural.ID
			minRange = min(minRange, wepData[id].MinRange, minRange)
			maxRange = max(maxRange, wepData[id].MaxRange, maxRange)
			
		_change_state(GameState.GB_ATTACK_TARGETING)
	
	_draw_range(unit, maxRange, minRange)

func _get_aug_range(unit, action) -> Array:
	var minRange := 1000
	var maxRange := 0
	var reach := []
	var skill = UnitData.skillData[action.Skill]
	var wepData :Dictionary = UnitData.itemData
	if skill.RangeMin == 0 or skill.RangeMax == 0:
		for wep in unit.unitData.Inv:
			if wep.Dur == 0:
				continue
			minRange = min(minRange, wepData[wep.ID].MinRange, minRange)
			maxRange = max(maxRange, wepData[wep.ID].MaxRange, maxRange)
	else:
		minRange = skill.RangeMin
		maxRange = skill.RangeMax
	reach.append(minRange)
	reach.append(maxRange)
	return reach
		


func warp_targeting(unit, wRange):
	_draw_range(unit, wRange)
	_change_state(GameState.GB_WARP)
	
func _draw_range(unit : Unit, maxRange : int, minRange := 0):
	
	#draws a visual representation of a unit's attack range, and binds the cursor within this space(snapPath)
	#var path = hexStar.find_all_paths(unit.cell, maxRange,)
	#if path.size() != 1 and minRange > 0:
		#minRange = minRange - 1
		#minRange = clampi(minRange, 0, 1000)
		#var invalid = hexStar.find_all_paths(unit.cell, minRange,)
		#path = hexStar.trim_path(path, invalid) #HEX REF
	var path = _get_cells_in_range(unit.cell, maxRange, minRange,)
	snapPath = path
	bump_cursor()
	unitOverlay.draw_attack(path)
	unitPath.stop()
	
func _get_cells_in_range(cell : Vector2i, maxRange : int, minRange : int): #HEX REF
	var hexStar = AHexGrid2D.new(currMap)
	var path = hexStar.find_all_paths(cell, maxRange)
	if path.size() != 1 and minRange > 0:
		minRange = minRange - 1
		minRange = clampi(minRange, 0, 1000)
		var invalid = hexStar.find_all_paths(cell, minRange)
		path = hexStar.trim_path(path, invalid)
	return path
	
func initiate_warp():
	#var friendly = false
#	var team = null
	if !is_occupied(cursorCell) and !solidsArray.has(cursorCell) and snapPath.has(cursorCell):
		combatManager.warp_to(warpTarget, cursorCell)
		combat_sequence("warp")
		warpTarget = null

#actions code
func _on_unit_item_targeting(item, unit):
	#combatManager.use_item(unit, unit, item)
	pass


func _on_unit_item_activated(item, unit, target):
	var results = combatManager.use_item(unit, unit, item)
	

func combat_sequence(scenario):
	_change_state(GameState.ACCEPT_PROMPT)
	
	emit_signal("sequence_initiated", scenario)

func _on_animation_handler_sequence_complete():
	var hasPostEvents = _check_post_queue()
	_change_state(GameState.LOADING)
	
	if hasPostEvents:
		_run_post_queue()
		await self.post_queue_cleared
	emit_signal("sequence_concluded")
	wipe_region()
	
	
func _run_post_queue():
	var postEvents = _sort_post_queue()
	var eventKeys
	var type = Enums.EFFECT_TYPE
	eventKeys = postEvents.keys()
	for actor in eventKeys:
		for event in postEvents[actor]:
			var t = event.Type
			var effect = UnitData.effectData[event.EffectId]
			var target = event.Target
			var isWait = true
			match t:
				type.RELOC:
					combatManager.start_relocation(actor, target, effect)
				_: isWait = false
			if isWait:
				await self.continue_queue
		
	_clear_post_queue()

func on_effect_complete():
	emit_signal("continue_queue")

func _sort_post_queue():
	var seen := {}
	var postEvents := {}
	for event in postQueue:
		if !postEvents.has(event.Actor):
			postEvents[event.Actor] = []
			seen[event.Actor] = []
		if seen[event.Actor].has(event.Type):
			continue
		else:
			seen[event.Actor].append(event.Type)
			postEvents[event.Actor].append(event)
	return postEvents


func _check_post_queue() -> bool:
	if postQueue.size() > 0:
		return true
	return false


func add_post_queue(new):
	postQueue.append(new)


func _clear_post_queue():
	postQueue.clear()
	emit_signal("post_queue_cleared")


func on_turn_complete(unit):
	#and mainCon.state != GameState.GB_END_OF_ROUND
	if sequencingUnits.has(unit):
		sequencingUnits[unit] = false
	else: return
	for u in sequencingUnits:
		if sequencingUnits[u]:
			return
	sequencingUnits.clear()
	_deselect_active_unit(true)
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
	var mapSize = currMap.get_used_rect().size
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
	var hexStar = AHexGrid2D.new(currMap)
	if !snapPath.has(cursorCell):
		seek = true
	if seek:
		for cell in snapPath:
			var distance = hexStar.find_distance(cursorCell, cell)
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
	var hexStar = AHexGrid2D.new(currMap)
	for cell in snapPath:
		var distanceNext = hexStar.find_distance(nextCell, cell)
		var distanceCurrent= hexStar.find_distance(currentCell, cell)
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
	var addingExp = false
	if unit.FACTION_ID == Enums.FACTION_ID.ENEMY:
		var killer = unit.killer
		addingExp = killer.add_exp("Kill", unit)
		
	if addingExp:
		await self.continue_turn
		unit.confirm_post_sequence_flags("Death")
	else:
		unit.confirm_post_sequence_flags("Death")
	deathList.append(unit)
	currMap.check_event("Death", unit)
	
	
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
	var factionId = unit.FACTION_ID
	_remove_turn(factionId)
	units.erase(remove)
	unit.queue_free()
	#clear non-player units from unitData HERE!!!
	
func _remove_from_grid(unit: Unit):
	var remove = unit.cell
	if units.has(remove):
		units.erase(remove)
	
#turn functions
func _post_turn_events():
	
	_progress_time()
	checkSun()
	currMap.call_deferred("check_events")
	await currMap.events_checked
	turn_change()
		
	
	
func turn_change():
	#change turn
#	ai.rein_units(units)
	boardState.update_unit_data(units)
	turnOrder.pop_front()
	turnCounter += 1
	
	
	if turnOrder.size() == 0:
		round_change()
	else:
		startNextTurn = true
	boardState.update_remaining_turns(turnOrder)
	print(turnOrder)
	emit_signal("turn_changed")
	emit_signal("turn_order_updated", turnOrder)
	

func _start_next_turn():
	
	if turnOrder[0] == "Enemy":
		mainCon.state = GameState.LOADING
		aiTurn = true
		aiNeedAct = true
		print("Enemy Turn")
		_cursor_toggle(false)
	elif turnOrder[0] == "Player":	
		mainCon.state = GameState.GB_DEFAULT
		aiTurn = false
		print("Player Turn")
		_cursor_toggle(true)
	elif turnOrder[0] == "NPC": #Currently, NPC turns aren't a feature of the AI
		mainCon.state = GameState.LOADING
		aiTurn = true
		print("NPC Turn")
		_cursor_toggle(false)

	if !aiTurn and earlyEnd:
		_change_state(GameState.LOADING)
		set_next_acted()
		turnComplete = true
	

func _add_turn(faction):
	var team : String

	match faction:
		Enums.FACTION_ID.PLAYER: team = "Player"
		Enums.FACTION_ID.ENEMY: team = "Enemy"
		Enums.FACTION_ID.NPC: team = "NPC"
		
	turnOrder.append(team)
	emit_signal("turn_order_updated", turnOrder)
	
func _remove_turn(factionId):
	var faction : String
	print("Before Removed Turn:",turnOrder)
	match factionId:
		Enums.FACTION_ID.PLAYER: faction = "Player"
		Enums.FACTION_ID.ENEMY: faction = "Enemy"
		Enums.FACTION_ID.NPC: faction = "NPC"
	if turnOrder[0] != faction:
		var i = turnOrder.rfind(faction)
		turnOrder.remove_at(i)
	print("Removed Turn:",faction, ":",turnOrder)
	emit_signal("turn_order_updated", turnOrder)
	
func round_change():
	#Changes the round and reloads the "turn order" magazine
	#Return HERE to make sure turns flow properly, I can already see conflicting issues cropping up
	earlyEnd = false
	_initialize_turns()
	boardState.clear_acted()
	round_duration_tick() #Outdated! Just handles global time effect durations! Doesn't utilize new skill system, or duration types! SHOULD CHECK UNIT'S VERSION OF THIS, TOO.
	endOfRound = true
	emit_signal("round_changed")
#	print(units)
	
func _check_eor_events():
	endOfRound = false
	_change_state(GameState.GB_END_OF_ROUND)
	if danmaku.size() > 0:
		_progress_danmaku_path()
		await self.danmaku_pathing_complete
	currMap.progress_danmaku_script()


func _on_danmaku_progressed():
	_start_next_turn()
	
func _initialize_turns(ignoreActed = false): #not quite right Groups might be the problem, just use faction ID
	var groups = ["Player", "Enemy", "NPC"]
	turnOrder.clear()
	for cell in units: #grab unit locations
		var unit = units[cell]
		if ignoreActed and unit.status.Acted:
			continue
		else: unit.set_acted(false)
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
		if !units[cell].status.Acted and units[cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
			units[cell].set_acted(true)
			return
	

func start_ai_turn(aiFaction):
	print("Starting AI Turn")
	aiNeedAct = false
	_change_state(GameState.GB_AI_TURN)
	#Gets the ball rolling for the AI to take actions
	if boardState.enemy.size() > 0:
		var result = ai.get_move(boardState)
		print_rich("[color=green]AI MOVE[/color]:",result)
		match result.BestMove["Action"]:
			"Attack": ai_attack(result)
			"Move": ai_move(result)
			"Wait": ai_wait(result)
	else: turnComplete = true
	
#The next three functions process the AI's decided action based on which one is taken
##Attacking, Move without attacking; waiting in place
func ai_attack(result): #HERE..... EVENTUALLY. So fuckin out of date.
	var actor = result["Unit"]
	var target = result.BestMove["Target"]
	var destination = Vector2i(result.BestMove["Launch"])
	var weapon = result.BestMove["Weapon"]
	var skill = result.BestMove.Skill
	var wInd = actor.unitData.Inv.find(weapon)
	#var combatResults
	var path = get_path_to_cell(actor.cell, destination, actor)
	activeUnit = actor
	aiTarget = target
	activeAction = {"Weapon": weapon, "Skill": skill}
	actor.set_equipped(wInd)
	_select_unit(actor.cell, true)
#	var closestCell = hexStar.find_closest(actor.cell, target.cell, actor.unitData.MoveType, walkableCells)
	
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
		
	actor.update_stats()
	
	combatManager.get_forecast(actor, target, activeAction)
	
#	print(activeUnit)
	emit_signal("target_focused", 2)
	#Need to call up the forecast in a specific enemy AI mode.
	#Then have a timer, or player input trigger the following code.
	#combatResults = combatManager.start_the_justice(actor,target, activeAction)
	#combat_sequence(combatResults)
	#boardState.add_acted(activeUnit)
	#activeUnit.set_acted(true)
	
	
func ai_move(result):
	var actor = result["Unit"]
	var destination = Vector2i(result.BestMove["tile"])
	_select_unit(actor.cell)
	var path = get_path_to_cell(actor.cell, destination, actor)
	if actor.cell != destination:
		_move_active_unit(destination, true, path)
		await self.aimove_finished
	
	boardState.add_acted(actor)
	#actor.set_acted(true)
	_deselect_active_unit(true)
	turnComplete = true
	
func ai_wait(result):
	var actor = result["Unit"]
	_select_unit(actor.cell)
	boardState.add_acted(actor)
	#activeUnit.set_acted(true)
	_deselect_active_unit(true)
	turnComplete = true
	




func _on_combat_manager_combat_resolved():
	#Makes the map cursor visible again after combat manager signals that combat is over
	#Probably unecessary, would be better to move this to the turn change function, as cursor visibility in all other cases are handled else where
	#Left over from very early development
	_cursor_toggle(true, false)

func set_time_factor(effId):
	var effect = UnitData.effectData[effId]
	match effect.SubType:
		Enums.SUB_TYPE.SPEED_UP: Global.timeFactor += effect.Value
		Enums.SUB_TYPE.SLOW_DOWN: Global.timeFactor -= effect.Value
	Global.timeFactor = clampf(Global.timeFactor, 0, 2)
	globalEffects[effId] = {}
	globalEffects[effId]["Type"] = effect.SubType
	globalEffects[effId]["Factor"] = effect.Value
	globalEffects[effId]["Duration"] = effect.Duration

func _progress_time():
	if Global.gameTime >= 24 - Global.timeFactor:
		var timeMod = Global.gameTime - 24
		timeMod += Global.timeFactor
		Global.gameTime = timeMod
	else: Global.gameTime += Global.timeFactor
	Global.timePassed += Global.timeFactor
	
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


func _on_combat_manager_time_factor_changed(effId):
	set_time_factor(effId)


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
	if !forced:
		spawnLoc = _first_available_dep_cell()
	if filledSlots < depCap:
		unit.visible = true
		unit.isActive = true
		unit.relocate_unit(spawnLoc)
		filledSlots += 1
		_update_roster_label()
	else:
		print("Roster Full")
	
func _undeploy_unit(unit, ini = false):
	var spawnLoc = Vector2i(0,0)
	if !unit.forced:
		unit.visible = false
		unit.isActive = false
		_remove_from_grid(unit)
		unit.relocate_unit(spawnLoc, false)
	else:
		print("Must deploy: " + unit.unitId)
	if !unit.forced and !ini:
		filledSlots -= 1
		_update_roster_label()

func _update_roster_label():
	print(filledSlots)
	emit_signal("deploy_toggled", filledSlots)

			
			
func _cursor_toggle(enable, snapLeader = true): 
	
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

	
func _on_gui_manager_start_the_justice(button = false):
	var combatResults
	var target = focusUnit
	if aiTurn:
		target = aiTarget
	sequencingUnits[activeUnit] = true
	sequencingUnits[target] = true
	if activeAction.Weapon and button:
		var i = button.get_meta("index")
		activeUnit.set_equipped(i)
	_change_state(GameState.LOADING)
	combatResults = combatManager.start_the_justice(activeUnit,target, activeAction)
	#print(str(combatResults))
	combat_sequence(combatResults)
	boardState.add_acted(activeUnit)
	#activeUnit.set_acted(true)
	
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
			_change_state(GameState.GB_FORMATION)
		GameState.GB_FORMATION:
			_cursor_toggle(false)
	
#func _on_gui_manager_item_used(unit, item):
	#combatManager.use_item(unit, unit, item)

func _on_gui_manager_map_started():
	for unit in units:
		units[unit].map_start_init()
	_cursor_toggle(true)
	currMap.hide_deployment()
	_change_state(GameState.GB_DEFAULT)
	_initialize_turns()
	

func _on_action_menu_action_selected(selection, action = false):
	match selection:
		"Attack": 
			attack_targeting(activeUnit, action)
		"Skill": 
			attack_targeting(activeUnit, action)
		"Augment":
			attack_targeting(activeUnit, action)
		"Wait": 
			_deselect_active_unit(true)
			_change_state(GameState.GB_DEFAULT)
			turnComplete = true
#			Input.warp_mouse(currMap.map_to_local(activeUnit.position))
		"End":
			_change_state(GameState.LOADING)
			earlyEnd = true
			turnComplete = true
		
		
func _on_action_menu_weapon_changed(button):
	var i = button.get_meta("index")
	
	if button.disabled:
		return
	activeUnit.set_temp_equip(i)
	combatManager.get_forecast(activeUnit, targetUnit, activeAction)
	
	

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
	
	
#aura signals
func _on_area_2d_area_entered(area):
	#print("Entered: ", area)
	focusUnit = area.get_master()
	#print("focusUnit: ", focusUnit)


func _on_area_2d_area_exited(_area):
	#print("Exited: ", area)
	focusUnit = null
	#print("focusUnit: ", focusUnit)
	
#Danmaku Functions
func _progress_danmaku_path():
	#Progress danmaku along it's pathing, then emit the signal once it's complete
	if danmaku.size() == 0:
		emit_signal("danmaku_pathing_complete")
		return
	for cell in danmaku:
		danmakuMotion.append(danmaku[cell])
		danmaku[cell].start_move()
	
	
	
#spawner functions
func spawn_danmaku(bullets: Array, range: int, anchor: Vector2i, anchorType: String) -> Array:
	var results := []
	var region := []
	#_init_hexStar_danmaku()
	region = _get_cells_in_range(anchor, range, range)
	_snap_cursor(anchor)
	for bullet in bullets:
		var isResolved := false
		var spawnPoint 
		while !isResolved:
			if region.size() == 0:
				spawnPoint = false
				isResolved = true
				break
			var cell = region.pop_front()
			var isAlly := false
			if units.has(cell) and units[cell].FACTION_ID == Enums.FACTION_ID.ENEMY:
				isAlly = true
			if !danmaku.has(cell) and !isAlly:
				danmaku[cell] = bullet
				_connect_danmaku_signals(bullet)
				spawnPoint = cell
				set_danmaku_facing(bullet,spawnPoint, anchor, anchorType)
				isResolved = true
			
		results.append({"SpawnPoint": spawnPoint, "Bullet": bullet})
	return results
	

func set_danmaku_facing(bullet,spawnPoint, anchor, type):
	var offsets := []
	var difference : Vector2i =  anchor - spawnPoint
	#var directions := ["TopRight","BottomRight","Bottom","BottomLeft","TopLeft","Top"]
	var i : int
	var hexStar = AHexGrid2D.new(currMap)
	offsets = hexStar._get_offsets(spawnPoint.x)
	i = offsets.find(difference)
	
	match type:
		"Master":
			#"TopRight","BottomRight","Bottom","BottomLeft","TopLeft","Top",
			#var d := [6,0.2,1.59,3,3.3,4.72,]
			var away := [3,4,5,0,1,2]
			i = away[i]
		"Target": pass
		
	#print("Cell:",spawnPoint," i:",i)
	bullet.set_facing(i)
	


func spawn_unit(unit: Unit, cell): #Uses solidsArray, which is deprecated FIX
	var isForced = unit.forced
	var maxed = false
	var adjustedCell = cell
	var path = [Vector2i(cell.x-1, cell.y)]
	var mapSize = currMap.get_used_rect().size
	if !isForced and units.has(cell):
		print("No Valid Space to Spawn Unit")
		return false
		
	adjustedCell.x = clampi(adjustedCell.x, 0, mapSize.x)
	adjustedCell.y = clampi(adjustedCell.y, 0, mapSize.y)
	
	while !is_within_bounds(adjustedCell) or units.has(adjustedCell) or solidsArray.has(adjustedCell):
		if !maxed:adjustedCell.x += 1
		else: 
			maxed = false
			adjustedCell.y += 1
		if adjustedCell.x >= mapSize.x:
			adjustedCell.x = cell.x
			adjustedCell.y += 1
			maxed = true
		if adjustedCell.y >= mapSize.y:
			print("No Valid Space to Spawn Unit")
			return false
	path.append(adjustedCell)
	#cell = adjustedCell
	unit.init_unit(currMap)
	_add_turn(unit.FACTION_ID)
	unitObjs[unit.unitId] = unit
	units[path[0]] = unit
	_connect_unit_signals(unit)
	_update_unit_terrain(unit)
	unit.relocate_unit(path[0])
	unit.play_arrival(path)
	return true

	
func spawn_raw_unit(unitPackage : Dictionary):
	var faction = unitPackage.Faction
	var cell = unitPackage.Cell
	var id = unitPackage.Id
	var lv = unitPackage.GenLv
	var spec = unitPackage.Species
	var job = unitPackage.Job
	var elite = unitPackage.IsElite
	var isForced = unitPackage.IsForced
	var maxed = false
	var adjustedCell = cell
	var mapSize = currMap.get_used_rect().size
	
	if !isForced and units.has(cell):
		print("No Valid Space to Spawn Unit")
		return
		
	adjustedCell.x = clampi(adjustedCell.x, 0, mapSize.x)
	adjustedCell.y = clampi(adjustedCell.y, 0, mapSize.y)
	
	while !is_within_bounds(adjustedCell) or units.has(adjustedCell) or solidsArray.has(adjustedCell):
		if !maxed:adjustedCell.y += 1
		else: adjustedCell.x += 1
		if adjustedCell.y >= mapSize.y:
			adjustedCell = cell
			adjustedCell.x += 1
		if adjustedCell.x >= mapSize.x:
			print("No Valid Space to Spawn Unit")
			return
	cell = adjustedCell
	
	var newUnit = unitScn.instantiate().init_unit(currMap, false, faction, id, elite, lv, spec, job)
	unitObjs[newUnit.unitId] = newUnit
	_connect_unit_signals(newUnit)
	_update_unit_terrain(newUnit)
	newUnit.relocate_unit(cell)
	newUnit.set_process(true)
	
	
#Debug Functions
func _kill_lady():
	var lady = unitObjs["Remilia"]
	lady.apply_dmg(9999)






