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
signal player_flow_changed(flow_keys:Array,flow)
signal aimove_finished
signal gameboard_targeting_canceled
signal map_freed


enum STATES {IDLE,LOADING,FORMATION,ROUND_END,NEW_TURN,PLAYER_PHASE,NPC_PHASE,ENEMY_PHASE,END_MAP,GAME_OVER,VICTORY}
var state:STATES = STATES.IDLE:
	set(value):
		state = value
		state_changed.emit(STATES.keys(),value)
		_sync_player_flow_from_turn_step()
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


func is_targeting_step(step: TURN_STEPS = turn_step) -> bool:
	match step:
		TURN_STEPS.ATTACK_TARGET, TURN_STEPS.SKILL_TARGET, TURN_STEPS.ITEM_TARGET, TURN_STEPS.WARP_TARGET, TURN_STEPS.DOOR_TARGET, TURN_STEPS.TRADE_TARGET:
			return true
		_:
			return false


func is_move_preview_step(step: TURN_STEPS = turn_step) -> bool:
	match step:
		TURN_STEPS.MOVE_SEEK, TURN_STEPS.UNIT_MOVING:
			return true
		_:
			return false


func is_post_move_step(step: TURN_STEPS = turn_step) -> bool:
	return step == TURN_STEPS.ACTIONS and PlayerData.move_committed


func is_segmented_move_preview() -> bool:
	return turn_step == TURN_STEPS.MOVE_SEEK and !unit_path.path_array.is_empty()


func is_cursor_free_step(step: TURN_STEPS = turn_step) -> bool:
	match step:
		TURN_STEPS.START, TURN_STEPS.MOVE_SEEK:
			return true
		_:
			return is_targeting_step(step)


func is_options_menu_active() -> bool:
	return turn_step == TURN_STEPS.OPTIONS


func is_post_move_menu_active() -> bool:
	return PlayerData.move_committed or is_post_move_step()


func get_action_menu_moved_state() -> bool:
	return is_post_move_menu_active()


func restore_post_target_turn_step() -> void:
	turn_step = _get_post_target_menu_step()


func get_targeting_game_state() -> GameState.gState:
	match turn_step:
		TURN_STEPS.ATTACK_TARGET:
			return GameState.gState.GB_ATTACK_TARGETING
		TURN_STEPS.SKILL_TARGET:
			return GameState.gState.GB_SKILL_TARGETING
		TURN_STEPS.ITEM_TARGET:
			return GameState.gState.GB_ITEM_TARGETING
		TURN_STEPS.WARP_TARGET:
			return GameState.gState.GB_WARP
		TURN_STEPS.TRADE_TARGET:
			return GameState.gState.GB_TRADE_TARGETING
		TURN_STEPS.DOOR_TARGET:
			return GameState.gState.GB_OBJECT_TARGETING
		_:
			return GameState.gState.GB_DEFAULT


func apply_default_control_state() -> void:
	if GameState:
		GameState.change_state(self, GameState.gState.GB_DEFAULT)


func apply_action_menu_control_state() -> void:
	if GameState:
		GameState.change_state(self, GameState.gState.GB_ACTION_MENU)


func apply_targeting_control_state() -> void:
	if GameState:
		GameState.change_state(self, get_targeting_game_state())


func apply_forecast_control_state() -> void:
	if GameState:
		GameState.change_state(self, GameState.gState.GB_COMBAT_FORECAST)


func apply_scene_control_state() -> void:
	if GameState:
		GameState.change_state(self, GameState.gState.SCENE_ACTIVE)


func apply_formation_control_state() -> void:
	if GameState:
		GameState.change_state(self, GameState.gState.GB_FORMATION)


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


func block_targeting_confirm_for_frame() -> void:
	targeting_input_blocked = true
	call_deferred("_clear_targeting_input_block")


func _clear_targeting_input_block() -> void:
	targeting_input_blocked = false


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
var targeting_input_blocked := false
var selection_equipment_snapshot: Array[Dictionary] = []
var focusUnit:Unit:
	set(value):
		focusUnit = value
		Global.focusUnit = focusUnit
var active_action:Dictionary = {"Weapon":false,"Skill":null,"Item":null}
var pending_warp_target: Unit = null
var pending_warp_item: Consumable = null
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
enum TURN_STEPS {STAND_BY,PROCESSING,START,END_PHASE,END,OPTIONS,ACTIONS,MOVE_SEEK,UNIT_MOVING,AI_ACT,ITEM_QUEUED,ITEM_ANIMATION,ITEM_TARGET,ATTACK_TARGET,DOOR_TARGET,TRADE_TARGET,SKILL_TARGET,FORECAST_ATTACK,COMBAT_DISPLAY,EFFECT_QUEUE,BAR_ANIM,EVENT_QUEUE,EXP_GRANT,CANTO,WARP_TARGET}
enum PLAYER_FLOW {IDLE,UNIT_SELECTED,MOVE_PREVIEW,POST_MOVE_MENU,TARGETING,FORECAST,RESOLVING}
enum AI_STEPS {STAND_BY,PROCESSING,START,EVALUATE,PROCESS_TURN,SELECT_UNIT,MOVE_UNIT}
enum ROUND_STEPS {CHECK,DANMAKU,SCENE,REINFORCE,END,}
var last_step:TURN_STEPS
var turn_step:TURN_STEPS = TURN_STEPS.STAND_BY:
	set(value):
		last_step = turn_step
		turn_step = value
		step_changed.emit(TURN_STEPS.keys(),value)
		_sync_player_flow_from_turn_step()
var player_flow:PLAYER_FLOW = PLAYER_FLOW.IDLE:
	set(value):
		player_flow = value
		player_flow_changed.emit(PLAYER_FLOW.keys(), value)
var ai_step:AI_STEPS = AI_STEPS.STAND_BY
var round_step:ROUND_STEPS = ROUND_STEPS.CHECK:
	set(value):
		round_step = value
		step_changed.emit(ROUND_STEPS.keys(),value)
var pending_item_action:Dictionary={"Item":false,"Results":false,}
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
var pending_ai_action: Action
#deployment
var stored_unit : Unit
var stored_cell : Vector2i = Vector2i(-1,-1)
#Queued events
var exp_events:Array[Dictionary] = []
var active_died:bool = false
var hp_bar_visibility_before_event_zoom := true
var hp_bar_visibility_captured := false
var door_zoom_complete_callable: Callable
var door_conclude_callable: Callable
var ai_return_cursor_cell : Vector2i = Vector2i(-1, -1)
const AI_PRESENTATION_PAN_SPEED := 0.35
const AI_PRESENTATION_PREVIEW_DELAY := 0.22
const AI_PRESENTATION_PRE_ACTION_DELAY := 0.18
const AI_PRESENTATION_POST_ACTION_DELAY := 0.2

#GUI
var guiManager:GUIManager:
	set(value):
		guiManager = value
		if is_inside_tree():
			_connect_gui_signals()
var player_action_controller: PlayerActionController
var board_targeting: BoardTargeting
var board_unit_registry: BoardUnitRegistry
var board_turn_flow: BoardTurnFlow
var board_event_resolver: BoardEventResolver


func get_player_flow() -> PLAYER_FLOW:
	return player_flow


func _set_player_flow(value: PLAYER_FLOW) -> void:
	player_flow = value


func _sync_player_flow_from_turn_step() -> void:
	if state != STATES.PLAYER_PHASE:
		_set_player_flow(PLAYER_FLOW.IDLE)
		return

	if turn_step == TURN_STEPS.OPTIONS:
		_set_player_flow(PLAYER_FLOW.UNIT_SELECTED)
	elif turn_step == TURN_STEPS.ACTIONS:
		if is_post_move_step():
			_set_player_flow(PLAYER_FLOW.POST_MOVE_MENU)
		else:
			_set_player_flow(PLAYER_FLOW.UNIT_SELECTED)
	elif is_move_preview_step():
		_set_player_flow(PLAYER_FLOW.MOVE_PREVIEW)
	elif is_targeting_step():
		_set_player_flow(PLAYER_FLOW.TARGETING)
	elif turn_step == TURN_STEPS.FORECAST_ATTACK:
		_set_player_flow(PLAYER_FLOW.FORECAST)
	elif turn_step in [TURN_STEPS.PROCESSING, TURN_STEPS.ITEM_QUEUED, TURN_STEPS.ITEM_ANIMATION, TURN_STEPS.COMBAT_DISPLAY, TURN_STEPS.EFFECT_QUEUE, TURN_STEPS.BAR_ANIM]:
		_set_player_flow(PLAYER_FLOW.RESOLVING)
	else:
		_set_player_flow(PLAYER_FLOW.IDLE)

#region init/ready/process
func _ready():
	if !cam_con: cam_con = CameraController.new(get_viewport())
	player_action_controller = PlayerActionController.new(self)
	board_targeting = BoardTargeting.new(self)
	board_unit_registry = BoardUnitRegistry.new(self)
	board_turn_flow = BoardTurnFlow.new(self)
	board_event_resolver = BoardEventResolver.new(self)
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


#region signal connection
func _connect_signals():
	_connect_general_signals()
	_connect_gui_signals()

func _connect_general_signals():
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


func free_map(emit_freed := true)->void:
	reset_flags()
	PlayerData.purge_npc_data()
	if unit_loader:
		unit_loader.queue_free()
		unit_loader = null
	if current_map:
		current_map.queue_free()
		await current_map.tree_exited
	current_map = null
	SignalTower.time_reset.emit()
	if emit_freed:
		map_freed.emit()


func _on_map_loaded():
	map_loader.queue_free()
	_load_units()


func _load_units():
	if !unit_loader:
		unit_loader = UnitLoader.new(self,save_enum,current_map)
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


func _update_unit_terrain(unit:Unit):
	unit.update_terrain_data()


func _move_active_unit(new_cell: Vector2i, set_path:Array[Vector2i]= []) -> void: #pathing related
	# Updates the units dictionary with the target position for the unit and asks the activeUnit to walk to it.
	var path = null
	var is_ai_turn := state != STATES.PLAYER_PHASE
	turn_step = TURN_STEPS.UNIT_MOVING
	if !new_cell == activeUnit.cell and !is_ai_turn:
		if is_occupied(new_cell) or not new_cell in walkable_cells: return
	current_map.pathAttack.clear()
	if !new_cell == activeUnit.cell:
		board_unit_registry.relocate_unit(activeUnit.cell, new_cell, activeUnit)
		if !is_ai_turn:
			path = unit_path.current_path
		else:
			path = PackedVector2Array(set_path)
		activeUnit.walk_along(path,true)


func _on_unit_walk_finished():
	_unit_at_destination()


func _unit_at_destination():
	unit_path.clear_path()
	if (state == STATES.ENEMY_PHASE or state == STATES.NPC_PHASE) and pending_ai_action != null:
		_continue_ai_action_after_move()
		return
	if PlayerData.canto_triggered:
		_wipe_region()
		PlayerData.canto_triggered = false
		PlayerData.move_committed = true
		turn_step = TURN_STEPS.END_PHASE
	else:
		PlayerData.move_committed = true
		turn_step = TURN_STEPS.ACTIONS
		unit_move_ended.emit(activeUnit)


func _start_canto():
	if activeUnit == null or activeUnit.remaining_move <= 0:
		PlayerData.canto_triggered = false
		turn_step = TURN_STEPS.END
		return
	turn_step = TURN_STEPS.MOVE_SEEK
	unit_path.clear_path()
	_update_walkable_range(activeUnit.remaining_move)
#endregion


#region AI functions
func _get_current_ai_faction() -> Enums.FACTION_ID:
	match state:
		STATES.ENEMY_PHASE:
			return Enums.FACTION_ID.ENEMY
		STATES.NPC_PHASE:
			return Enums.FACTION_ID.NPC
		_:
			return Enums.FACTION_ID.NONE


func begin_ai_phase_action() -> void:
	if turn_step != TURN_STEPS.START:
		return
	turn_step = TURN_STEPS.PROCESSING
	if ai == null:
		print("[AI] No AI manager present on map.")
		turn_step = TURN_STEPS.END
		return

	var faction := _get_current_ai_faction()
	if faction == Enums.FACTION_ID.NONE:
		print("[AI] No active AI faction for state: ", STATES.keys()[state])
		turn_step = TURN_STEPS.END
		return

	print("[AI] Begin phase action for faction: ", Enums.FACTION_ID.keys()[faction])
	var choice := ai.get_best_executable_action(faction)
	if choice.is_empty():
		print("[AI] No executable action chosen. Ending AI phase step.")
		turn_step = TURN_STEPS.END
		return

	var action: Action = choice.get("action", null)
	var unit_id := String(choice.get("unit_id", ""))
	var actor :Unit= unit_refs.get(unit_id, null)
	if actor == null:
		print("[AI] Chosen actor missing from unit_refs: ", unit_id)
		turn_step = TURN_STEPS.END
		return
	if actor.check_status("Acted"):
		print("[AI] Chosen actor already acted: ", unit_id)
		turn_step = TURN_STEPS.END
		return

	activeUnit = actor
	_set_action_actor(actor)
	_snapshot_active_unit_equipment()
	pending_ai_action = action
	activeUnit.isSelected = true
	print("[AI] Selected unit ", actor.unit_id, " at ", actor.cell, " | action=", Action.ACTION_TYPE.keys()[int(action.type)], " | from=", action.from_cell, " | target_cell=", action.target_cell, " | target_unit=", action.target_unit_id)

	var launch_cell := actor.cell
	if action != null:
		match action.type:
			Action.ACTION_TYPE.MOVE, Action.ACTION_TYPE.CANTO:
				launch_cell = action.target_cell
			_:
				launch_cell = action.from_cell
	await _present_ai_action(actor, action, launch_cell)
	if action != null and launch_cell != Vector2i.ZERO and launch_cell != actor.cell:
		print("[AI] Moving to launch cell: ", launch_cell)
		var move_path :Array[Vector2i]= get_path_to_cell(actor.cell, launch_cell, actor)
		_move_active_unit(launch_cell, move_path)
	else:
		_continue_ai_action_after_move()


func _continue_ai_action_after_move() -> void:
	if pending_ai_action == null or activeUnit == null:
		print("[AI] Missing pending action or active unit after move.")
		turn_step = TURN_STEPS.END
		return

	var action := pending_ai_action
	await get_tree().create_timer(AI_PRESENTATION_PRE_ACTION_DELAY).timeout
	print("[AI] Executing action: ", Action.ACTION_TYPE.keys()[int(action.type)], " for ", activeUnit.unit_id)
	match action.type:
		Action.ACTION_TYPE.MOVE, Action.ACTION_TYPE.WAIT:
			unit_wait()
		Action.ACTION_TYPE.ATTACK:
			var target: Unit = unit_refs.get(String(action.target_unit_id), null)
			if target == null:
				print("[AI] Attack target missing for action.")
				turn_step = TURN_STEPS.END
				return
			_set_active_action(true, null, null)
			_begin_ai_forecast_sequence(target)
		Action.ACTION_TYPE.SKILL_HOSTILE:
			var skill_target := _resolve_ai_action_target(action)
			if skill_target == null:
				print("[AI] Skill target missing for action.")
				turn_step = TURN_STEPS.END
				return
			var live_skill := _resolve_live_skill_for_action(action.skill, activeUnit)
			if live_skill == null:
				print("[AI] Skill payload could not be resolved for hostile skill action.")
				turn_step = TURN_STEPS.END
				return
			_set_active_action(live_skill.augment, live_skill, null)
			_begin_ai_forecast_sequence(skill_target)
		Action.ACTION_TYPE.SKILL_FRIENDLY:
			var support_target := _resolve_ai_action_target(action)
			if support_target == null:
				print("[AI] Friendly skill target missing for action.")
				turn_step = TURN_STEPS.END
				return
			var live_support_skill := _resolve_live_skill_for_action(action.skill, activeUnit)
			if live_support_skill == null:
				print("[AI] Skill payload could not be resolved for friendly skill action.")
				turn_step = TURN_STEPS.END
				return
			_set_active_action(live_support_skill.augment, live_support_skill, null)
			_begin_ai_forecast_sequence(support_target)
		Action.ACTION_TYPE.USE_ITEM:
			var item_target := _resolve_ai_action_target(action)
			if item_target == null:
				print("[AI] Item target missing for action.")
				turn_step = TURN_STEPS.END
				return
			var live_item := _resolve_live_item_for_action(action.item, activeUnit)
			if live_item == null:
				print("[AI] Item payload could not be resolved for action.")
				turn_step = TURN_STEPS.END
				return
			_set_active_action(false, null, live_item)
			_begin_ai_forecast_sequence(item_target)
		Action.ACTION_TYPE.DOOR:
			if current_map != null and current_map.doors.has(action.target_cell):
				turn_step = TURN_STEPS.PROCESSING
				ai_target = null
				activeUnit.pick_door(current_map.doors[action.target_cell])
			else:
				turn_step = TURN_STEPS.END
		_:
			print("[AI] Unsupported action reached live executor: ", Action.ACTION_TYPE.keys()[int(action.type)])
			turn_step = TURN_STEPS.END


func finalize_ai_phase_action() -> void:
	if activeUnit != null:
		print("[AI] Finalizing action for ", activeUnit.unit_id, " at ", activeUnit.cell)
		activeUnit.originCell = activeUnit.cell
		activeUnit.isSelected = false
		activeUnit.set_acted(true)
	selection_equipment_snapshot.clear()
	pending_ai_action = null
	ai_target = null
	_clear_active_unit()
	_wipe_region()
	current_map.pathAttack.clear()
	await get_tree().create_timer(AI_PRESENTATION_POST_ACTION_DELAY).timeout


func _resolve_ai_action_target(action: Action) -> Unit:
	if action == null or activeUnit == null:
		return null
	var target_id := String(action.target_unit_id)
	if target_id == "":
		if action.target_cell == activeUnit.cell or action.target_cell == Vector2i.ZERO:
			return activeUnit
		return units.get(action.target_cell, null)
	var target: Unit = unit_refs.get(target_id, null)
	if target != null:
		return target
	if target_id == String(activeUnit.unit_id):
		return activeUnit
	return null


func _begin_ai_forecast_sequence(target: Unit) -> void:
	if activeUnit == null or target == null:
		turn_step = TURN_STEPS.END
		return

	_set_action_target(target)
	ai_target = target
	var forecast: CombatResults = combatManager.get_forecast(activeUnit, target, active_action)
	_set_action_forecast(forecast)
	SignalTower.forecast_predicted.emit({
		"results": get_last_forecast(),
		"attacker_unit": activeUnit,
		"defender_unit": target
	})
	target_focused.emit(2, [-1, -1])


func _resolve_live_skill_for_action(skill_data, actor: Unit) -> Skill:
	if actor == null or skill_data == null:
		return null
	if skill_data is Skill:
		return skill_data
	var desired_id := ""
	var desired_path := ""
	if typeof(skill_data) == TYPE_DICTIONARY:
		desired_id = String(skill_data.get("id", ""))
		desired_path = String(skill_data.get("path", skill_data.get("Properties", "")))
	for skill in actor.skills:
		if skill == null:
			continue
		if desired_id != "" and String(skill.id) == desired_id:
			return skill
		if desired_path != "" and String(skill.resource_path) == desired_path:
			return skill
	if desired_path != "" and ResourceLoader.exists(desired_path):
		return load(desired_path) as Skill
	return null


func _resolve_live_item_for_action(item_data, actor: Unit) -> Consumable:
	if actor == null or item_data == null:
		return null
	if item_data is Consumable:
		return item_data
	var desired_id := ""
	var desired_path := ""
	if typeof(item_data) == TYPE_DICTIONARY:
		desired_id = String(item_data.get("id", ""))
		desired_path = String(item_data.get("path", item_data.get("Properties", "")))
	for item in actor.inventory:
		if item == null or not (item is Consumable):
			continue
		if desired_id != "" and String(item.id) == desired_id:
			return item as Consumable
		if desired_path != "" and String(item.resource_path) == desired_path:
			return item as Consumable
	return null


func _remember_player_cursor_view() -> void:
	if cursor == null:
		return
	ai_return_cursor_cell = cursor.cell


func _restore_player_cursor_view() -> void:
	if cursor == null:
		return
	if ai_return_cursor_cell.x < 0 or ai_return_cursor_cell.y < 0:
		_snap_cursor()
		return
	cursor.cell = ai_return_cursor_cell
	await _pan_camera_to_cell(ai_return_cursor_cell, 0.45)
	_warp_mouse_to_cursor()


func _warp_mouse_to_cursor() -> void:
	if cursor == null:
		return
	var mouse_warp := cursor.get_global_transform_with_canvas()
	get_viewport().warp_mouse(mouse_warp.origin)


func _pan_camera_to_cell(cell: Vector2i, speed: float = 0.35) -> void:
	if cell.x < 0 or cell.y < 0:
		return
	if !cam_con:
		cam_con = CameraController.new(get_viewport())
	cam_con.move_camera_map(cell, speed, cam_con.camera.get_zoom(), Tween.TransitionType.TRANS_SINE, Tween.EaseType.EASE_IN_OUT)
	await cam_con.camera_control_complete


func _present_ai_action(actor: Unit, action: Action, launch_cell: Vector2i) -> void:
	if actor == null or action == null:
		return
	await _pan_camera_to_cell(actor.cell, AI_PRESENTATION_PAN_SPEED)

	var should_preview_move := launch_cell != Vector2i.ZERO and launch_cell != actor.cell
	if not should_preview_move:
		await get_tree().create_timer(AI_PRESENTATION_PREVIEW_DELAY).timeout
		return

	walkable_cells = get_walkable_cells(actor)
	current_map.draw(walkable_cells)
	await get_tree().create_timer(AI_PRESENTATION_PREVIEW_DELAY).timeout

	var move_path :Array[Vector2i]= get_path_to_cell(actor.cell, launch_cell, actor)
	if !move_path.is_empty():
		unit_path.draw(move_path)

	await _pan_camera_to_cell(launch_cell, AI_PRESENTATION_PAN_SPEED)
	await get_tree().create_timer(AI_PRESENTATION_PRE_ACTION_DELAY).timeout
	_wipe_region()
	unit_path.clear_path()


#endregion

#region events
func _process_event_queue()->void:
	board_event_resolver.process_event_queue()


func _handle_active_unit_death():
	board_event_resolver.handle_active_unit_death()


func _process_exp_events():
	await board_event_resolver.process_exp_events()
#endregion


#region movement of unit objects
func on_unit_relocated(oldCell, newCell, unit): #updates unit locations with it's new location
	board_unit_registry.relocate_unit(oldCell, newCell, unit)
#endregion


#region removal, death and bar updates of units
func on_death_done(unit: Unit):
	var killer:= unit.killer
	if killer == null and action_context.Actor is Unit:
		killer = action_context.Actor
	if killer == null and activeUnit is Unit:
		killer = activeUnit
	if !killer: 
		push_warning("[Unit]on_death_done: invalid or null killer")
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


func _remove_from_grid(unit: Unit):
	board_unit_registry.remove_from_grid(unit)



#endregion


#region unit EXP handling

	#emit_signal("exp_display", oldExp, expSteps, results, portrait, unitName)
#endregion

#region unit turn and action handling
func on_turn_complete(unit):
	pass


func _on_item_used(item:Item):
	PlayerData.item_used = true
	var targeting:Enums.SKILL_TARGET = item.target
	#{NONE, SELF, ALLY, ENEMY, MAP, SELF_ALLY}
	match targeting:
		Enums.SKILL_TARGET.NONE: _advance_to_end_phase()
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
	pending_item_action["Item"] = item
	pending_item_action["Results"] = results


func _on_unit_animation_complete(_unit:Unit):
	if turn_step == TURN_STEPS.ITEM_QUEUED and (_unit == activeUnit or _unit == targetUnit):
		apply_default_control_state()
		turn_step = TURN_STEPS.END_PHASE
		return
	match last_step:
		TURN_STEPS.DOOR_TARGET: 
			door_conclude_callable = Callable(self, "_door_conclude")
			if cam_con.camera_control_complete.is_connected(door_conclude_callable):
				cam_con.camera_control_complete.disconnect(door_conclude_callable)
			cam_con.camera_control_complete.connect(door_conclude_callable)
			reset_event_zoom()
			
func _door_conclude():
	if door_conclude_callable.is_valid() and cam_con.camera_control_complete.is_connected(door_conclude_callable):
		cam_con.camera_control_complete.disconnect(door_conclude_callable)
	door_conclude_callable = Callable()
	if hp_bar_visibility_captured:
		get_tree().set_group("HPBar", "visible", hp_bar_visibility_before_event_zoom)
		hp_bar_visibility_captured = false
	if guiManager != null:
		guiManager._show_hud()
		await get_tree().create_timer(1.0).timeout
	turn_step = TURN_STEPS.END_PHASE


func _map_use_item(_item:Item):
	pass


func _target_use_item(_item:Item):
	pass


func _apply_item(item:Consumable, unit:Unit, _target:Unit):
	var target := _target if _target != null else unit
	if unit == null or target == null:
		return
	var results: CombatResults = _resolve_item_action(unit, target, item)
	pending_item_action["Item"] = item
	pending_item_action["Results"] = results
#endregion

#region targeting code
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
	if activeUnit and skill and not activeUnit.has_enough_comp(int(skill.cost)):
		return
	board_targeting.start_skill_targeting(skill)


func start_item_targeting(item: Consumable):
	if activeUnit and item and not activeUnit.has_enough_comp(int(item.cost)):
		return
	board_targeting.start_item_targeting(item)

func door_targeting():
	board_targeting.door_targeting()


func seek_trade(unit: Unit = activeUnit) -> void:
	board_targeting.seek_trade(unit)


func _end_targeting(emit_cancel := true):
	board_targeting.end_targeting(emit_cancel)


func end_targeting() -> void:
	_end_targeting()


func trade_target_selected() -> void:
	board_targeting.trade_target_selected()
#endregion

#region action code
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
	if is_cursor_free_step():
		cursor.cell = position
		


#not vetted
func _cursor_toggle(enable, snapLeader = true):
	if enable:
		cursor.visible = true
	else:
		cursor.visible = false
	if snapLeader:
		_snap_cursor()


func _snap_cursor(cell: Vector2i = _get_lady_cell()):
	cursor.cell = cell
	var mouseWarp = cursor.get_global_transform_with_canvas()
	get_viewport().warp_mouse(mouseWarp.origin)
	cursor.align_camera()


func _on_cursor_moved(new_cell: Vector2i) -> void: #Pathing
	var path := []
	#safety measure, catches any uncleared cell storage that slips through the cracks
	if units.has(new_cell) and units[new_cell] == null: units.erase(new_cell)
	
	if state != STATES.PLAYER_PHASE or !activeUnit or !activeUnit.isSelected: return
	if turn_step != TURN_STEPS.MOVE_SEEK:
		unit_path.clear()
		return
	if is_segmented_move_preview():
		path = _draw_segmented_path(new_cell)
	else:
		path = _draw_initial_path(new_cell)
	if path: unit_path.draw(path)



func _on_area_2d_area_entered(area):
	#print("Entered: ", area.collision_layer)
	match area.collision_layer:
		2:
			var unit: Unit = area.get_master()
			if unit != null and unit.is_active and unit.deployment != Enums.DEPLOYMENT.UNDEPLOYED:
				focusUnit = unit
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


func regress_act_menu() -> void:
	if guiManager != null:
		guiManager.regress_act_menu()
	else:
		ui_return()


func _get_post_target_menu_step() -> TURN_STEPS:
	return TURN_STEPS.ACTIONS


func _cancel_targeting_step() -> void:
	turn_step = _get_post_target_menu_step()
	_end_targeting()


func _ui_return_player_phase(): 
	match turn_step:
		TURN_STEPS.OPTIONS:
			turn_step = TURN_STEPS.START
		TURN_STEPS.ACTIONS:
			ui_returned.emit(turn_step)
		TURN_STEPS.MOVE_SEEK:
			if is_segmented_move_preview():
				_undo_segment()
			else:
				if PlayerData.canto_triggered:
					PlayerData.canto_triggered = false
					_wipe_region()
					turn_step = TURN_STEPS.END_PHASE
				else:
					turn_step = TURN_STEPS.ACTIONS
					_wipe_region()
					unit_selected.emit(activeUnit)
		TURN_STEPS.ATTACK_TARGET:
			_cancel_targeting_step()
		TURN_STEPS.WARP_TARGET:
			pending_warp_target = null
			pending_warp_item = null
			_cancel_targeting_step()
		TURN_STEPS.FORECAST_ATTACK:
			turn_step = TURN_STEPS.ATTACK_TARGET
			ui_returned.emit(TURN_STEPS.FORECAST_ATTACK)
		_ when is_targeting_step():
			_cancel_targeting_step()


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
	var hp_bars = get_tree().get_nodes_in_group("HPBar")
	hp_bar_visibility_before_event_zoom = hp_bar_vis
	if hp_bars.size() > 0:
		hp_bar_visibility_before_event_zoom = hp_bars[0].visible
	hp_bar_visibility_captured = true
	if hp_bar_visibility_before_event_zoom:
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
		TURN_STEPS.MOVE_SEEK: select_destination()
		TURN_STEPS.ATTACK_TARGET: attack_target_selected()
		TURN_STEPS.DOOR_TARGET: door_target_selected()
		TURN_STEPS.TRADE_TARGET: trade_target_selected()
		TURN_STEPS.SKILL_TARGET: _feature_target_selected(active_action.Skill)
		TURN_STEPS.ITEM_TARGET: _feature_target_selected(active_action.Item)
		TURN_STEPS.WARP_TARGET: warp_destination_selected()


func door_target_selected():
	if current_map.doors.has(cursor.cell):
		turn_step = TURN_STEPS.PROCESSING
		var dCell :Vector2i = cursor.cell
		_end_targeting(false)
		if guiManager != null:
			guiManager._hide_hud()
		action_confirmed.emit()
		if !cam_con: cam_con = CameraController.new(get_viewport())
		door_zoom_complete_callable = Callable(self, "_door_zoom_complete").bind(dCell)
		if cam_con.camera_control_complete.is_connected(door_zoom_complete_callable):
			cam_con.camera_control_complete.disconnect(door_zoom_complete_callable)
		cam_con.camera_control_complete.connect(door_zoom_complete_callable)
		event_zoom()
		


func _door_zoom_complete(cell:Vector2i):
	if door_zoom_complete_callable.is_valid() and cam_con.camera_control_complete.is_connected(door_zoom_complete_callable):
		cam_con.camera_control_complete.disconnect(door_zoom_complete_callable)
	door_zoom_complete_callable = Callable()
	PlayerData.canto_triggered = true
	activeUnit.pick_door(current_map.doors[cell])


func _select_unit(cell: Vector2i) -> void:
	var occupied :bool= is_occupied(cell)
	if !occupied:
		turn_step = TURN_STEPS.OPTIONS
		cell_selected.emit(cell)
	elif units[cell].FACTION_ID == Enums.FACTION_ID.ENEMY: return
	elif !units.has(cell) or units[cell].status.Acted: return
	elif _is_dazed_deferred(units[cell]): return
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


func item_target_selected() -> void:
	_feature_target_selected(active_action.Item)


func warp_destination_selected() -> void:
	board_targeting.warp_destination_selected()


func attack_target_selected():
	board_targeting.attack_target_selected()


func grab_target(cell):
	board_targeting.grab_target(cell)


func move_selection(isAi := false):
	turn_step = TURN_STEPS.MOVE_SEEK
	unit_path.clear_path()
	#_snap_cursor(activeUnit.cell)
	if PlayerData.canto_triggered and activeUnit != null and activeUnit.remaining_move > 0:
		_update_walkable_range(activeUnit.remaining_move)
	else:
		walkable_cells = get_walkable_cells(activeUnit)
		current_map.draw(walkable_cells)
	#if !isAi: GameState.change_state(self, GameState.gState.GB_SELECTED)


func select_destination() -> void: #SELECTED STATE Pathing Related
	var cell:Vector2i = cursor.cell
	var isOccupied = is_occupied(cell)
	var isWalkable = walkable_cells.has(cell)
	var available_move :int = activeUnit.remaining_move if PlayerData.canto_triggered else activeUnit.active_stats.Move
	var moveRemain :int = available_move - unit_path.path_array.size()
	if !isOccupied and isWalkable and moveRemain > 0 and !unit_path.path_array.has(cell):
		unit_path.update_pathing_array(activeUnit,cell,current_map)
		moveRemain = available_move - unit_path.path_array.size()
		_update_walkable_range(moveRemain)
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
	if unit == null or ofuda == null:
		return
	activeUnit = unit
	_set_action_actor(unit)
	start_item_targeting(ofuda)

func _on_gui_door_selected() -> void:
	player_action_controller.on_gui_door_selected()

func _on_gui_seize_selected(cell) -> void:
	player_action_controller.on_gui_seize_selected(cell)

func _on_gui_suspend_requested() -> void:
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
	apply_default_control_state()
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
	unit_refs.clear()
	activeUnit = null
	targetUnit = null
	focusUnit = null
	Global.activeUnit = null
	chapter_started = false
	turn_order.clear()
	turn_counter = 0
	selection_equipment_snapshot.clear()
	walkable_cells.clear()
	snap_path.clear()
	action_context = {
		"Actor": null,
		"Target": null,
		"Action": {"Weapon": false, "Skill": null, "Item": null},
		"Forecast": null,
		"Results": null,
	}
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
	active_died = false


func _advance_to_end_phase():
	turn_step = TURN_STEPS.END_PHASE


func _actor_took_damage_in_last_results() -> bool:
	var results: CombatResults = get_last_combat_results()
	if results == null:
		return false
	var actor :Unit= action_context.get("Actor", null)
	if actor == null:
		return false
	var actor_id := String(actor.unit_id)
	for round in results.rounds:
		for action in round.get("actions", []):
			if String(action.get("target_id", "")) != actor_id:
				continue
			for swing in action.get("swings", []):
				if not bool(swing.get("hit", false)):
					continue
				if int(swing.get("dmg", 0)) > 0:
					return true
				for event in swing.get("events_pre", []):
					if String(event.get("type", "")) == "damage" and String(event.get("target_id", "")) == actor_id and int(event.get("amount", 0)) > 0:
						return true
				for event in swing.get("events_post", []):
					if String(event.get("type", "")) == "damage" and String(event.get("target_id", "")) == actor_id and int(event.get("amount", 0)) > 0:
						return true
				for event in swing.get("events", []):
					if String(event.get("type", "")) == "damage" and String(event.get("target_id", "")) == actor_id and int(event.get("amount", 0)) > 0:
						return true
	return false


func update_canto_trigger_from_last_results() -> void:
	if PlayerData.canto_triggered:
		return
	if activeUnit == null or not PlayerData.move_committed:
		return
	if not activeUnit.has_passive(Enums.PASSIVE_TYPE.CANTO):
		return
	if activeUnit.remaining_move <= 0:
		return
	PlayerData.canto_triggered = not _actor_took_damage_in_last_results()


func _check_friendly(unit1, unit2, sameOnly:=false) ->bool:
	if unit1.FACTION_ID == unit2.FACTION_ID: return true
	elif !sameOnly and unit1.FACTION_ID != Enums.FACTION_ID.ENEMY and unit2.FACTION_ID != Enums.FACTION_ID.ENEMY: return true
	return false


func _is_dazed_deferred(unit: Unit) -> bool:
	if unit == null or not unit.check_status("Dazed"):
		return false

	for other in units.values():
		if other == null or other == unit:
			continue
		if other.FACTION_ID != unit.FACTION_ID:
			continue
		if other.check_status("Acted") or other.check_status("Dazed"):
			continue
		if not other.can_act():
			continue
		return true

	return false

#region newlyadded
func _set_active_action(uses_weapon: bool, skill = null, item = null) -> void:
	active_action = {
		"Weapon": uses_weapon,
		"Skill": skill,
		"Item": item
	}
	action_context.Action = active_action.duplicate()


func _resolve_item_action(actor: Unit, target: Unit, item: Consumable, warp_destination := Vector2i(-999999, -999999)) -> CombatResults:
	if actor == null or target == null or item == null:
		return null
	_set_active_action(false, null, item)
	if warp_destination != Vector2i(-999999, -999999):
		active_action["WarpDestination"] = warp_destination
		action_context.Action = active_action.duplicate()
	var results: CombatResults = combatManager.start_the_justice(actor, target, active_action)
	turn_step = TURN_STEPS.ITEM_QUEUED
	actor.use_item(item)
	target.receive_item(item)
	_set_action_results(results)
	return results


func should_resolve_item_without_forecast(item: Consumable) -> bool:
	if item == null:
		return false
	for effect: Effect in item.effects:
		if effect == null:
			continue
		if effect.type == Enums.EFFECT_TYPE.RELOC:
			return true
	return false


func is_warp_item(item: Consumable) -> bool:
	if item == null:
		return false
	for effect: Effect in item.effects:
		if effect == null:
			continue
		if effect.type == Enums.EFFECT_TYPE.RELOC and effect.sub_type == Enums.SUB_TYPE.WARP:
			return true
	return false


func resolve_item_without_forecast(item: Consumable) -> void:
	if activeUnit == null or targetUnit == null or item == null:
		return
	var results: CombatResults = _resolve_item_action(activeUnit, targetUnit, item)
	pending_item_action["Item"] = item
	pending_item_action["Results"] = results


func resolve_warp_without_forecast(item: Consumable, target: Unit, destination: Vector2i) -> void:
	if activeUnit == null or target == null or item == null:
		return
	var results: CombatResults = _resolve_item_action(activeUnit, target, item, destination)
	pending_item_action["Item"] = item
	pending_item_action["Results"] = results
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
	if !unit_path.path_array and moveRemain > 0:
		newArea = hexStar.find_remaining_unit_paths(activeUnit, activeUnit.cell, moveRemain)
	elif !unit_path.path_array:
		newArea = get_walkable_cells(activeUnit)
	else: newArea = hexStar.find_remaining_unit_paths(activeUnit, unit_path.path_array[-1], moveRemain)
	walkable_cells = newArea
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
	else:
		unit_path.draw(unit_path.path_array)
#endregion


#region turn tracker
func _initialize_turns(ignoreActed := false):
	board_turn_flow.initialize_turns(ignoreActed)


func turn_change():
	board_turn_flow.turn_change()


func _start_next_turn():
	board_turn_flow.start_next_turn()
		


func _add_turn(faction):
	board_turn_flow.add_turn(faction)


func _remove_turn(teamId):
	board_turn_flow.remove_turn(teamId)


func set_next_acted():
	board_turn_flow.set_next_acted()
#endregion


#region turn steps
func _check_player_turn_step():
	await board_turn_flow.check_player_turn_step()


func _check_enemy_turn_step():
	await board_turn_flow.check_enemy_turn_step()


func _stand_by_step():
	board_turn_flow.stand_by_step()
	

func _check_end_of_turn():
	await board_turn_flow.check_end_of_turn()


func _check_next_state():
	board_turn_flow.check_next_state()
#endregion


#region end of round functions
func round_change():
	board_turn_flow.round_change()


func round_duration_tick():
	board_turn_flow.round_duration_tick()


func _check_eor_events()->void:
	board_turn_flow.check_end_of_round_events()
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

	if active_action.Item:
		var item_results: CombatResults = _resolve_item_action(activeUnit, target, active_action.Item)
		pending_item_action["Item"] = active_action.Item
		pending_item_action["Results"] = item_results
		combat_sequence(item_results)
		return

	var combatResults: CombatResults = combatManager.start_the_justice(activeUnit, target, active_action)
	_set_action_results(combatResults)
	combat_sequence(combatResults)
#endregion


#region animation handling
func _on_animation_handler_sequence_complete():
	board_event_resolver.on_animation_handler_sequence_complete()
	


func _update_unit_bars():
	board_event_resolver.update_unit_bars()


func _on_bars_updated(unit:Unit):
	board_event_resolver.on_bars_updated(unit)


func _check_effect_queue() -> bool:
	return board_event_resolver.check_effect_queue()


func _run_effect_queue():
	await board_event_resolver.run_effect_queue()


func on_effect_complete():
	board_event_resolver.on_effect_complete()


func _sort_effect_queue():
	return board_event_resolver.sort_effect_queue()


func add_effect_queue(new):
	board_event_resolver.add_effect_queue(new)


func _clear_effect_queue():
	board_event_resolver.clear_effect_queue()


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
	if activeUnit != null and units.has(activeUnit.cell):
		if !confirm: 
			PlayerData.move_committed = false
			board_unit_registry.clear_cell(activeUnit.cell)
			var new_cell = activeUnit.return_original()
			activeUnit.moved_hexes = 0
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
			apply_formation_control_state()
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
