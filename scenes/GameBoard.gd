#This class is what I see when I wake up in the middle of the night in a cold sweat
#It controls pretty much all facets of gameplay when within a playable "map"
#UIManager, the map itself, all units, skills and combat are manipulated from this point and acts almost like a veritable hub
#UIManager is not a true child of this class so that it can be used outside of simply maps and keep all UI elements in one place.
#signals are uses for communication between them and many of the children of this class
class_name GameBoard
extends Node2D

#region signals sent from here
signal player_lost
signal player_win
signal cell_selected
signal unit_selected(unit:Unit)
signal unit_move_ended(unit:Unit)
signal gameboard_targeting_canceled
signal camera_on_anchor
signal danmaku_pathing_complete
signal sequence_concluded
signal post_queue_cleared
signal continue_queue
signal map_loaded(map:GameMap)
signal map_freed
signal turn_added(team:StringName)
signal turn_removed(team:StringName)
signal turn_changed
signal new_round(turn_order:Array[StringName])
signal map_added(map:GameMap)
signal units_loaded
#signal loading_complete

#signal skill_target_canceled
#signal item_target_canceled

signal forecast_confirmed



signal toggle_prof

signal target_focused
signal aimove_finished
signal exp_display
signal continue_turn
signal deploy_toggled
signal formation_closed
#endregion

##region targeting modes
#enum TARGET_MODE {ATTACK, SKILL, DOOR,}
#region variables
enum ACTION_TYPE {ATTACK, SKILL, WAIT, END}
var save_enum:Enums.SAVE_TYPE
var map_end := false
var chapter_started := false
# Mapping locations of units and danmaku {cell:node}
var units :Dictionary[Vector2i, Unit]= {} 
var danmaku := {}
var danmakuMotion := []
var collisionQue := []
var dmkScriptProgressing:bool = false
#these are used to store references to actual units that are passed around this class and those it controls
var focusUnit : Unit :
	set(value):
		focusUnit = value
		Global.focusUnit = focusUnit
var focusDanmaku : Danmaku :
	set(value):
		focusDanmaku = value
		Global.focusDanmaku = focusDanmaku
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
var currMap: GameMap:
	set(value):
		currMap = value
		Global.map_ref = value
var warpTarget
var deathList = []
var turnLoss = []
#Units by unit_id
var unitObjs : Dictionary
@onready var parent = get_parent()
#related to pathfinding
#var hexStar: AHexGrid2D #HEX REF
var walkableCells = []
var solidsArray = [] #Deprecated, remove after fixing FIX
var unitMoving = false
var snapPath := []:
	set(value):
		cursor.snapPath = value
		snapPath = value
var pathingArray := []
#game turns
var turnOrder :Array[StringName]= []
var roundCounter := 0
var turnCounter := 0
var earlyEnd = false
#Turn/Round variables
var turnComplete := false
var endOfRound := false
var startNextTurn := false
#Global effects
var globalEffects := {}
#unit variables
var activeAction : Dictionary = {"Weapon":false,"Skill":null,"Item":null}
var postQueue := []
#controls pseudo UI elements, like HP bars
var HpBarVis := true
#AI Variables
var aiTurn := false
var aiNeedAct := false
var ai_turn_result:Dictionary = {}
#Mouse related
@export var mouseSens: float = 0.4
@export var smoothing: float = 0.2
#Nodes
@onready var unitPath: UnitPath = $UnitPath
@onready var cursor: Cursor = $Cursor
@onready var combatManager : CombatManager = $CombatManager
@onready var turnSort : TurnSort = $TurnSort
#@onready var turnTest = $Control/TurnLight
@onready var boardState: BoardState = BoardState.new()
@export var uiCooldown := 0.2
## Global node variables
var cc : CameraController
var ai : AiManager
##Unit Preload
var unitScn := preload("res://scenes/units/Unit.tscn")
#endregion

func _init()->void:
	set_process(false)


func _process(_delta):
	_check_flags()
	if deathList.size() > 0 and turnComplete:
		_wipe_dead()
	elif map_end: return
	elif endOfRound:
		_check_eor_events()
	elif collisionQue.size() > 0 and GameState.state == GameState.gState.GB_END_OF_ROUND:
		_pause_danmaku_phase()
		_process_danmaku_collision()
	elif collisionQue.size() == 0 and danmakuMotion.size() == 0 and GameState.state == GameState.gState.GB_END_OF_ROUND and !dmkScriptProgressing: #When spawning danmaku, this is valid over and over.
		emit_signal("danmaku_pathing_complete")
	elif GameState.state == GameState.gState.ACCEPT_PROMPT or GameState.state == GameState.gState.FAIL_STATE or GameState.state == GameState.gState.WIN_STATE or GameState.state == GameState.gState.GB_END_OF_ROUND:
		pass
	elif turnComplete:
		turnComplete = false
		_post_turn_events()
	elif startNextTurn:
		startNextTurn = false
		_start_next_turn()
	elif aiTurn and aiNeedAct:
		start_ai_turn(turnOrder[0])


#region save/load
func save() -> Dictionary:
	var saveData : Dictionary = {}
	saveData["DataType"] = "GameBoard"
	saveData["map_end"] = map_end
	saveData["chapter_started"] = chapter_started
	#Global effects
	saveData["globalEffects"] = globalEffects
	if !chapter_started and currMap: saveData["deployment"] = _get_deployment()
	#Turn/Round variables
	saveData["turnOrder"] = turnOrder
	saveData["roundCounter"] = roundCounter
	saveData["turnCounter"] = turnCounter
	saveData["earlyEnd"] = earlyEnd
	saveData["turnComplete"] = turnComplete
	saveData["endOfRound"] = endOfRound
	saveData["startNextTurn"] = startNextTurn
	
	#unit variables
	saveData["activeAction"] = activeAction
	saveData["postQueue"] = postQueue
	saveData["HpBarVis"] = HpBarVis # Needs special loading function

	saveData["aiTurn"] = aiTurn
	saveData["aiNeedAct"] = aiNeedAct
	saveData["ai_turn_result"] = ai_turn_result
	# Mapping locations of units and danmaku {cell:node}
	#saveData["units"] = units
	#saveData["focusUnit"] = focusUnit
	#saveData["focusDanmaku"] = focusDanmaku
	#saveData["aiTarget"] = aiTarget
	#saveData["activeUnit"] = activeUnit
	#saveData["targetUnit"] = targetUnit
	#saveData["sequencingUnits"] = sequencingUnits
	#saveData["forcedDeploy"] = forcedDeploy
	#saveData["deploymentCells"] = deploymentCells
	#saveData["depCap"] = depCap
	#saveData["filledSlots"] = filledSlots
	#saveData["storedUnits"] = storedUnit
	#saveData["storedCell"] = storedCell
	#variables related to the active map in use
	#saveData["currMap"] = currMap
	#saveData["deathList"] = deathList
	#saveData["turnLoss"] = turnLoss
	#Units by unit_id
	#saveData["unitObjs"] = unitObjs
	return saveData

func _get_deployment()->Dictionary[StringName,Vector2i]:
	var deployments : Dictionary[StringName,Vector2i]
	for cell : Vector2i in units:
		var unit: Unit = units[cell]
		if unit.deployment == Enums.DEPLOYMENT.DEPLOYED and unit.FACTION_ID == Enums.FACTION_ID.PLAYER: deployments[unit.unit_id] = cell
	return deployments
#endregion

#region Chapter begin, no idea what grouping this is yet
func begin_chapter():
	for unit in units:
		units[unit].map_start_init()
	chapter_started = true
	_cursor_toggle(true)
	currMap.hide_deployment()
	GameState.clear_state_lists()
	GameState.change_state(self, GameState.gState.GB_DEFAULT)
	_initialize_turns()
	call_deferred("set_process", true)
#endregion


#region map functions?
func _get_current_map():
	for mapChild in get_children(): #mapchild
		var map := mapChild as GameMap
		if not map:
			continue
		return map


func free_map()->void:
	reset_flags()
	turnComplete = false # find a better place to reinitialize this and above value HERE
	PlayerData.purge_npc_data()
	if currMap:
		currMap.queue_free()
		await currMap.tree_exited
	SignalTower.time_reset.emit()
	map_freed.emit()
	#call_deferred("_load_new_map", map)


func load_map(map:String, save_data:Dictionary={}):
	if !map: print("[GameBoard]load_map: empty map string")
	var newMap:GameMap = load(map).instantiate()
	Global.timePassed = 0
	currMap = newMap
	if save_data: newMap.map_ready.connect(self._on_map_ready_from_file)
	else: newMap.map_ready.connect(self._on_map_ready)
	if save_data: newMap.load_data(save_data.GameMap)
	add_child(newMap)
	emit_signal("map_added",newMap)
	


#func skip_setup_load(map:String,save_data:Dictionary):
	#load_map(map, save_data)
	##begin_chapter()


#func continue_map():
	#call_deferred("set_process", true)


func _on_map_ready():
	call_deferred("_initialize_new_map")


func _on_map_ready_from_file():
	currMap.units_reloaded.connect(self._on_units_reloaded)
	currMap.load_map_units()


func _on_units_reloaded():
	_initialize_new_map()


func _initialize_new_map():
	_connect_general_signals()
	units.clear()
	_set_game_time()
	_store_enemy_units()
	##_initialize_units() #This wasn't finishing in time
	await _initialize_units() #no, don't read this one yet		--		So I had to tell Wokedot to chill the fuck out for a sec
	_init_gamestate()
	combatManager.init_manager()
	ai = currMap.ai
	ai.init_ai(self)
	_cursor_toggle(true) ##before this one, which relies on Remilia being loaded in
	#You can go back and read the second one now
	emit_signal("map_loaded", currMap)
#endregion


#region unit loading
func _store_enemy_units():
	for child in currMap.get_children():
		var unit := child as Unit
		if not unit or unit.FACTION_ID == Enums.FACTION_ID.PLAYER or unit.is_queued_for_deletion(): continue
		units[unit.cell] = unit
		_connect_unit_signals(unit)


func _initialize_units():
	var roster := PlayerData.rosterData
	var order := PlayerData.roster_order
	var unitData:Dictionary = PlayerData.unitData
	var deploymentHistory := {"Deployed":[],"Undeployed":[]}
	
	#var spawnLoc
	filledSlots = 0
	deploymentCells = currMap.get_deployment_cells()
	forcedDeploy = currMap.get_forced_deploy()
	depCap = deploymentCells.size() + forcedDeploy.size()
	
	_deploy_forced(forcedDeploy)
	_deploy_group(order[Enums.DEPLOYMENT.DEPLOYED])
	_deploy_group(order[Enums.DEPLOYMENT.UNDEPLOYED])
	_update_roster_label()


func _deploy_forced(forced_dictionary:Dictionary):
	var roster := PlayerData.rosterData
	var unitData:Dictionary = PlayerData.unitData
	var group:Array = forced_dictionary.keys()
	var filledSlots: int = 0
	for id in group:
		if roster[id].deployment == Enums.DEPLOYMENT.GRAVEYARD: continue
		var playerUnit:Unit = _load_player_unit(roster[id].Path)
		_deploy_unit(playerUnit, true, forced_dictionary[id])


func _deploy_group(group:Array):
	var roster := PlayerData.rosterData
	var unitData:Dictionary = PlayerData.unitData
	var groupCopy:= group.duplicate()
	for id in groupCopy:
		if roster[id].deployment == Enums.DEPLOYMENT.GRAVEYARD: continue
		var playerUnit:Unit = _load_player_unit(roster[id].Path)
		if filledSlots < depCap:
			_deploy_unit(playerUnit)
		elif filledSlots >= depCap:
			_undeploy_unit(playerUnit, true)


func _load_player_unit(path:String) -> Unit:
	var playerUnit :Unit= load(path).instantiate()
	var unitData:Dictionary = PlayerData.unitData
	playerUnit.map = currMap
	if unitData and unitData.PLAYER.get(playerUnit.unit_id,false): 
		playerUnit.pre_load(unitData.PLAYER[playerUnit.unit_id])
	unitObjs[playerUnit.unit_id] = playerUnit
	_connect_unit_signals(playerUnit)
	currMap.add_child(playerUnit)
	return playerUnit


##Intended for player units, maps will handle Enemy and NPC units
func _on_unit_ready(unit:Unit)->void:
	var faction:String = Enums.FACTION_ID.keys()[unit.FACTION_ID]
	var ID: String = unit.unit_id
	var unitData:Dictionary = PlayerData.unitData[faction]
	var setCell:bool = false
	if save_enum == Enums.SAVE_TYPE.SUSPENDED: setCell = true
	if unitData and unitData.get(ID,false): unit.post_load(unitData[ID],setCell)
#endregion


#region cell/grid/pathfinding
## Returns `true` if the cell is occupied by a unit
func is_occupied(cell: Vector2i) -> bool:
		return units.has(cell)


func get_walkable_cells(unit: Unit) -> Array: #Pathing
	var hexStar = AHexGrid2D.new(currMap)
	var path = hexStar.find_all_unit_paths(unit)
	return path


func _update_walkable_range(moveRemain:int = 0):
	var hexStar = AHexGrid2D.new(currMap)
	var newArea :Array = hexStar.find_remaining_unit_paths(activeUnit, pathingArray[-1], moveRemain)
	currMap.draw(newArea)


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
	var occupied = is_occupied(cursor.cell)
	if !occupied and !currMap.doors.has(cursor.cell):
		emit_signal("cell_selected", cursor.cell)
	elif units[cursor.cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
		_select_unit(cursor.cell)
	else:
		pass #TO-DO: seperate selection that just toggles a unit's movement and reach

func grab_target(cell):
	#Called to assign values based on unit at cursor's coordinate
	var hexStar = AHexGrid2D.new(currMap)
	if not units.has(cell):
		print("oops")
		return
	var mode : int
	targetUnit = units[cell]
	var distance := hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit) #HEX REF
	var reach := [distance, distance]
	#if activeAction.Item: activeAction.Skill = activeAction.Item
	if activeAction.Weapon:
		combatManager.get_forecast(activeUnit, targetUnit, activeAction)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mode = 0
	else:
		combatManager.get_forecast(activeUnit, targetUnit, activeAction)
		mode = 1
		
	emit_signal("target_focused", mode, reach)


func select_destination() -> void: #SELECTED STATE Pathing Related
	var isOccupied = is_occupied(cursor.cell)
	var isWalkable = walkableCells.has(cursor.cell)
	var moveRemain :int = activeUnit.active_stats.Move - pathingArray.size()
	
	if !isOccupied and isWalkable and moveRemain > 0 and !pathingArray.has(cursor.cell):
		_update_pathing_array(cursor.cell)
		moveRemain = activeUnit.active_stats.Move - pathingArray.size()
		_update_walkable_range(moveRemain)
	elif cursor.cell == activeUnit.cell:
		emit_signal("unit_move_ended", activeUnit)
	elif !isWalkable or isOccupied: return
	elif pathingArray[-1] == cursor.cell:
		_move_active_unit(cursor.cell)
#endregion


func _on_cursor_moved(new_cell: Vector2i) -> void: #Pathing
	var path := []
	
	if units.has(new_cell) and units[new_cell] == null: #safety measure, catches any uncleared cell storage that slips through the cracks
		units.erase(new_cell)
	
	if !activeUnit or !activeUnit.isSelected or GameState.state != GameState.gState.GB_SELECTED:
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
	var nextCell = cursor.cell + direction
	var newCell
	
	if GameState.state == GameState.gState.GB_PROFILE:
		return
		
	if snapPath and !snapPath.has(nextCell):
		newCell = find_next_best_cell(cursor.cell, nextCell)
		cursor.cell = newCell
	else: cursor.cell += direction


#region Targeting Code
func start_attack_targeting():
	var reach :Dictionary = activeUnit.get_weapon_reach()
	activeAction = {"Weapon": true, "Skill": null, "Item": null}
	GameState.change_state(self, GameState.gState.GB_ATTACK_TARGETING)
	_draw_range(activeUnit, reach.Max, reach.Min)
	
	
func start_skill_targeting():
	var reach : Dictionary
	activeAction = {"Weapon": Global.activeSkill.augment, "Skill": Global.activeSkill, "Item": null}
	if activeAction.Weapon: reach = activeUnit.get_aug_reach(activeAction.Skill)
	else: reach = activeUnit.get_skill_reach(activeAction.Skill)
	_draw_range(activeUnit, reach.Max, reach.Min)
	GameState.change_state(self, GameState.gState.GB_SKILL_TARGETING)


func door_targeting():
	_draw_range(activeUnit, 1, 1)
	GameState.change_state(self, GameState.gState.GB_OBJECT_TARGETING)


func start_item_targeting(item:Item):
	activeAction = {"Weapon": false, "Skill": null, "Item": item}
	_draw_range(activeUnit, item.min_reach, item.max_reach)
	GameState.change_state(self, GameState.gState.GB_ITEM_TARGETING)


func seek_trade(_unit:Unit):
	GameState.change_state(self, GameState.gState.GB_TRADE_TARGETING)
	_draw_range(activeUnit, 1, 1)

func warp_targeting(unit, wRange):
	_draw_range(unit, wRange)
	GameState.change_state(self, GameState.gState.GB_WARP)
	
func _draw_range(unit : Unit, maxRange : int, minRange := 0):
	var path = _get_cells_in_range(unit.cell, maxRange, minRange,)
	snapPath = path
	cursor.bump_cursor()
	currMap.draw_attack(path)
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
	if !is_occupied(cursor.cell) and !solidsArray.has(cursor.cell) and snapPath.has(cursor.cell):
		combatManager.warp_to(warpTarget, cursor.cell)
		combat_sequence("warp")
		warpTarget = null
#endregion

#actions code
func _on_unit_item_targeting(item, unit):
	activeUnit = unit
	start_item_targeting(item)


func _on_unit_item_activated(item:Consumable, unit:Unit, target:Unit)->void:
	_activate_item(item,unit,target)


func _activate_item(item:Consumable, unit:Unit, _target:Unit): #HERE Unfinished
	var results = combatManager.use_item(unit, unit, item)
	GameState.change_state(self, GameState.gState.LOADING)
	#insert map animations for items here
	_on_animation_handler_sequence_complete()

func combat_sequence(scenario):
	GameState.change_state(self, GameState.gState.ACCEPT_PROMPT)
	SignalTower.emit_signal("sequence_initiated", scenario)


func _on_animation_handler_sequence_complete():
	var hasPostEvents = _check_post_queue()
	GameState.change_state(self, GameState.gState.LOADING)
	
	if hasPostEvents:
		_run_post_queue()
		await self.post_queue_cleared
	emit_signal("sequence_concluded")
	_wipe_region()


func _run_post_queue():
	var postEvents = _sort_post_queue()
	var eventKeys
	var type = Enums.EFFECT_TYPE
	eventKeys = postEvents.keys()
	for actor in eventKeys:
		for event in postEvents[actor]:
			var t = event.Type
			var effect = event.EffectId
			var target = event.Target
			var isWait = true
			match t:
				type.RELOC:
					combatManager.start_relocation(actor, target, effect)
				_: isWait = false
			if isWait:
				await self.continue_queue
	call_deferred("_clear_post_queue")


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
	PlayerData.save_unit_data()
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
	currMap.check_event(currMap.MAP_EVENT.DEATH, unit)


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


#region turn functions
func _post_turn_events():
	Global.progress_time()
	check_passives()
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
	GameState.clear_state_lists()
	PlayerData.traded = false
	PlayerData.item_used = false
	emit_signal("turn_changed")


func _start_next_turn():
	if turnOrder[0] == "Enemy":
		GameState.change_state(self, GameState.gState.LOADING)
		aiTurn = true
		aiNeedAct = true
		print("Enemy Turn")
		_cursor_toggle(false)
	elif turnOrder[0] == "Player":	
		GameState.change_state(self, GameState.gState.GB_DEFAULT)
		aiTurn = false
		print("Player Turn")
		_cursor_toggle(true)
	elif turnOrder[0] == "NPC": #Currently, NPC turns aren't a feature of the AI
		GameState.change_state(self, GameState.gState.LOADING)
		aiTurn = true
		print("NPC Turn")
		_cursor_toggle(false)

	if !aiTurn and earlyEnd:
		GameState.change_state(self, GameState.gState.LOADING)
		set_next_acted()
		turnComplete = true
	

func _add_turn(faction):
	var team : StringName

	match faction:
		Enums.FACTION_ID.PLAYER: team = "Player"
		Enums.FACTION_ID.ENEMY: team = "Enemy"
		Enums.FACTION_ID.NPC: team = "NPC"
		
	turnOrder.append(team)
	emit_signal("turn_added", team)


func _remove_turn(teamId):
	var team : StringName
	print("Before Removed Turn:",turnOrder)
	match teamId:
		Enums.FACTION_ID.PLAYER: team = "Player"
		Enums.FACTION_ID.ENEMY: team = "Enemy"
		Enums.FACTION_ID.NPC: team = "NPC"
	if turnOrder[0] != team:
		var i = turnOrder.rfind(team)
		turnOrder.remove_at(i)
	print("Removed Turn:",team, ":",turnOrder)
	emit_signal("turn_removed", team)


func round_change():
	#Changes the round and reloads the "turn order" magazine
	#Return HERE to make sure turns flow properly, I can already see conflicting issues cropping up
	earlyEnd = false
	_initialize_turns()
	boardState.clear_acted()
	round_duration_tick() #Outdated! Just handles global time effect durations! Doesn't utilize new skill system, or duration types! SHOULD CHECK UNIT'S VERSION OF THIS, TOO.
	endOfRound = true
	emit_signal("new_round",turnOrder)
#	print(units)
	
func _check_eor_events():
	endOfRound = false
	GameState.change_state(self, GameState.gState.GB_END_OF_ROUND)
	if danmaku.size() > 0:
		_progress_danmaku_path()
		await self.danmaku_pathing_complete
	dmkScriptProgressing = true
	if !cc: 
		cc = CameraController.new(get_viewport())
	cursor.visible = false
	currMap.progress_danmaku_script()
	


func camera_to_anchor(cell:Vector2i):
	cc.move_camera_map(cell)
	await cc.camera_control_complete
	emit_signal("camera_on_anchor")


func _on_danmaku_progressed():
	dmkScriptProgressing = false
	if cc:
		cc.reset_camera(true)
		await cc.camera_control_complete
		_kill_camera()
	_start_next_turn()
	
func _initialize_turns(ignoreActed = false): #not quite right Groups might be the problem, just use faction ID
	turnOrder.clear()
	for cell in units: #grab unit locations
		var unit = units[cell]
		if ignoreActed and unit.status.Acted:
			continue
		else: unit.set_acted(false)
		
		match unit.FACTION_ID: #turn order initializing
			Enums.FACTION_ID.PLAYER: turnOrder.append("Player")
			Enums.FACTION_ID.ENEMY: turnOrder.append("Enemy")
			Enums.FACTION_ID.NPC: turnOrder.append("NPC")
		_update_unit_terrain(unit) #update terrain data
	turnOrder = turnSort.sort_turns(turnOrder)
	aiTurn = false
	boardState.update_remaining_turns(turnOrder)
	emit_signal("new_round", turnOrder)
	print(turnOrder)


func set_next_acted():
	for cell in units:
		if !units[cell].status.Acted and units[cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
			units[cell].set_acted(true)
			return
#endregion

##Gets the ball rolling for the AI to take actions
func start_ai_turn(aiFaction):
	print("Starting AI Turn")
	var team : Array = boardState[aiFaction.to_lower()]
	var factionId : Enums.FACTION_ID = Enums.FACTION_ID[aiFaction.to_upper()]
	aiNeedAct = false
	GameState.change_state(self, GameState.gState.GB_AI_TURN)
	if team.size() > 0:
		ai_turn_result = ai.get_move(factionId)
		
		print_rich("[color=green]AI MOVE[/color]: ",ai_turn_result)
		turnComplete = true #not normally here
		#match result.BestMove["Action"]:
			#"Attack": ai_attack(result)
			#"Skill": pass
			#"Move": ai_move(result)
			#"Wait": ai_wait(result)
	else: turnComplete = true
	

func _continue_ai_turn():
	pass
	
#The next three functions process the AI's decided action based on which one is taken
##Attacking, Move without attacking; waiting in place
func ai_attack(result): #HERE..... EVENTUALLY. So fuckin out of date.
	var actor = result["Unit"]
	var target = result.BestMove["Target"]
	var destination = Vector2i(result.BestMove["Launch"])
	var weapon = result.BestMove.Weapon
	var skill = result.BestMove.Skill
	var wInd = actor.inventory.find(weapon)
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


#region Time bullshitery
##tracks duration of round based effects, removing them when duration is up
##Lacks a check for stacked global effects, and only really works for time_factor changes
func round_duration_tick():
	var keys = globalEffects.keys()
	for effId in keys:
		globalEffects[effId].duration -= 1
		if globalEffects[effId].duration <= 0 and globalEffects[effId].type == "Time":
			Global.reset_time_factor()
			globalEffects.erase(effId)
		else: #no other global effects exist, this needs to be expanded if a new one is made
			globalEffects.erase(effId)

##Does not have a stacking check
func add_global_effect_time_factor(effect:Effect):
	var effId = effect.id
	globalEffects[effId] = effect
	#globalEffects[effId]["Type"] = effect.sub_type
	#globalEffects[effId]["Factor"] = effect.value
	#globalEffects[effId]["Duration"] = effect.duration
	Global.apply_time_factor(effect.value)


func _on_combat_manager_time_factor_changed(effect:Effect):
	add_global_effect_time_factor(effect)


func _set_game_time():
	var newTime = Global.time_to_float(currMap.hours, currMap.minutes)
	Global.game_time = newTime
	check_passives()


func check_passives():
	for unit in units:
		units[unit].check_passives()
#endregion


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


func _deploy_unit(unit:Unit, forced = false, spawnLoc = Vector2i(0,0)):
	var roster := PlayerData.rosterData
	if forced:
		unit.deployment = Enums.DEPLOYMENT.FORCED
	else:
		spawnLoc = _first_available_dep_cell()
		unit.deployment = Enums.DEPLOYMENT.DEPLOYED
	if filledSlots < depCap:
		unit.visible = true
		unit.is_active = true
		if save_enum != Enums.SAVE_TYPE.SUSPENDED: unit.relocate_unit(spawnLoc)
		filledSlots += 1
		roster
		_update_roster_label()
	else:
		print("Roster Full")


func _undeploy_unit(unit:Unit, ini = false):
	var spawnLoc = Vector2i(0,0)
	if unit.deployment != Enums.DEPLOYMENT.FORCED:
		unit.visible = false
		unit.is_active = false
		unit.deployment = Enums.DEPLOYMENT.UNDEPLOYED
		_remove_from_grid(unit)
		unit.relocate_unit(spawnLoc, false)
	else:
		print("Must deploy: " + unit.unit_id)
	if unit.deployment != Enums.DEPLOYMENT.FORCED and !ini:
		filledSlots -= 1
		_update_roster_label()


func _update_roster_label():
	#print(filledSlots)
	emit_signal("deploy_toggled", filledSlots)


func _cursor_toggle(enable, snapLeader = true):
	if enable:
		cursor.visible = true
	else:
		cursor.visible = false
	if snapLeader:
		_snap_cursor()


func _snap_cursor(cell: Vector2i = unitObjs[forcedDeploy.keys()[0]].cell): #can be annoying to always have this tied to mouse, like before map starts.
	cursor.cell = cell
	var mouseWarp = cursor.get_global_transform_with_canvas()
	#mouseWarp = to_global(mouseWarp)
	print("Mouse Warp:", mouseWarp.origin)
	get_viewport().warp_mouse(mouseWarp.origin)
	cursor.align_camera()


#region GUI Signal Functions
func _on_gui_action_menu_canceled():
	request_deselect()

func unit_wait():
	_deselect_active_unit(true)
	GameState.change_state(self, GameState.gState.LOADING)
	turnComplete = true


func _on_exp_gain_exp_finished():
	#GameState.change_state(self, GameState.gState.LOADING)
	GameState.change_state()
	emit_signal("continue_turn")


func _on_action_weapon_selected(button = false):
	var combatResults
	var target = focusUnit
	if aiTurn:
		target = aiTarget
	sequencingUnits[activeUnit] = true
	sequencingUnits[target] = true
	if activeAction.Weapon and button:
		var weapon = button.get_meta("Item")
		activeUnit.set_equipped(weapon)
	GameState.change_state(self, GameState.gState.LOADING)
	combatResults = combatManager.start_the_justice(activeUnit,target, activeAction)
	#print(str(combatResults))
	combat_sequence(combatResults)
	boardState.add_acted(activeUnit)
	#activeUnit.set_acted(true)


func _on_win_screen_win_finished():
	PlayerData.completed_chapters.append(currMap.get_name())
	#currMap.progress_next_map()
	#self.call_deferred("_load_next_map")


func _on_gui_manager_deploy_toggled(unit, deployed):
#	var unit = unitObjs[unit_id]
	if deployed:
		_undeploy_unit(unit)
	else:
		_deploy_unit(unit)


func _on_gui_manager_formation_toggled():
	match GameState.state:
		GameState.gState.GB_SETUP:
			_cursor_toggle(true, true)
			GameState.change_state(self, GameState.gState.GB_FORMATION)
		GameState.gState.GB_FORMATION:
			_cursor_toggle(false)
	
#func _on_gui_manager_item_used(unit, item):
	#combatManager.use_item(unit, unit, item)

func _on_gui_manager_map_started():
	begin_chapter()
	_randomize_rolls()


func _on_inventory_weapon_changed(button) -> void:
	var i = button.get_meta("Item")
	if button.disabled:
		return
	activeUnit._equip_weapon(i) #See if it can find it's own index based on ID?
	combatManager.get_forecast(activeUnit, targetUnit, activeAction)
#regionend


#Objective related code
func _check_flags():
	var flags = Global.flags
	
	if map_end: return
	elif flags.gameOver: #consider saving reason for loss in later versions
		map_end = true
		emit_signal("player_lost")
	elif flags.victory:
		map_end = true
		PlayerData.save_unit_data(true)
		emit_signal("player_win")
		
func reset_flags():
	Global.reset_map_flags()
	units.clear()
	map_end = false
	chapter_started = false
	aiTurn = false
	aiNeedAct = false
	turnComplete = false
	endOfRound = false
	startNextTurn = false

#aura signals
func _on_area_2d_area_entered(area):
	#print("Entered: ", area.collision_layer)
	match area.collision_layer:
		2: focusUnit = area.get_master()
		4: focusDanmaku = area.get_master()
	#print("focus: ", focusDanmaku)


func _on_area_2d_area_exited(area):
	#print("Exited: ", area)
	match area.collision_layer:
		2: focusUnit = null
		4: focusDanmaku = null
	
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


func append_danmaku(new_danmaku:Dictionary[Vector2i,Danmaku]):
	for cell in new_danmaku:
		danmaku[cell] = new_danmaku[cell]
		_connect_danmaku_signals(danmaku[cell])


#spawner functions
#func spawn_danmaku(bullets: Array, danRange: int, anchor: Vector2i, anchorType: String) -> Array:
	#var results := []
	#var region := []
	##_init_hexStar_danmaku()
	#region = _get_cells_in_range(anchor, danRange, danRange)
	#_snap_cursor(anchor)
	#for bullet in bullets:
		#var isResolved := false
		#var spawnPoint 
		#while !isResolved:
			#if region.size() == 0:
				#spawnPoint = false
				#isResolved = true
				#break
			#var cell = region.pop_front()
			#var isAlly := false
			#if units.has(cell) and units[cell].FACTION_ID == Enums.FACTION_ID.ENEMY:
				#isAlly = true
			#if !danmaku.has(cell) and !isAlly:
				#danmaku[cell] = bullet
				#_connect_danmaku_signals(bullet)
				#spawnPoint = cell
				#set_danmaku_facing(bullet,spawnPoint, anchor, anchorType)
				#isResolved = true
			#
		#results.append({"SpawnPoint": spawnPoint, "Bullet": bullet})
	#return results
	

#func set_danmaku_facing(bullet,spawnPoint, anchor, type):
	#var offsets := []
	#var difference : Vector2i =  anchor - spawnPoint
	##var directions := ["TopRight","BottomRight","Bottom","BottomLeft","TopLeft","Top"]
	#var i : int
	#var hexStar = AHexGrid2D.new(currMap)
	#offsets = hexStar._get_offsets(spawnPoint.x)
	#i = offsets.find(difference)
	#
	#match type:
		#"Master":
			##"TopRight","BottomRight","Bottom","BottomLeft","TopLeft","Top",
			##var d := [6,0.2,1.59,3,3.3,4.72,]
			#var away := [3,4,5,0,1,2]
			#i = away[i]
		#"Target": pass
		#
	##print("Cell:",spawnPoint," i:",i)
	#bullet.set_facing(i)
	


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
	unitObjs[unit.unit_id] = unit
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
	unitObjs[newUnit.unit_id] = newUnit
	_connect_unit_signals(newUnit)
	_update_unit_terrain(newUnit)
	newUnit.relocate_unit(cell)
	newUnit.set_process(true)
	

#region outdated, possibly unneeded functions that can't be outright deleted yet
func _init_gamestate():
	#boardState.update_map_data(terrainData)
	boardState.update_unit_data(units)
#endregion


#region menu response functions
func confirm_forecast():
	emit_signal("forecast_confirmed")


func _start_trade(cell):
	_wipe_region()
	currMap.pathAttack.clear()
	parent.call_trade(units[cell])


func toggle_unit_profile(): 
	if GameState.state == GameState.gState.GB_PROFILE:
		emit_signal("toggle_prof")
	elif focusUnit:
		emit_signal("toggle_prof")
	else: toggle_extra_info()


func request_deselect():
	_wipe_region()
	currMap.pathAttack.clear()
	GameState.change_state(self, GameState.gState.GB_DEFAULT)
	_deselect_active_unit(false)


func end_targeting():
	_wipe_region()
	currMap.pathAttack.clear()
	cursor.cell = activeUnit.cell
	emit_signal("gameboard_targeting_canceled")


func menu_step_back():
	match GameState.state:
		GameState.gState.GB_COMBAT_FORECAST:
			emit_signal("action_called", activeUnit)
			GameState.change_state(self, GameState.gState.GB_ACTION_MENU)
			_wipe_region()
			cursor.cell = activeUnit.cell


func attack_target_selected():
	if is_occupied(cursor.cell) and !_check_friendly(activeUnit, focusUnit):
#				$Cursor.visible = false
		grab_target(cursor.cell)


func trade_target_selected():
	if is_occupied(cursor.cell) and _check_friendly(activeUnit, focusUnit, true):
		_start_trade(cursor.cell)


func item_target_selected()->void:
	if activeAction.Item is Ofuda: _feature_target(activeAction.Item)
	else: _activate_item(activeAction.Item,activeUnit,focusUnit)


func skill_target_selected():
	_feature_target(activeAction.Skill)


func object_target_selected():
	if currMap.doors.has(cursor.cell):
		GameState.change_state(self, GameState.gState.ACCEPT_PROMPT)
		activeUnit.pick_door(currMap.doors[cursor.cell])


func _feature_target(feature:SlotWrapper)-> void:
	if !is_occupied(cursor.cell):
		return
	if !feature:
		print("No Valid SkillID")
		return
	var friendly := false
	var valid := false
	if focusUnit.FACTION_ID == activeUnit.FACTION_ID or focusUnit.FACTION_ID == Enums.FACTION_ID.NPC:
		friendly = true
	match feature.target:
		Enums.SKILL_TARGET.SELF:
			if activeUnit == focusUnit:
				valid = true
		Enums.SKILL_TARGET.ENEMY:
			if !friendly:
				valid = true
			#if skill.RuleType:
				#match skill.RuleType:
					#Enums.RULE_TYPE.TARGET_SPEC:
						#if skill.Rule != focusUnit.SPEC_ID:
							#valid = false
		Enums.SKILL_TARGET.ALLY:
			if friendly and activeUnit != focusUnit:
				valid = true
		Enums.SKILL_TARGET.SELF_ALLY:
			if friendly:
				valid = true
		Enums.SKILL_TARGET.MAP:
			if activeUnit != focusUnit:
				valid = true
	if valid: grab_target(cursor.cell)


func _check_friendly(unit1, unit2, sameOnly:=false) ->bool:
	if unit1.FACTION_ID == unit2.FACTION_ID: return true
	elif !sameOnly and unit1.FACTION_ID != Enums.FACTION_ID.ENEMY and unit2.FACTION_ID != Enums.FACTION_ID.ENEMY: return true
	return false


func return_targeting():
	#var s
	match GameState.previousState:
		GameState.gState.GB_ATTACK_TARGETING:
			#s = "Attack"
			activeUnit.restore_equip()
			start_attack_targeting()
		GameState.gState.GB_SKILL_TARGETING:
			start_skill_targeting()
		GameState.gState.GB_SKILL_TARGETING:
			start_item_targeting(activeAction.Item)
#endregion


#region mouse/cursor functions
func gb_mouse_motion(_event):
	var mousePos: Vector2i = currMap.get_local_mouse_position()
	var toMap = currMap.ground.local_to_map(mousePos)
	
	#print(mousePos)
	cursor.cell = Vector2i(toMap)
#endregion


#region unit-related functions
func _update_unit_terrain(unit:Unit): #HERE BROKEN
	unit.update_terrain_data()


func _move_active_unit(new_cell: Vector2i, enemy: bool = false, enemyPath = null) -> void: #pathing related
	# Updates the units dictionary with the target position for the unit and asks the activeUnit to walk to it.
#	print("move_active: ", new_cell)
	var path = null
	if !new_cell == activeUnit.cell and !enemy:
		if is_occupied(new_cell) or not new_cell in walkableCells:
			return
	
	if !enemy:
		GameState.change_state(self, GameState.gState.ACCEPT_PROMPT)
	currMap.pathAttack.clear()
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
		emit_signal("unit_move_ended", activeUnit)
	else:
		emit_signal("aimove_finished")


func _select_unit(cell: Vector2i, isAi = false) -> void:
	# Selects the unit in the `cell` if there's one there.
	# Sets it as the `activeUnit` and draws its walkable cells and interactive move path. 
#	#print(units, units.has(cell))
#	print(cell)
	if !units.has(cell) or units[cell].status.Acted: return
	activeUnit = units[cell]
	#activeUnit.save_equip()
	activeUnit.isSelected = true
	walkableCells = get_walkable_cells(activeUnit)
	
	currMap.draw(walkableCells)
	if !isAi: GameState.change_state(self, GameState.gState.GB_SELECTED)
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
		_snap_cursor(activeUnit.cell)
		activeUnit.isSelected = false
		
	_clear_active_unit()
	currMap.pathAttack.clear()
	unitPath.stop()
	pathingArray.clear()
	
	
func on_unit_relocated(oldCell, newCell, unit): #updates unit locations with it's new location
	if units.has(oldCell):
		units.erase(oldCell)
	units[newCell] = unit


func _clear_active_unit() -> void:
	# Clears the reference to the activeUnit and the corresponding walkable cells
	
	activeUnit = null
	walkableCells.clear()
#endregion


#region Danmaku functions
func on_danmaku_relocated(oldCell, newCell, bullet):
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
#endregion


#region formation functions
func select_formation_cell():
	if deploymentCells.has(cursor.cell) and is_occupied(cursor.cell) and storedUnit == null:
		storedUnit = units[cursor.cell]
		storedCell = cursor.cell
		storedUnit.isSelected = true
	elif deploymentCells.has(cursor.cell) and is_occupied(cursor.cell):
		_deploy_swap(storedUnit, units[cursor.cell])
		# swap function here
	elif deploymentCells.has(cursor.cell) and storedCell != Vector2i(-1,-1):
		storedCell = cursor.cell
	elif deploymentCells.has(cursor.cell):
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
		storedUnit.isSelected = false
		storedUnit = null
	if storedCell != defValue:
		storedCell = defValue
#endregion


#region utility funcs
func _randomize_rolls():
	var rng:=RngTool.new()
	rng.random()


func _wipe_region():
	snapPath.clear()


func _toggle_pause():
	get_tree().paused = !get_tree().paused


func _connect_unit_signals(unit:Unit):
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
	if !self.new_round.is_connected(unit._on_new_round):
		self.new_round.connect(unit._on_new_round)
	if !self.turn_changed.is_connected(unit._on_turn_changed):
		self.turn_changed.connect(unit._on_turn_changed)
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
	if !unit.unit_ready.is_connected(self._on_unit_ready):
		unit.unit_ready.connect(self._on_unit_ready)

func _connect_danmaku_signals(bullet):
	if !bullet.danmaku_relocated.is_connected(self.on_danmaku_relocated):
		bullet.danmaku_relocated.connect(self.on_danmaku_relocated)
	if !bullet.collision_detected.is_connected(self.on_danmaku_collision):
		bullet.collision_detected.connect(self.on_danmaku_collision)
	if !bullet.animation_completed.is_connected(self._on_danmaku_animation):
		bullet.animation_completed.connect(self._on_danmaku_animation)


func _connect_general_signals():
	#self.gb_ready.connect(GameState.set_new_state)
	cursor.cursor_moved.connect(self._on_cursor_moved)
	SignalTower.sequence_complete.connect(self._on_animation_handler_sequence_complete)
	#self.danmaku_pathing_complete.connect()
	#self.round_changed.connect(currMap.on_round_changed)
	#self.cell_selected.connect(mainCon.on_cell_selected)
#endregion


#region debug funcs
func _kill_lady():
	var lady = unitObjs["remilia"]
	lady.apply_dmg(9999)


func _dmg_lady():
	var lady :Unit= unitObjs["remilia"]
	lady.apply_dmg(9, lady)


func level_test():
	var unit : Unit = unitObjs["remilia"]
	unit.add_exp("Kill")


func _camera_test():
	if !cc: 
		cc = CameraController.new(get_viewport())
	cursor.visible = false
	GameState.change_state(self, GameState.gState.CAMERA_STATE)
	#cc.move_camera_map(Vector2i(15,8))
	
	cc.move_camera_cameratile(0)
	
	await cc.camera_control_complete
	
	cc.move_camera_cameratile(1,0.5)
	
	await cc.camera_control_complete
	
	cc.fade_out()
	cc.reset_camera(false)
	
	await cc.camera_control_complete
	
	cc.fade_in()
	
	await cc.camera_fade_in_complete
	
	
	GameState.change_state()
	cursor.visible = true
	print("Camera tween test complete")

func _kill_camera() -> void:
	if !cc: return
	cc.skip_tween()
	cursor.visible = true
	cc.call_deferred("free")
	#cursor.return_origin()
#endregion
