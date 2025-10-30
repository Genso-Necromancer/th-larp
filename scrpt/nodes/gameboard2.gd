extends Node
class_name GameBoard

signal map_loaded(map:GameMap)
signal map_added(map:GameMap)
#turn/round signal
signal new_round(turn_order:Array)
signal turn_changed
signal turn_added(team:StringName)
signal turn_removed(team:StringName)
#GUI signals
signal formation_closed
signal deployment_count_updated(slots:int)
signal continue_turn
signal exp_display(oldExp:int, expSteps:Array, results:Dictionary, portrait:String, unitName:String)
signal toggle_prof
#animation signals
#signal sequence_concluded
signal continue_queue
#signal effect_queue_cleared
signal unit_move_ended(unit:Unit)
#selection signals
signal cell_selected(cell:Vector2i)
signal unit_selected(unit:Unit)
signal ui_returned(step:TURN_STEPS)
signal target_focused(mode:int,reach:Array)
signal action_confirmed
#debug signals
signal state_changed(state_keys:Array,state)
signal step_changed(step_keys:Array,step)
#added to make things run, not sure if needed
signal aimove_finished
signal gameboard_targeting_canceled
signal map_freed
#signal action_confirmed #Bandaid signal to close the action menu after targeted things like opening a door


enum STATES {IDLE,LOADING,FORMATION,ROUND_END,NEW_TURN,PLAYER_PHASE,NPC_PHASE,ENEMY_PHASE,END_MAP,GAME_OVER,VICTORY}
var state:STATES = STATES.IDLE:
	set(value):
		state = value
		state_changed.emit(STATES.keys(),value)
var save_enum:Enums.SAVE_TYPE = Enums.SAVE_TYPE.NONE

#nodes
@onready var cursor:Cursor = %Cursor
@onready var combatManager:CombatManager = %CombatManager
@onready var unit_path:UnitPath = $UnitPath
@onready var turn_sort:TurnSort =$TurnSort
var ai:AiManager
var map_loader:MapLoader
var unit_loader:UnitLoader
#map
var current_map:GameMap:
	set(value):
		current_map = value
		Global.map_ref = value
var chapter_started:bool = false
#pathing
#var path_array:Array[Vector2i]
var walkable_cells:Array
var snap_path:Array:
	set(value):
		cursor.snap_path = value
		snap_path = value
#unit
var units:Dictionary[Vector2i, Unit]={}
var unit_refs:Dictionary[String, Unit]={} #This feels redundant, it's just another look up table like "units" but uses ID instead of Cell
var activeUnit:Unit
var targetUnit:Unit
var focusUnit:Unit:
	set(value):
		focusUnit = value
		Global.focusUnit = focusUnit
var active_action:Dictionary = {"Weapon":false,"Skill":null,"Item":null}
var lady:Unit
var death_list :Array[Unit]= []
var move_committed:bool = false
var hp_bar_vis := true
#danmaku
var focusDanmaku:Danmaku:
	set(value):
		focusDanmaku = value
		Global.focusDanmaku = focusDanmaku
#turns/rounds
enum TURN_STEPS {STAND_BY,PROCESSING,START,END_PHASE,END,OPTIONS,ACTIONS,MOVE_SEEK,MOVE_REMAINING,UNIT_MOVING,MOVE_END,ACTIONS2,AI_ACT,ITEM_QUEUED,ITEM_ANIMATION,ITEM_TARGET,ATTACK_TARGET,DOOR_TARGET,SKILL_TARGET,FORECAST_ATTACK,COMBAT_DISPLAY,EFFECT_QUEUE,BAR_ANIM,EVENT_QUEUE,EXP_GRANT,CANTO}
enum AI_STEPS {STAND_BY,PROCESSING,START,EVALUATE,PROCESS_TURN,SELECT_UNIT,MOVE_UNIT}
enum ROUND_STEPS {CHECK,DANMAKU,SCENE,REINFORCE,END,}
var last_step:TURN_STEPS
var turn_step:TURN_STEPS = TURN_STEPS.STAND_BY:
	set(value):
		last_step = turn_step
		turn_step = value
		step_changed.emit(TURN_STEPS.keys(),value)
var ai_step:AI_STEPS = AI_STEPS.STAND_BY
var round_step:ROUND_STEPS = ROUND_STEPS.CHECK:
	set(value):
		round_step = value
		step_changed.emit(ROUND_STEPS.keys(),value)
var item_queue:Dictionary={"Item":false,"Results":false,}
var turn_order:Array[StringName]
var turn_counter:int = 0
var early_end:bool = false
#global effects
var global_effects := {}
#animations
var effect_queue:= []
var sequencing_units := {}
var bar_queue:= []
#Camera
var cam_con:CameraController
#AI
var ai_target:Unit
#deployment
var stored_unit : Unit
var stored_cell : Vector2i = Vector2i(-1,-1)
#Queued events
var exp_events:Array[Dictionary] = []
var active_died:bool = true

#region init/ready/process
func _init():
	pass


func _ready():
	if !cam_con: cam_con = CameraController.new(get_viewport())
	_connect_general_signals()


func _process(_delta):
	if state != STATES.LOADING: _check_step()
#endregion


#region saving/loading
func save() -> Dictionary:
	var saveData:Dictionary = {
		"DataType":"GameBoard",
		"state":state,
		"turn_step":turn_step,
	}
	return saveData


func load_data(save_data:Dictionary):
	pass
#endregion


#region gameflow stepping
func _check_step():
	match state:
		STATES.NEW_TURN: _start_next_turn()
		STATES.PLAYER_PHASE: _check_player_turn_step()
		STATES.ENEMY_PHASE: _check_enemy_turn_step()
		STATES.ROUND_END: _check_eor_events()


func _match_step(step):
	pass
#endregion


#region signal connection
func _connect_general_signals():
	#self.gb_ready.connect(GameState.set_new_state)
	cursor.cursor_moved.connect(self._on_cursor_moved)
	SignalTower.sequence_complete.connect(self._on_animation_handler_sequence_complete)
	
#endregion


#region map loading
func load_map(map:String, save_data:Dictionary={}):
	var newMap:GameMap
	state = STATES.LOADING
	map_loader = MapLoader.new()
	map_loader.map_loaded.connect(self._on_map_loaded)
	newMap = map_loader.load_map(map, save_data)
	current_map = newMap
	add_child(newMap)
	map_added.emit(newMap)


func free_map()->void:
	reset_flags()
	#turnComplete = false # find a better place to reinitialize this and above value HERE
	PlayerData.purge_npc_data()
	if current_map:
		current_map.queue_free()
		await current_map.tree_exited
	SignalTower.time_reset.emit()
	map_freed.emit()


#func _on_map_ready():
	#if load_state == LOADING_STATES.NEW: call_deferred("_initialize_new_map")
	#else: 
		##current_map.units_reloaded.connect(self._on_units_reloaded)
		#await current_map.load_map_units()
		#call_deferred("_initialize_new_map")

#func _on_units_reloaded():
	#_initialize_new_map()

func _on_map_loaded():
	map_loader.queue_free()
	_load_units()


func _load_units():
	if !unit_loader:
		unit_loader = UnitLoader.new(self,save_enum,current_map)
		#unit_loader.master = self
		#unit_loader.save_enum = save_enum
		add_child(unit_loader)
	unit_loader.unit_removed.connect(self._remove_from_grid)
	unit_loader.units_loaded.connect(self._on_units_loaded)
	unit_loader.deploy_count_changed.connect(self._on_loader_deploy_count_changed)
	if save_enum == Enums.SAVE_TYPE.NONE or save_enum == Enums.SAVE_TYPE.TRANSITION: unit_loader.load_map_units(current_map,units,unit_refs)
	else: unit_loader.load_units_from_file(current_map,units,unit_refs)


func _on_unit_ready(unit:Unit)->void:
	if unit.FACTION_ID != Enums.FACTION_ID.PLAYER: return
	if !unit_loader: 
		unit_loader = UnitLoader.new(self,save_enum,current_map)
		#unit_loader.master = self
		#unit_loader.save_enum = save_enum
	unit_loader.post_load_unit(unit)


func _on_units_loaded():
	combatManager.init_manager()
	_cursor_toggle(false)
	ai = current_map.ai
	ai.init_ai(self)
	map_loaded.emit(current_map)
	state = STATES.LOADING


func _on_loader_deploy_count_changed(slots:int):
	deployment_count_updated.emit(slots)

#func _initialize_new_map():
	#units.clear()
	#_store_enemy_units()
	#await _initialize_units() 
	##_init_gamestate() used in the old state scripts. Could be deleted later.
	#
	 ##The Ai Manager is tied to the map... uhh.... I think this is so the AI values can be tweeked per map... 
	##but I could just have an AI tweaks that are read off from the map and applied to the AI manager at a different level?
	#
	#_set_game_time()
	
	


#func _set_game_time():
	#var newTime = Global.time_to_float(current_map.hours, current_map.minutes)
	#Global.game_time = newTime
	#check_passives() #This occured before units are even loaded in _initialize_new_map(), changed that
#endregion


#region map calls
func _get_lady_cell()->Vector2i:
	if lady: return lady.cell
	var ladyId = current_map.get_forced_deploy().keys()[0]
	for cell in units:
		if units[cell].unit_id == ladyId:
			lady = units[cell]
			break
	return lady.cell
#endregion


#region unit calls
func check_passives():
	for unit in units:
		units[unit].check_passives()


func _update_unit_terrain(unit:Unit): #HERE BROKEN
	unit.update_terrain_data()


func _move_active_unit(new_cell: Vector2i, set_path:Array[Vector2i]= []) -> void: #pathing related
	# Updates the units dictionary with the target position for the unit and asks the activeUnit to walk to it.
#	print("move_active: ", new_cell)
	var path = null
	var ai:bool
	if state == STATES.PLAYER_PHASE: ai = false
	else: ai = true
	turn_step = TURN_STEPS.UNIT_MOVING
	if !new_cell == activeUnit.cell and !ai:
		if is_occupied(new_cell) or not new_cell in walkable_cells: return
	
	#if !enemy:
		#GameState.change_state(self, GameState.gState.ACCEPT_PROMPT)
	current_map.pathAttack.clear()
	if !new_cell == activeUnit.cell:
		#print("it's walkable")
		# warning-ignore:return_value_discarded
		units.erase(activeUnit.cell)
		units[new_cell] = activeUnit
		if !ai:
			path = unit_path.current_path
		else:
			path = set_path
		activeUnit.walk_along(path,true)
		#unit_moving = true
		#await activeUnit.walk_finished


func _on_unit_walk_finished():
	_unit_at_destination()
	#if state == STATES.PLAYER_PHASE:
		#unit_move_ended.emit(activeUnit)
	#else:
		#turn_step = TURN_STEPS.AI_ACT
		#aimove_finished.emit()


func _unit_at_destination():
	unit_path.clear_path()
	turn_step = TURN_STEPS.MOVE_END


func _start_canto():
	turn_step = TURN_STEPS.PROCESSING
	PlayerData.canto_triggered = false
	#this will set off the canto features later. for now just skips over self and resolves trigger
	turn_step = TURN_STEPS.END_PHASE
#endregion


#region AI functions
#func _evaluate_position():
	#state = STATES.LOADING
	##call AI manager here, to pre-evaluate the position and gather data to be deliberated
	##Perhaps break this up into parts and peppering it in other steps that are gaurenteed to occur before enemy turn?
	##Use a signal on the last part to get the process going again, for now this just skips and sets to enemy_phase again
	#state = STATES.ENEMY_PHASE
#
#
#func _get_strategy():
	#state = STATES.LOADING
	#ai_step = AI_STEPS.PROCESS_TURN
	##Like _evaluate_position() only this time, turn instructions are returned for the gameboard to follow
#
#
#func _check_turn_instruct():
	#pass
	#This goes through elements of the turn instruction, playing out the turn step by step. Unnecessary and completed steps are skipped.
	#Process returns here between each step? Maybe move this to the function ALREADY doing that??? I dunno, need to draft better.
	#Select Unit>Move Unit>Initiate Action>Display Forecast>Effect Que>Event Que>End Phase>End

#endregion

#region events
func _run_event_queue()->void:
	turn_step = TURN_STEPS.PROCESSING
	current_map.check_map_completion()
	if active_died: _resolve_active_death()
	elif Global.meta_state == Global.META_STATES.GAME_OVER: turn_step = TURN_STEPS.END_PHASE
	#check game over or victory
	elif exp_events: turn_step = TURN_STEPS.EXP_GRANT
	else: turn_step = TURN_STEPS.END_PHASE


func _resolve_active_death():
	active_died = false
	match state:
		STATES.PLAYER_PHASE: turn_step = TURN_STEPS.EVENT_QUEUE
			#Enter a narrative scene playing state for the Unit's death, and then proceed with event queue
		STATES.ENEMY_PHASE,STATES.NPC_PHASE: turn_step = TURN_STEPS.EVENT_QUEUE
			#Like previous, check if narrative scene is tied to this character, and then proceed with event queue


func _resolve_exp():
	turn_step = TURN_STEPS.PROCESSING
	for event in exp_events:
		var recip:Unit
		var trig:Unit
		match event.Type:
			"Kill": 
				recip = event.Killer
				trig = event.Kill
		if recip:
			recip.add_exp(event.Type, trig)
			await continue_turn
	exp_events.clear()
	turn_step = TURN_STEPS.EVENT_QUEUE
#endregion


#region movement of unit objects
func on_unit_relocated(oldCell, newCell, unit): #updates unit locations with it's new location
	if units.has(oldCell):
		units.erase(oldCell)
	units[newCell] = unit
#endregion


#region removal, death and bar updates of units
func on_death_done(unit: Unit):
	#Plan to alter this down the line for Seiga fight, where fallen units will be cached instead of completely removed
	#Intention would be for Seiga to "reanimate" fallen units as part of her "danmaku"
	var addingExp = false
	if unit.FACTION_ID == Enums.FACTION_ID.ENEMY and unit.killer.FACTION_ID == Enums.FACTION_ID.PLAYER:
		var killer = unit.killer
		exp_events.append({"Type":"Kill","Killer":killer,"Kill":unit})
	add_to_death_list(unit)
	if unit == activeUnit: active_died = true
	#current_map.check_event(current_map.MAP_EVENT.DEATH, unit)
	
	# REVIEW THIS ONLY KEPT AS TO NOT LOSE IT
		#if unit.FACTION_ID == Enums.FACTION_ID.ENEMY:
		#var killer = unit.killer
		#addingExp = killer.add_exp("Kill", unit)
		#
	#if addingExp:
		#await self.continue_turn
		#unit.confirm_post_sequence_flags("Death")
	#else:
		#unit.confirm_post_sequence_flags("Death")
	#death_list.append(unit)
	#current_map.check_event(current_map.MAP_EVENT.DEATH, unit)


func add_to_death_list(unit:Unit):
	unit.visible = false
	unit.is_active = false
	death_list.append(unit)


func _wipe_dead():
	for dead in death_list:
		_clear_unit(dead)
	death_list.clear()


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



#endregion


#region unit EXP handling

	#emit_signal("exp_display", oldExp, expSteps, results, portrait, unitName)
#endregion

#region unit turn and action handling
func on_turn_complete(unit):
	pass
	#and mainCon.state != GameState.GB_END_OF_ROUND
	#PlayerData.save_unit_data()
	#if sequencingUnits.has(unit):
		#sequencingUnits[unit] = false
	#else: return
	#for u in sequencingUnits:
		#if sequencingUnits[u]:
			#return
	#GameState.change_state(self, GameState.gState.LOADING)
	#sequencingUnits.clear()
	#_deselect_active_unit(true)
	#turnComplete = true


func _on_item_used(item:Item):
	var targeting:Enums.SKILL_TARGET = item.target
	#{NONE, SELF, ALLY, ENEMY, MAP, SELF_ALLY}
	match targeting:
		Enums.SKILL_TARGET.NONE: _unfuck_turn()
		Enums.SKILL_TARGET.SELF: _self_use_item(item)
		Enums.SKILL_TARGET.MAP: _map_use_item(item)
		_: _target_use_item(item)


func _on_item_equipped(item:Item,is_equipping:bool):
	PlayerData.item_used = true
	if is_equipping: activeUnit.set_equipped(item)
	else: activeUnit.unequip(item)


func _on_unit_item_targeting(item, unit):
	activeUnit = unit
	start_item_targeting(item)


func _on_unit_item_activated(item:Consumable, unit:Unit, target:Unit)->void:
	_apply_item(item,unit,target)


func on_exp_gained(oldExp, expSteps, results, portrait, unitName):
	exp_display.emit(oldExp, expSteps, results, portrait, unitName)


func _on_exp_gain_exp_finished():
	#GameState.change_state(self, GameState.gState.LOADING)
	GameState.change_state()
	continue_turn.emit()


func unit_seize():
	unit_wait()


func unit_wait():
	#_deselect_active_unit(true)
	turn_step = TURN_STEPS.END_PHASE


func _self_use_item(item:Item):
	turn_step = TURN_STEPS.ITEM_QUEUED
	var results:=combatManager.use_item(activeUnit,activeUnit,item)
	item_queue["Item"] = item
	item_queue["Results"] = results[0]
	#{"Actor":false,"Type":false, "Target": false,"EffectId": effect, "Resisted": false, "Dmg": dmg, "Heal": false, "Comp": false, "Slayer": false}
	


func _play_item_results():
	var item:Item = item_queue.Item
	var results:Dictionary= item_queue.Results
	turn_step = TURN_STEPS.PROCESSING
	results.Actor.use_item(item)
	results.Target.receive_item(item)
	item_queue.clear()


func _on_unit_animation_complete(_unit:Unit):
	match last_step:
		TURN_STEPS.DOOR_TARGET: 
			cam_con.camera_control_complete.connect(self._door_conclude)
			reset_event_zoom()
			
		TURN_STEPS.ITEM_QUEUED: turn_step = TURN_STEPS.END_PHASE


func _door_conclude():
	cam_con.camera_control_complete.disconnect(self._door_conclude)
	if hp_bar_vis: get_tree().set_group("HPBar", "visible", true)
	turn_step = TURN_STEPS.END_PHASE


func _map_use_item(item:Item):
	pass


func _target_use_item(item:Item):
	pass


func _apply_item(item:Consumable, unit:Unit, _target:Unit): #HERE Unfinished
	var results = combatManager.use_item(unit, unit, item)
	turn_step = TURN_STEPS.ITEM_ANIMATION
	#insert map animations for items here
	_on_animation_handler_sequence_complete()
#endregion

#region targeting code
func _draw_range(unit : Unit, maxRange : int, minRange := 0):
	var path = _get_cells_in_range(unit.cell, maxRange, minRange,)
	snap_path = path
	cursor.bump_cursor()
	current_map.draw_attack(path)
	unit_path.stop()


func start_item_targeting(item:Item):
	active_action = {"Weapon": false, "Skill": null, "Item": item}
	_draw_range(activeUnit, item.min_reach, item.max_reach)
	turn_step = TURN_STEPS.ITEM_TARGET
	#GameState.change_state(self, GameState.gState.GB_ITEM_TARGETING)


func _get_cells_in_range(cell : Vector2i, maxRange : int, minRange : int)->Array: #HEX REF
	var hexStar = AHexGrid2D.new(current_map)
	var path :Array= hexStar.find_all_paths(cell, maxRange)
	if path.size() != 1 and minRange > 0:
		minRange = minRange - 1
		minRange = clampi(minRange, 0, 1000)
		var invalid = hexStar.find_all_paths(cell, minRange)
		path = hexStar.trim_path(path, invalid)
	return path


func start_attack_targeting():
	var reach :Dictionary = activeUnit.get_weapon_reach()
	turn_step = TURN_STEPS.ATTACK_TARGET
	active_action = {"Weapon": true, "Skill": null, "Item": null}
	#GameState.change_state(self, GameState.gState.GB_ATTACK_TARGETING)
	_draw_range(activeUnit, reach.Max, reach.Min)


func start_skill_targeting():
	var reach : Dictionary
	turn_step = TURN_STEPS.SKILL_TARGET
	active_action = {"Weapon": Global.activeSkill.augment, "Skill": Global.activeSkill, "Item": null}
	if active_action.Weapon: reach = activeUnit.get_aug_reach(active_action.Skill)
	else: reach = activeUnit.get_skill_reach(active_action.Skill)
	_draw_range(activeUnit, reach.Max, reach.Min)


func door_targeting():
	turn_step = TURN_STEPS.DOOR_TARGET
	_draw_range(activeUnit, 1, 1)


func _end_targeting():
	_wipe_region()
	current_map.pathAttack.clear()
	cursor.cell = activeUnit.cell
	gameboard_targeting_canceled.emit()
#endregion


#region cursor  functions
func gb_mouse_motion(_event):
	var mousePos: Vector2i = current_map.get_local_mouse_position()
	var toMap = current_map.ground.local_to_map(mousePos)
	var pos :Vector2i = Vector2i(toMap)
	#print(mousePos)
	match state:
		STATES.PLAYER_PHASE: _player_phase_mouse_motion(pos)
		STATES.FORMATION: cursor.cell = pos


func _player_phase_mouse_motion(position:Vector2i):
	match turn_step:
		TURN_STEPS.START: cursor.cell = position
		TURN_STEPS.MOVE_SEEK: cursor.cell = position
		TURN_STEPS.MOVE_REMAINING: cursor.cell = position
		TURN_STEPS.ATTACK_TARGET: cursor.cell = position
		TURN_STEPS.DOOR_TARGET: cursor.cell = position
		TURN_STEPS.SKILL_TARGET: cursor.cell = position
		


#not vetted
func _cursor_toggle(enable, snapLeader = true):
	if enable:
		cursor.visible = true
	else:
		cursor.visible = false
	if snapLeader:
		_snap_cursor()


func _snap_cursor(cell: Vector2i = _get_lady_cell()): #can be annoying to always have this tied to mouse, like before map starts.
	cursor.cell = cell
	var mouseWarp = cursor.get_global_transform_with_canvas()
	#mouseWarp = to_global(mouseWarp)
	print("Mouse Warp:", mouseWarp.origin)
	get_viewport().warp_mouse(mouseWarp.origin)
	cursor.align_camera()


func _on_cursor_moved(new_cell: Vector2i) -> void: #Pathing
	var path := []
	#safety measure, catches any uncleared cell storage that slips through the cracks
	if units.has(new_cell) and units[new_cell] == null: units.erase(new_cell)
	
	if state != STATES.PLAYER_PHASE or !activeUnit or !activeUnit.isSelected: return
	match turn_step:
		TURN_STEPS.MOVE_SEEK: path = _draw_initial_path(new_cell)
		TURN_STEPS.MOVE_REMAINING: path = _draw_segmented_path(new_cell)
		_: 
			unit_path.clear()
			return
	if path: unit_path.draw(path)
	#elif path_array and walkable_cells.has(new_cell): path = path_array + get_path_to_cell(path_array[-1], new_cell, activeUnit)
	#elif walkable_cells.has(new_cell): path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit)
	#elif new_cell == activeUnit.cell: unit_path.clear()
	#else: return


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
#endregion


#region input functions
func ui_return():
	match state:
		STATES.PLAYER_PHASE: _ui_return_player_phase()


func _ui_return_player_phase(): 
	match turn_step:
		TURN_STEPS.ACTIONS, TURN_STEPS.ACTIONS2:
			ui_returned.emit(turn_step)
		TURN_STEPS.MOVE_SEEK:
			turn_step = TURN_STEPS.ACTIONS
			_wipe_region()
			#_snap_cursor(activeUnit.cell)
			unit_selected.emit(activeUnit)
		TURN_STEPS.MOVE_REMAINING:
			_undo_segment()
			#revert_partial_move()
		TURN_STEPS.ATTACK_TARGET:
			turn_step = last_step #If turn_steps are acting out of line during testing, this is probably the culprit
			_end_targeting()
		TURN_STEPS.FORECAST_ATTACK:
			turn_step = last_step #
			ui_returned.emit(turn_step)
		TURN_STEPS.SKILL_TARGET:
			turn_step = last_step #
			_end_targeting()


func toggle_unit_profile(): 
	if GameState.state == GameState.gState.GB_PROFILE:
		toggle_prof.emit()
	elif focusUnit:
		toggle_prof.emit()
	else: toggle_extra_info()


func toggle_extra_info():
	#Toggles HP bars
	if hp_bar_vis == true:
		get_tree().set_group("HPBar", "visible", false)
		hp_bar_vis = false
	elif hp_bar_vis == false: 
		get_tree().set_group("HPBar", "visible", true)
		hp_bar_vis = true
	return


func on_directional_press(direction: Vector2i):
	var nextCell = cursor.cell + direction
	var newCell
	
	if GameState.state == GameState.gState.GB_PROFILE:
		return
		
	if snap_path and !snap_path.has(nextCell):
		newCell = find_next_best_cell(cursor.cell, nextCell)
		cursor.cell = newCell
	else: cursor.cell += direction


func find_next_best_cell(currentCell, nextCell): #it's still pretty jank, but atleast you can reach cells using direction keys using this. Without it, some cannot be reached during targeting.
	var shortestNext = 1000
	var shortestCurrent = 1000
	var nextBest
	var hexStar = AHexGrid2D.new(current_map)
	for cell in snap_path:
		var distanceNext = hexStar.find_distance(nextCell, cell)
		var distanceCurrent= hexStar.find_distance(currentCell, cell)
		if distanceNext <= shortestNext and distanceCurrent <= shortestCurrent and cell != currentCell:
			shortestNext = distanceNext
			shortestCurrent = distanceCurrent
			nextBest = cell
	return nextBest
#endregion

#region camera functions
func event_zoom():
	if !cam_con: cam_con = CameraController.new(get_viewport())
	if hp_bar_vis == true:
		get_tree().set_group("HPBar", "visible", false)
	cursor.visible = false
	cam_con.move_camera_unit(activeUnit.unit_id,0.7,Vector2(1.5,1.5),Tween.TransitionType.TRANS_BACK,Tween.EaseType.EASE_OUT)


func reset_event_zoom(): cam_con.reset_camera(true,0.7,Tween.TransitionType.TRANS_BACK,Tween.EaseType.EASE_IN)

#region selection functions
func select_cell(): #DEFAULT STATE: If a cell has a valid unit, selects it
	var occupied = is_occupied(cursor.cell)
	match state:
		STATES.PLAYER_PHASE: _player_phase_select()
	


func _player_phase_select():
	var cell :Vector2i = cursor.cell
	match turn_step:
		TURN_STEPS.START: _select_unit(cell)
		TURN_STEPS.MOVE_SEEK,TURN_STEPS.MOVE_REMAINING: select_destination()
		TURN_STEPS.ATTACK_TARGET: attack_target_selected()
		TURN_STEPS.DOOR_TARGET: door_target_selected()
		TURN_STEPS.SKILL_TARGET: _feature_target_selected(active_action.Skill)


func door_target_selected():
	if current_map.doors.has(cursor.cell):
		turn_step = TURN_STEPS.PROCESSING
		var dCell :Vector2i = cursor.cell
		_end_targeting()
		action_confirmed.emit()
		if !cam_con: cam_con = CameraController.new(get_viewport())
		cam_con.camera_control_complete.connect(self._door_zoom_complete.bind(dCell))
		event_zoom()
		


func _door_zoom_complete(cell:Vector2i):
	cam_con.camera_control_complete.disconnect(self._door_zoom_complete)
	PlayerData.canto_triggered = true
	activeUnit.pick_door(current_map.doors[cell])


func _select_unit(cell: Vector2i) -> void:
	# Selects the unit in the `cell` if there's one there.
	var occupied :bool= is_occupied(cell)
	if !occupied:
		turn_step == TURN_STEPS.OPTIONS
		cell_selected.emit(cell)
	elif units[cell].FACTION_ID == Enums.FACTION_ID.ENEMY: return ##Put attack range activation here
	elif !units.has(cell) or units[cell].status.Acted: return
	elif units[cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
		activeUnit = units[cell]
		#activeUnit.save_equip()
		activeUnit.isSelected = true
		#walkable_cells = get_walkable_cells(activeUnit)
		#current_map.draw(walkable_cells)
		#if !isAi: GameState.change_state(self, GameState.gState.GB_SELECTED)
		_snap_cursor(activeUnit.cell)
		unit_selected.emit(activeUnit)
		turn_step = TURN_STEPS.ACTIONS
	#	set_region_border(walkable_cells)


func _feature_target_selected(feature:SlotWrapper)-> void:
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
	if valid:
		turn_step = TURN_STEPS.FORECAST_ATTACK
		grab_target(cursor.cell)


func attack_target_selected():
	if is_occupied(cursor.cell) and !_check_friendly(activeUnit, focusUnit):
#				$Cursor.visible = false
		turn_step = TURN_STEPS.FORECAST_ATTACK
		grab_target(cursor.cell)


func grab_target(cell):
	#Called to assign values based on unit at cursor's coordinate
	var hexStar = AHexGrid2D.new(current_map)
	if not units.has(cell):
		print("oops")
		return
	var mode : int
	targetUnit = units[cell]
	var distance := hexStar.compute_cost(activeUnit.cell, targetUnit.cell, activeUnit) #HEX REF
	var reach := [distance, distance]
	if active_action.Weapon:
		combatManager.get_forecast(activeUnit, targetUnit, active_action)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mode = 0
	else:
		combatManager.get_forecast(activeUnit, targetUnit, active_action)
		mode = 1
	target_focused.emit(mode, reach)


func move_selection(isAi := false):
	turn_step = TURN_STEPS.MOVE_SEEK
	#_snap_cursor(activeUnit.cell)
	walkable_cells = get_walkable_cells(activeUnit)
	current_map.draw(walkable_cells)
	#if !isAi: GameState.change_state(self, GameState.gState.GB_SELECTED)


func select_destination() -> void: #SELECTED STATE Pathing Related
	var cell:Vector2i = cursor.cell
	var isOccupied = is_occupied(cell)
	var isWalkable = walkable_cells.has(cell)
	var moveRemain :int = activeUnit.active_stats.Move - unit_path.path_array.size()
	if !isOccupied and isWalkable and moveRemain > 0 and !unit_path.path_array.has(cell):
		unit_path.update_pathing_array(activeUnit,cell,current_map)
		moveRemain = activeUnit.active_stats.Move - unit_path.path_array.size()
		_update_walkable_range(moveRemain)
		turn_step = TURN_STEPS.MOVE_REMAINING
	elif cell == activeUnit.cell:
		_unit_at_destination()
	elif !isWalkable or isOccupied: return
	elif unit_path.path_array[-1] == cell:
		_move_active_unit(cell)


func is_occupied(cell: Vector2i) -> bool:
		return units.has(cell)


func select_formation_cell():
	var deploymentCells :Array[Vector2i] = current_map.get_deployment_cells()
	if deploymentCells.has(cursor.cell) and is_occupied(cursor.cell) and stored_unit == null:
		stored_unit = units[cursor.cell]
		stored_cell = cursor.cell
		stored_unit.isSelected = true
	elif deploymentCells.has(cursor.cell) and is_occupied(cursor.cell):
		_deploy_swap(stored_unit, units[cursor.cell])
		# swap function here
	elif deploymentCells.has(cursor.cell) and stored_cell != Vector2i(-1,-1):
		stored_cell = cursor.cell
	elif deploymentCells.has(cursor.cell):
		_deploy_swap(stored_unit, stored_cell)
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
	if stored_unit == null and stored_cell == defValue:
		_cursor_toggle(false)
		state = STATES.IDLE
		formation_closed.emit()
	if stored_unit != null:
		stored_unit.isSelected = false
		stored_unit = null
	if stored_cell != defValue:
		stored_cell = defValue
#endregion


#region GUI Signals
func _on_gui_manager_deploy_toggled(unit, deployed):
#	var unit = unitObjs[unit_id]
	if deployed:
		unit_loader.undeploy_unit(unit)
	else:
		unit_loader.deploy_unit(unit)
#endregion


#region chapter start
func _on_gui_manager_map_started():
	begin_chapter()
	
	_randomize_rolls()


func begin_chapter():
	for unit in units:
		units[unit].map_start_init()
	chapter_started = true
	_cursor_toggle(true)
	current_map.hide_deployment()
	GameState.clear_state_lists()
	GameState.change_state(self, GameState.gState.GB_DEFAULT)
	_initialize_turns()
	#call_deferred("set_process", true)
#endregion


#region utility funcs
func _randomize_rolls():
	var rng:=RngTool.new()
	rng.random()


func reset_flags():
	Global.reset_map_flags()
	units.clear()
	chapter_started = false
	#state = STATES.LOADING
	#map_end = false
	#aiTurn = false
	#aiNeedAct = false
	#turnComplete = false
	#endOfRound = false
	#startNextTurn = false


func _clear_player_action_flags():
	PlayerData.move_committed = false
	PlayerData.traded = false
	PlayerData.item_used = false
	PlayerData.canto_triggered = false


func _unfuck_turn():
	print("[Gameboard/_unfuck_turn] Attempted undoable action. Ending Turn.")
	turn_step = TURN_STEPS.END_PHASE


func _check_friendly(unit1, unit2, sameOnly:=false) ->bool:
	if unit1.FACTION_ID == unit2.FACTION_ID: return true
	elif !sameOnly and unit1.FACTION_ID != Enums.FACTION_ID.ENEMY and unit2.FACTION_ID != Enums.FACTION_ID.ENEMY: return true
	return false
#endregion


#region pathing
func get_path_to_cell(start:Vector2i, end:Vector2i, unit = false)->Array[Vector2i]: #Pathing
	var hexStar = AHexGrid2D.new(current_map)
	return hexStar.find_path(start, end, unit) #HEX REF


func _wipe_region():
	snap_path.clear()
	current_map.pathAttack.clear()


func _wipe_attack():
	current_map.pathAttack.clear()


func get_walkable_cells(unit: Unit) -> Array: #Pathing
	var hexStar = AHexGrid2D.new(current_map)
	var path = hexStar.find_all_unit_paths(unit)
	return path


#func _update_pathing_array(wayPoint:Vector2i): #Pathing
	#var path :Array[Vector2i]= []
	#var start : Vector2i = activeUnit.cell
	#if path_array: start = path_array[-1]
	#path = get_path_to_cell(start, wayPoint, activeUnit)
	#path_array.append_array(path)


func _update_walkable_range(moveRemain:int = 0):
	var hexStar = AHexGrid2D.new(current_map)
	var newArea :Array = []
	if !unit_path.path_array: newArea = get_walkable_cells(activeUnit)
	else: newArea = hexStar.find_remaining_unit_paths(activeUnit, unit_path.path_array[-1], moveRemain)
	current_map.draw(newArea)


func _draw_initial_path(new_cell:Vector2i) ->Array[Vector2i]: 
	var path:Array[Vector2i] = []
	if 	new_cell == activeUnit.cell: unit_path.clear_path()
	elif walkable_cells.has(new_cell): 
		path = get_path_to_cell(activeUnit.cell, new_cell, activeUnit)
		#path = path.pop_front()
	return path


func _draw_segmented_path(new_cell:Vector2i) ->Array[Vector2i]:
	var path:Array[Vector2i] = []
	if new_cell == activeUnit.cell: path = unit_path.path_array
	else: path = unit_path.path_array + get_path_to_cell(unit_path.path_array[-1], new_cell, activeUnit)
	return path


func _undo_segment():
	var moveRemain :int 
	unit_path.remove_last_segment()
	moveRemain = activeUnit.active_stats.Move - unit_path.path_array.size()
	_update_walkable_range(moveRemain)
	if !unit_path.path_array:
		unit_path.clear()
		turn_step = TURN_STEPS.MOVE_SEEK
	else:
		unit_path.draw(unit_path.path_array)
#endregion


#region turn tracker
func _initialize_turns(ignoreActed := false): #not quite right Groups might be the problem, just use faction ID
	turn_order.clear()
	for cell in units: #grab unit locations
		var unit = units[cell]
		if ignoreActed and unit.status.Acted:
			continue
		else: unit.set_acted(false)
		match unit.FACTION_ID: #turn order initializing
			Enums.FACTION_ID.PLAYER: turn_order.append("Player")
			Enums.FACTION_ID.ENEMY: turn_order.append("Enemy")
			Enums.FACTION_ID.NPC: turn_order.append("NPC")
		_update_unit_terrain(unit) #update terrain data
	turn_order = turn_sort.sort_turns(turn_order)
	#aiTurn = false
	#boardState.update_remaining_turns(turn_order)
	new_round.emit(turn_order)
	state = STATES.NEW_TURN
	print(turn_order)


func turn_change():
	#change turn
#	ai.rein_units(units)
	#boardState.update_unit_data(units)
	turn_order.pop_front()
	turn_counter += 1
	if turn_order.size() == 0:
		state = STATES.ROUND_END
		#round_change()
	else:
		state = STATES.NEW_TURN
		turn_step = TURN_STEPS.STAND_BY
	#boardState.update_remaining_turns(turn_order)
	print(turn_order)
	GameState.clear_state_lists()
	_clear_player_action_flags()
	turn_changed.emit()


func _start_next_turn():
	if turn_order[0] == "Enemy":
		GameState.change_state(self, GameState.gState.LOADING)
		state = STATES.ENEMY_PHASE
		print("Enemy Turn")
		_cursor_toggle(false)
	elif turn_order[0] == "Player":	
		GameState.change_state(self, GameState.gState.GB_DEFAULT)
		state = STATES.PLAYER_PHASE
		print("Player Turn")
		_cursor_toggle(true)
	elif turn_order[0] == "NPC": #Currently, NPC turns aren't a feature of the AI
		GameState.change_state(self, GameState.gState.LOADING)
		state = STATES.NPC_PHASE
		print("NPC Turn")
		_cursor_toggle(false)

	if state == STATES.PLAYER_PHASE and early_end:
		GameState.change_state(self, GameState.gState.LOADING)
		set_next_acted()
		turn_step = TURN_STEPS.END_PHASE
		


func _add_turn(faction):
	var team : StringName
	match faction:
		Enums.FACTION_ID.PLAYER: team = "Player"
		Enums.FACTION_ID.ENEMY: team = "Enemy"
		Enums.FACTION_ID.NPC: team = "NPC"
	turn_order.append(team)
	turn_added.emit(team)


func _remove_turn(teamId):
	var team : StringName
	print("Before Removed Turn:",turn_order)
	match teamId:
		Enums.FACTION_ID.PLAYER: team = "Player"
		Enums.FACTION_ID.ENEMY: team = "Enemy"
		Enums.FACTION_ID.NPC: team = "NPC"
	if turn_order[0] != team:
		var i = turn_order.rfind(team)
		turn_order.remove_at(i)
	print("Removed Turn:",team, ":",turn_order)
	turn_removed.emit(team)


func set_next_acted():
	for cell in units:
		if !units[cell].status.Acted and units[cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
			units[cell].set_acted(true)
			return
#endregion


#region turn steps
func _check_player_turn_step():
	match turn_step:
		TURN_STEPS.STAND_BY: _stand_by_step()
		TURN_STEPS.ITEM_QUEUED: _play_item_results()
		TURN_STEPS.MOVE_END:
			turn_step = TURN_STEPS.ACTIONS2
			unit_move_ended.emit(activeUnit)
		TURN_STEPS.EFFECT_QUEUE: _run_effect_queue()
		TURN_STEPS.EVENT_QUEUE: _run_event_queue()
		TURN_STEPS.EXP_GRANT: _resolve_exp()
		TURN_STEPS.END_PHASE: _check_end_of_turn()
		TURN_STEPS.CANTO: _start_canto()
		TURN_STEPS.END:
			if activeUnit: activeUnit.set_acted(true)
			_check_next_state()


func _check_enemy_turn_step():
	#if activeUnit: activeUnit.set_acted(true)
	_check_next_state()
	#match ai_step:
		#AI_STEPS.STAND_BY: _stand_by_step()
		#AI_STEPS.START: _get_strategy()
		#AI_STEPS.PROCESS_TURN: _check_turn_instruct()


func _stand_by_step():
	##This is for functions that need to slip it before a new turn starts
	#_evaluate_position()
	turn_step = TURN_STEPS.START
	

func _check_end_of_turn():
	if death_list: await _wipe_dead()
	
	if !activeUnit: turn_step = TURN_STEPS.END
	elif activeUnit.can_canto(): turn_step = TURN_STEPS.CANTO
	else: turn_step = TURN_STEPS.END


func _check_next_state():
	match Global.meta_state:
		Global.META_STATES.GAME_OVER: state = STATES.GAME_OVER
		Global.META_STATES.VICTORY: state = STATES.VICTORY
		_: turn_change()
#endregion


#region end of round functions
func round_change():
	#Changes the round and reloads the "turn order" magazine
	#Return HERE to make sure turns flow properly, I can already see conflicting issues cropping up
	early_end = false
	_initialize_turns()
	#boardState.clear_acted()
	new_round.emit(turn_order)


func round_duration_tick():
	var keys = global_effects.keys()
	for effId in keys:
		global_effects[effId].duration -= 1
		if global_effects[effId].duration <= 0 and global_effects[effId].type == "Time":
			Global.reset_time_factor()
			global_effects.erase(effId)
		else: #no other global effects exist, this needs to be expanded if a new one is made
			global_effects.erase(effId)


func _check_eor_events()->void:
	if cursor.visible:cursor.visible = false
	if GameState.state != GameState.gState.GB_END_OF_ROUND: GameState.change_state(self, GameState.gState.GB_END_OF_ROUND)
	#if round_step != ROUND_STEPS.CHECK: return
	match round_step:
		ROUND_STEPS.CHECK:
			round_step = ROUND_STEPS.DANMAKU
		ROUND_STEPS.DANMAKU:
			round_step = ROUND_STEPS.SCENE
		ROUND_STEPS.SCENE: 
			round_step = ROUND_STEPS.REINFORCE
		ROUND_STEPS.REINFORCE: 
			round_step = ROUND_STEPS.END
		ROUND_STEPS.END:
			round_duration_tick()
			round_change()
			state = STATES.NEW_TURN
	#if danmaku.size() > 0:
		#_progress_danmaku_path()
		#await self.danmaku_pathing_complete
	#dmkScriptProgressing = true
	#if !cc: 
		#cc = CameraController.new(get_viewport())
	
	
	#current_map.progress_danmaku_script()
#endregion


#region combat functions
func _on_inventory_weapon_changed(button) -> void:
	var i = button.get_meta("Item")
	if button.disabled:
		return
	activeUnit._equip_weapon(i) #See if it can find it's own index based on ID?
	combatManager.get_forecast(activeUnit, targetUnit, active_action)


func _on_action_weapon_selected(button = false):
	var combatResults
	var target :Unit= focusUnit
	turn_step = TURN_STEPS.COMBAT_DISPLAY
	if state == STATES.ENEMY_PHASE or state == STATES.NPC_PHASE:
		target = ai_target
	sequencing_units[activeUnit] = true
	sequencing_units[target] = true
	if active_action.Weapon and button:
		var weapon = button.get_meta("Item")
		activeUnit.set_equipped(weapon)
	combatResults = combatManager.start_the_justice(activeUnit,target, active_action)
	#print(str(combatResults))
	combat_sequence(combatResults)
	#boardState.add_acted(activeUnit)
	#activeUnit.set_acted(true)
#endregion


#region animation handling
func _on_animation_handler_sequence_complete():
	var hasPostEvents = _check_effect_queue()
	GameState.change_state(self, GameState.gState.GB_DEFAULT)
	
	if hasPostEvents: turn_step = TURN_STEPS.EFFECT_QUEUE
	else: _update_unit_bars()
	


func _update_unit_bars():
	turn_step = TURN_STEPS.BAR_ANIM
	bar_queue.append(activeUnit)
	bar_queue.append(focusUnit)
	activeUnit.update_life_bar()
	targetUnit.update_life_bar()


func _on_bars_updated(unit:Unit):
	bar_queue.erase(unit)
	if !bar_queue:
		match turn_step:
			TURN_STEPS.BAR_ANIM: turn_step = TURN_STEPS.EVENT_QUEUE


func _check_effect_queue() -> bool:
	if effect_queue.size() > 0:
		return true
	return false


func _run_effect_queue():
	var postEvents = _sort_effect_queue()
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
	call_deferred("_clear_effect_queue")


func on_effect_complete():
	continue_queue.emit()
	_update_unit_bars()


func _sort_effect_queue():
	var seen := {}
	var postEvents := {}
	for event in effect_queue:
		if !postEvents.has(event.Actor):
			postEvents[event.Actor] = []
			seen[event.Actor] = []
		if seen[event.Actor].has(event.Type):
			continue
		else:
			seen[event.Actor].append(event.Type)
			postEvents[event.Actor].append(event)
	return postEvents


func add_effect_queue(new):
	effect_queue.append(new)


func _clear_effect_queue():
	effect_queue.clear()
	turn_step = TURN_STEPS.EVENT_QUEUE


func combat_sequence(scenario):
	SignalTower.emit_signal("sequence_initiated", scenario)
#endregion


#region cell selection, active, and focus handling
func request_deselect():
	_wipe_region()
	current_map.pathAttack.clear()
	#GameState.change_state(self, GameState.gState.GB_DEFAULT)
	_deselect_active_unit(false)
	
	
func _deselect_active_unit(confirm) -> void:
	# Deselects the active unit, clearing the cells overlay and interactive path drawing
	#confirm is used to let the game know if this is a temporary movement(can be canceled by player) 
	#or a confirmed move so it knows to retain previous position or update the units dictionary
	#NEW: HERE setting confirm to "true" is not currently used anywhere.
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
			#boardState.add_acted(activeUnit)
			activeUnit.set_acted(true)
		_snap_cursor(activeUnit.cell)
		activeUnit.isSelected = false
		
	_clear_active_unit()
	current_map.pathAttack.clear()
	unit_path.stop()
	unit_path.clear_path()


func _clear_active_unit() -> void:
	# Clears the reference to the activeUnit and the corresponding walkable cells
	activeUnit = null
	walkable_cells.clear()
#endregion


#region gui signals
func _on_gui_formation_selected():
	match GameState.state:
		GameState.gState.GB_SETUP:
			_cursor_toggle(true, true)
			GameState.change_state(self, GameState.gState.GB_FORMATION)
			state = STATES.FORMATION
		GameState.gState.GB_FORMATION:
			_cursor_toggle(false)
			state = STATES.IDLE


func _on_gui_set_up_loaded():
	state = STATES.IDLE


func _on_gui_action_menu_canceled():
	match state:
		STATES.PLAYER_PHASE: _player_phase_menu_canceled()
	


func _player_phase_menu_canceled():
	match turn_step:
		TURN_STEPS.ACTIONS: 
			turn_step = TURN_STEPS.START
			request_deselect()
		TURN_STEPS.FORECAST_ATTACK:
			activeUnit.restore_equip()
			start_attack_targeting()
		
		#start_skill_targeting()
		#start_item_targeting(active_action.Item)
#endregion


#region commented out code. Delete later
##region deploy functions
#func _deploy_unit(unit:Unit, forced = false, spawnLoc = Vector2i(0,0)):
	#var roster := PlayerData.rosterData
	#if forced:
		#unit.deployment = Enums.DEPLOYMENT.FORCED
	#else:
		#spawnLoc = _first_available_dep_cell()
		#unit.deployment = Enums.DEPLOYMENT.DEPLOYED
	#if filledSlots < depCap:
		#unit.visible = true
		#unit.is_active = true
		#if save_enum != Enums.SAVE_TYPE.SUSPENDED: unit.relocate_unit(spawnLoc)
		#filledSlots += 1
		#roster
		#_update_roster_label()
	#else:
		#print("Roster Full")
#
#
#func _undeploy_unit(unit:Unit, ini = false):
	#var spawnLoc = Vector2i(0,0)
	#if unit.deployment != Enums.DEPLOYMENT.FORCED:
		#unit.visible = false
		#unit.is_active = false
		#unit.deployment = Enums.DEPLOYMENT.UNDEPLOYED
		#_remove_from_grid(unit)
		#unit.relocate_unit(spawnLoc, false)
	#else:
		#print("Must deploy: " + unit.unit_id)
	#if unit.deployment != Enums.DEPLOYMENT.FORCED and !ini:
		#filledSlots -= 1
		#_update_roster_label()
#
#
#func _first_available_dep_cell():
	#var firstCell = null
	#var filled = units.keys()
	#for cell in deploymentCells:
		#if !filled.has(cell):
			#firstCell = cell
			#break
	#return firstCell
##endregion
#endregion
