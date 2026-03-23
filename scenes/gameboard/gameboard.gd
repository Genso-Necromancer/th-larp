extends Node
class_name GameBoard

#New Control Functions
# _connect_signals
# _connect_gui_signals
# _set_active_action
# _begin_targeting_for_active_action



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

#combat results
# CombatEngine handoff
var last_forecast: CombatResults = null
var last_combat_results: CombatResults = null
var action_context := {
	"Actor": null,
	"Target": null,
	"Action": {"Weapon": false, "Skill": null, "Item": null},
	"Forecast": null,
	"Results": null,
}

func get_last_forecast() -> CombatResults:
	return action_context.Forecast

func get_last_combat_results() -> CombatResults:
	return action_context.Results


func get_action_context() -> Dictionary:
	return action_context


func _set_action_actor(unit: Unit) -> void:
	action_context.Actor = unit


func _set_action_target(unit: Unit) -> void:
	targetUnit = unit
	action_context.Target = unit


func _set_action_forecast(results: CombatResults) -> void:
	last_forecast = results
	action_context.Forecast = results


func _set_action_results(results: CombatResults) -> void:
	last_combat_results = results
	action_context.Results = results


func _clear_action_target() -> void:
	targetUnit = null
	action_context.Target = null
	_set_action_forecast(null)
	_set_action_results(null)


func _reset_action_context() -> void:
	_set_action_actor(activeUnit)
	_clear_action_target()
	_set_active_action(false, null, null)


func _snapshot_active_unit_equipment() -> void:
	selection_equipment_snapshot.clear()
	if activeUnit == null:
		return
	selection_equipment_snapshot = activeUnit.equipment_helper.snapshot_equipment_state()


func _restore_active_unit_equipment() -> void:
	if activeUnit == null:
		return
	activeUnit.equipment_helper.restore_equipment_state(selection_equipment_snapshot)
	selection_equipment_snapshot.clear()


func rollback_pending_selection_state() -> void:
	if activeUnit == null:
		return
	if selection_equipment_snapshot.is_empty():
		return
	_restore_active_unit_equipment()

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
var selection_equipment_snapshot: Array[Dictionary] = []
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
enum TURN_STEPS {STAND_BY,PROCESSING,START,END_PHASE,END,OPTIONS,ACTIONS,MOVE_SEEK,MOVE_REMAINING,UNIT_MOVING,MOVE_END,ACTIONS2,AI_ACT,ITEM_QUEUED,ITEM_ANIMATION,ITEM_TARGET,ATTACK_TARGET,DOOR_TARGET,TRADE_TARGET,SKILL_TARGET,FORECAST_ATTACK,COMBAT_DISPLAY,EFFECT_QUEUE,BAR_ANIM,EVENT_QUEUE,EXP_GRANT,CANTO}
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

#GUI
var guiManager:GUIManager:
	set(value):
		guiManager = value
		if is_inside_tree():
			_connect_gui_signals()
var player_action_controller: PlayerActionController
var board_targeting: BoardTargeting
var board_unit_registry: BoardUnitRegistry

#region init/ready/process
func _init():
	pass


func _ready():
	if !cam_con: cam_con = CameraController.new(get_viewport())
	player_action_controller = PlayerActionController.new(self)
	board_targeting = BoardTargeting.new(self)
	board_unit_registry = BoardUnitRegistry.new(self)
	_connect_signals()


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
func _connect_signals():
	_connect_general_signals()
	_connect_gui_signals()

func _connect_general_signals():
	#self.gb_ready.connect(GameState.set_new_state)
	cursor.cursor_moved.connect(self._on_cursor_moved)
	SignalTower.sequence_complete.connect(self._on_animation_handler_sequence_complete)

func _connect_gui_signals():
	if guiManager == null: 
		return
	if not guiManager.ui_move_selected.is_connected(_on_gui_move_selected):
		guiManager.ui_move_selected.connect(_on_gui_move_selected)
	if not guiManager.ui_attack_selected.is_connected(_on_gui_attack_selected):
		guiManager.ui_attack_selected.connect(_on_gui_attack_selected)
	if not guiManager.ui_skill_selected.is_connected(_on_gui_skill_selected):
		guiManager.ui_skill_selected.connect(_on_gui_skill_selected)
	if not guiManager.ui_item_selected.is_connected(_on_gui_item_selected):
		guiManager.ui_item_selected.connect(_on_gui_item_selected)
	if not guiManager.ui_trade_selected.is_connected(_on_gui_trade_selected):
		guiManager.ui_trade_selected.connect(_on_gui_trade_selected)
	if not guiManager.ui_wait_selected.is_connected(_on_gui_wait_selected):
		guiManager.ui_wait_selected.connect(_on_gui_wait_selected)
	if not guiManager.ui_ofuda_selected.is_connected(_on_gui_ofuda_selected):
		guiManager.ui_ofuda_selected.connect(_on_gui_ofuda_selected)
	if not guiManager.ui_door_selected.is_connected(_on_gui_door_selected):
		guiManager.ui_door_selected.connect(_on_gui_door_selected)
	if not guiManager.ui_seize_selected.is_connected(_on_gui_seize_selected):
		guiManager.ui_seize_selected.connect(_on_gui_seize_selected)
	if not guiManager.ui_suspend_requested.is_connected(_on_gui_suspend_requested):
		guiManager.ui_suspend_requested.connect(_on_gui_suspend_requested)
	if not guiManager.ui_action_menu_canceled.is_connected(_on_gui_action_menu_canceled):
		guiManager.ui_action_menu_canceled.connect(_on_gui_action_menu_canceled)
	
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
		board_unit_registry.relocate_unit(activeUnit.cell, new_cell, activeUnit)
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
	PlayerData.move_committed = true
	turn_step = TURN_STEPS.MOVE_END


func _start_canto():
	turn_step = TURN_STEPS.PROCESSING
	PlayerData.canto_triggered = false
	#this will set off the canto features later. for now just skips over self and resolves trigger
	turn_step = TURN_STEPS.END_PHASE
#endregion


#region AI functions


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
	board_unit_registry.relocate_unit(oldCell, newCell, unit)
#endregion


#region removal, death and bar updates of units
func on_death_done(unit: Unit):
	#Plan to alter this down the line for Seiga fight, where fallen units will be cached instead of completely removed
	#Intention would be for Seiga to "reanimate" fallen units as part of her "danmaku"
	#var addingExp = false
	var killer:= unit.killer
	if !killer: 
		print("[Unit]on_death_done: invalid or null killer")
		pass
	elif unit.FACTION_ID == Enums.FACTION_ID.ENEMY and killer.FACTION_ID == Enums.FACTION_ID.PLAYER:
		exp_events.append({"Type":"Kill","Killer":killer,"Kill":unit})
	add_to_death_list(unit)
	if unit == activeUnit: active_died = true



func add_to_death_list(unit:Unit):
	board_unit_registry.add_to_death_list(unit)


func _wipe_dead():
	board_unit_registry.wipe_dead()


func _clear_unit(unit):
	board_unit_registry.clear_unit(unit)
	#clear non-player units from unitData HERE!!!


func _remove_from_grid(unit: Unit):
	board_unit_registry.remove_from_grid(unit)



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
	PlayerData.item_used = true
	var targeting:Enums.SKILL_TARGET = item.target
	#{NONE, SELF, ALLY, ENEMY, MAP, SELF_ALLY}
	match targeting:
		Enums.SKILL_TARGET.NONE: _unfuck_turn()
		Enums.SKILL_TARGET.SELF: _self_use_item(item)
		Enums.SKILL_TARGET.MAP: _map_use_item(item)
		_: _target_use_item(item)


func _on_item_equipped(item:Item,is_equipping:bool):
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


func _self_use_item(item: Item):
	if activeUnit == null:
		return
	var consumable := item as Consumable
	if consumable == null:
		push_error("[GameBoard/_self_use_item] Expected Consumable, got %s" % [item])
		return
	turn_step = TURN_STEPS.PROCESSING
	var results: CombatResults = _resolve_item_action(activeUnit, activeUnit, consumable)
	item_queue["Item"] = item
	item_queue["Results"] = results
	_unfuck_turn()
	


#func _play_item_results():
	#var item:Item = item_queue.Item
	#var results:Dictionary= item_queue.Results
	#turn_step = TURN_STEPS.PROCESSING
	#results.Actor.use_item(item)
	#results.Target.receive_item(item)
	#item_queue.clear()


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
	var target := _target if _target != null else unit
	if unit == null or target == null:
		return
	var results: CombatResults = _resolve_item_action(unit, target, item)
	item_queue["Item"] = item
	item_queue["Results"] = results
	_unfuck_turn()
#endregion

#region targeting code
#region newly added
func _begin_targeting_for_active_action() -> void:
	player_action_controller.begin_targeting_for_active_action()
#endregion

func _draw_range(unit : Unit, maxRange : int, minRange := 0):
	board_targeting.draw_range(unit, maxRange, minRange)


func _get_cells_in_range(cell : Vector2i, maxRange : int, minRange : int)->Array: #HEX REF
	return board_targeting.get_cells_in_range(cell, maxRange, minRange)


func start_attack_targeting():
	board_targeting.start_attack_targeting()


func start_skill_targeting(skill = null):
	board_targeting.start_skill_targeting(skill)


func start_item_targeting(item: Consumable):
	board_targeting.start_item_targeting(item)

func door_targeting():
	board_targeting.door_targeting()


func seek_trade(unit: Unit = activeUnit) -> void:
	board_targeting.seek_trade(unit)


func _end_targeting():
	board_targeting.end_targeting()


func end_targeting() -> void:
	_end_targeting()


func trade_target_selected() -> void:
	board_targeting.trade_target_selected()
#endregion

#region action code
#NEW
func _begin_attack_action() -> void:
	player_action_controller.begin_attack_action()

func _begin_skill_action(skill) -> void:
	player_action_controller.begin_skill_action(skill)

func _commit_wait_action() -> void:
	player_action_controller.commit_wait_action()

func _cancel_action_menu_flow() -> void:
	player_action_controller.cancel_action_menu_flow()


func _resume_targeting_for_active_action() -> void:
	player_action_controller.resume_targeting_for_active_action()
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
		TURN_STEPS.TRADE_TARGET: cursor.cell = position
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


func _get_post_target_menu_step() -> TURN_STEPS:
	if PlayerData.move_committed:
		return TURN_STEPS.ACTIONS2
	return TURN_STEPS.ACTIONS


func _ui_return_player_phase(): 
	match turn_step:
		TURN_STEPS.OPTIONS:
			turn_step = TURN_STEPS.START
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
			turn_step = _get_post_target_menu_step()
			_end_targeting()
		TURN_STEPS.FORECAST_ATTACK:
			turn_step = TURN_STEPS.ATTACK_TARGET
			ui_returned.emit(TURN_STEPS.FORECAST_ATTACK)
		TURN_STEPS.SKILL_TARGET:
			turn_step = _get_post_target_menu_step()
			_end_targeting()
		TURN_STEPS.ITEM_TARGET:
			turn_step = _get_post_target_menu_step()
			_end_targeting()
		TURN_STEPS.DOOR_TARGET:
			turn_step = _get_post_target_menu_step()
			_end_targeting()
		TURN_STEPS.TRADE_TARGET:
			turn_step = _get_post_target_menu_step()
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
		TURN_STEPS.TRADE_TARGET: trade_target_selected()
		TURN_STEPS.SKILL_TARGET: _feature_target_selected(active_action.Skill)
		TURN_STEPS.ITEM_TARGET: _feature_target_selected(active_action.Item)


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


func object_target_selected() -> void:
	door_target_selected()


func _select_unit(cell: Vector2i) -> void:
	# Selects the unit in the `cell` if there's one there.
	var occupied :bool= is_occupied(cell)
	if !occupied:
		turn_step = TURN_STEPS.OPTIONS
		cell_selected.emit(cell)
	elif units[cell].FACTION_ID == Enums.FACTION_ID.ENEMY: return ##Put attack range activation here
	elif !units.has(cell) or units[cell].status.Acted: return
	elif units[cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
		activeUnit = units[cell]
		_reset_action_context()
		_snapshot_active_unit_equipment()
		activeUnit.isSelected = true
		#walkable_cells = get_walkable_cells(activeUnit)
		#current_map.draw(walkable_cells)
		#if !isAi: GameState.change_state(self, GameState.gState.GB_SELECTED)
		_snap_cursor(activeUnit.cell)
		unit_selected.emit(activeUnit)
		turn_step = TURN_STEPS.ACTIONS
	#	set_region_border(walkable_cells)


func _feature_target_selected(feature:SlotWrapper)-> void:
	board_targeting.feature_target_selected(feature)


func skill_target_selected() -> void:
	_feature_target_selected(active_action.Skill)


func attack_target_selected():
	board_targeting.attack_target_selected()


func grab_target(cell):
	board_targeting.grab_target(cell)


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
		return board_unit_registry.is_occupied(cell)


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
		board_unit_registry.swap_units(start, end)
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

#region Signal Handlers
#region GUI
func _on_gui_move_selected() -> void:
	player_action_controller.on_gui_move_selected()

func _on_gui_attack_selected() -> void:
	player_action_controller.on_gui_attack_selected()

func _on_gui_skill_selected(skill) -> void:
	player_action_controller.on_gui_skill_selected(skill)

func _on_gui_wait_selected() -> void:
	player_action_controller.on_gui_wait_selected()

func _on_gui_item_selected(unit) -> void:
	player_action_controller.on_gui_item_selected(unit)

func _on_gui_trade_selected(unit) -> void:
	player_action_controller.on_gui_trade_selected(unit)

func _on_gui_ofuda_selected(unit, ofuda) -> void:
	# Legacy path for now; this should later become item-use intent handled from GameBoard.
	if unit and ofuda and unit.has_method("use_item"):
		unit.use_item(ofuda)

func _on_gui_door_selected() -> void:
	player_action_controller.on_gui_door_selected()

func _on_gui_seize_selected(cell) -> void:
	player_action_controller.on_gui_seize_selected(cell)

func _on_gui_suspend_requested() -> void:
	# Leave suspend behavior unchanged for now
	pass


#endregion
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

#region newlyadded
func _set_active_action(uses_weapon: bool, skill = null, item = null) -> void:
	active_action = {
		"Weapon": uses_weapon,
		"Skill": skill,
		"Item": item
	}
	action_context.Action = active_action.duplicate()


func _resolve_item_action(actor: Unit, target: Unit, item: Consumable) -> CombatResults:
	if actor == null or target == null or item == null:
		return null
	_set_active_action(false, null, item)
	var results: CombatResults = combatManager.start_the_justice(actor, target, active_action)
	_set_action_results(results)
	return results
#endregion
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
		#TURN_STEPS.ITEM_QUEUED: _play_item_results()
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
#endregion


#region combat functions
func _on_inventory_weapon_changed(button) -> void:
	var i = button.get_meta("Item")
	if button.disabled:
		return
	activeUnit.set_equipped(i) #See if it can find it's own index based on ID?
	_set_action_forecast(combatManager.get_forecast(activeUnit, targetUnit, active_action))
	SignalTower.forecast_predicted.emit({
  "results": get_last_forecast(),
  "attacker_unit": activeUnit,   # Unit reference OK for UI
  "defender_unit": targetUnit
})


func _on_action_weapon_selected(button = false):
	var target: Unit = focusUnit
	turn_step = TURN_STEPS.COMBAT_DISPLAY

	if state == STATES.ENEMY_PHASE or state == STATES.NPC_PHASE:
		target = ai_target

	sequencing_units[activeUnit] = true
	sequencing_units[target] = true

	if active_action.Weapon and button:
		var weapon = button.get_meta("Item")
		activeUnit.set_equipped(weapon)

	var combatResults: CombatResults = combatManager.start_the_justice(activeUnit, target, active_action)
	_set_action_results(combatResults)
	combat_sequence(combatResults)
#endregion


#region animation handling
func _on_animation_handler_sequence_complete():
	var hasPostEvents = _check_effect_queue()
	GameState.change_state(self, GameState.gState.GB_DEFAULT)
	_wipe_region()
	current_map.pathAttack.clear()
	if activeUnit:
		cursor.cell = activeUnit.cell
	
	if hasPostEvents: turn_step = TURN_STEPS.EFFECT_QUEUE
	else: _update_unit_bars()
	


func _update_unit_bars():
	turn_step = TURN_STEPS.BAR_ANIM
	bar_queue.append(activeUnit)
	bar_queue.append(targetUnit)
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
			PlayerData.move_committed = false
			board_unit_registry.clear_cell(activeUnit.cell)
			var new_cell = activeUnit.return_original()
			board_unit_registry.set_unit(new_cell, activeUnit)
			_restore_active_unit_equipment()
		else:
			var new_cell = activeUnit.cell
			activeUnit.originCell = activeUnit.cell
			board_unit_registry.set_unit(new_cell, activeUnit)
			#boardState.add_acted(activeUnit)
			activeUnit.set_acted(true)
			selection_equipment_snapshot.clear()
		_snap_cursor(activeUnit.cell)
		activeUnit.isSelected = false
		
	_clear_active_unit()
	current_map.pathAttack.clear()
	unit_path.stop()
	unit_path.clear_path()


func _clear_active_unit() -> void:
	# Clears the reference to the activeUnit and the corresponding walkable cells
	activeUnit = null
	_reset_action_context()
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
	player_action_controller.on_gui_action_menu_canceled()
	


func _player_phase_menu_canceled():
	player_action_controller.player_phase_menu_canceled()
#endregion
