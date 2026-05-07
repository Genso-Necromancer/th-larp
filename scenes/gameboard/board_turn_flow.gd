extends RefCounted
class_name BoardTurnFlow

var board: GameBoard


func _init(owner: GameBoard) -> void:
	board = owner


func stand_by_step() -> void:
	board.turn_step = GameBoard.TURN_STEPS.START


func check_player_turn_step() -> void:
	match board.turn_step:
		GameBoard.TURN_STEPS.STAND_BY:
			stand_by_step()
		GameBoard.TURN_STEPS.EFFECT_QUEUE:
			await board._run_effect_queue()
		GameBoard.TURN_STEPS.EVENT_QUEUE:
			board._process_event_queue()
		GameBoard.TURN_STEPS.EXP_GRANT:
			await board._process_exp_events()
		GameBoard.TURN_STEPS.END_PHASE:
			await check_end_of_turn()
		GameBoard.TURN_STEPS.CANTO:
			board._start_canto()
		GameBoard.TURN_STEPS.END:
			if board.activeUnit:
				board._deselect_active_unit(true)
			check_next_state()


func check_enemy_turn_step() -> void:
	match board.turn_step:
		GameBoard.TURN_STEPS.STAND_BY:
			stand_by_step()
		GameBoard.TURN_STEPS.START:
			board.begin_ai_phase_action()
		GameBoard.TURN_STEPS.EFFECT_QUEUE:
			await board._run_effect_queue()
		GameBoard.TURN_STEPS.EVENT_QUEUE:
			board._process_event_queue()
		GameBoard.TURN_STEPS.EXP_GRANT:
			await board._process_exp_events()
		GameBoard.TURN_STEPS.END_PHASE:
			await check_end_of_turn()
		GameBoard.TURN_STEPS.CANTO:
			board.turn_step = GameBoard.TURN_STEPS.END
		GameBoard.TURN_STEPS.END:
			board.turn_step = GameBoard.TURN_STEPS.PROCESSING
			await board.finalize_ai_phase_action()
			check_next_state()


func initialize_turns(ignore_acted := false) -> void:
	board.turn_order.clear()
	board.turn_step = GameBoard.TURN_STEPS.STAND_BY
	for cell in board.units:
		var unit = board.units[cell]
		if ignore_acted and unit.check_status("Acted"):
			continue
		else:
			unit.set_acted(false)
		unit.isSelected = false
		unit.originCell = unit.cell
		unit.call_deferred("refresh_state_visual")
		match unit.FACTION_ID:
			Enums.FACTION_ID.PLAYER:
				board.turn_order.append("Player")
			Enums.FACTION_ID.ENEMY:
				board.turn_order.append("Enemy")
			Enums.FACTION_ID.NPC:
				board.turn_order.append("NPC")
		board._update_unit_terrain(unit)
	board.turn_order = board.turn_sort.sort_turns(board.turn_order)
	board.new_round.emit(board.turn_order)
	board.state = GameBoard.STATES.NEW_TURN


func turn_change() -> void:
	board.turn_order.pop_front()
	board.turn_counter += 1
	Global.progress_time(0, 10)
	if board.turn_order.size() == 0:
		board.state = GameBoard.STATES.ROUND_END
	else:
		board.state = GameBoard.STATES.NEW_TURN
		board.turn_step = GameBoard.TURN_STEPS.STAND_BY
	GameState.clear_state_lists()
	board._clear_player_action_flags()
	board.turn_changed.emit()


func start_next_turn() -> void:
	board.turn_step = GameBoard.TURN_STEPS.STAND_BY
	if board.turn_order[0] == "Enemy":
		GameState.change_state(board, GameState.gState.LOADING)
		board.state = GameBoard.STATES.ENEMY_PHASE
		board._remember_player_cursor_view()
		board._cursor_toggle(false, false)
	elif board.turn_order[0] == "Player":
		board.apply_default_control_state()
		board.state = GameBoard.STATES.PLAYER_PHASE
		board._cursor_toggle(true, false)
		board.call_deferred("_restore_player_cursor_view")
	elif board.turn_order[0] == "NPC":
		GameState.change_state(board, GameState.gState.LOADING)
		board.state = GameBoard.STATES.NPC_PHASE
		board._remember_player_cursor_view()
		board._cursor_toggle(false, false)

	if board.state == GameBoard.STATES.PLAYER_PHASE and board.early_end:
		GameState.change_state(board, GameState.gState.LOADING)
		set_next_acted()
		board.turn_step = GameBoard.TURN_STEPS.END_PHASE


func add_turn(faction) -> void:
	var team: StringName
	match faction:
		Enums.FACTION_ID.PLAYER:
			team = "Player"
		Enums.FACTION_ID.ENEMY:
			team = "Enemy"
		Enums.FACTION_ID.NPC:
			team = "NPC"
	board.turn_order.append(team)
	board.turn_added.emit(team)


func remove_turn(team_id) -> void:
	var team: StringName
	match team_id:
		Enums.FACTION_ID.PLAYER:
			team = "Player"
		Enums.FACTION_ID.ENEMY:
			team = "Enemy"
		Enums.FACTION_ID.NPC:
			team = "NPC"
	if board.turn_order[0] != team:
		var i = board.turn_order.rfind(team)
		board.turn_order.remove_at(i)
	board.turn_removed.emit(team)


func set_next_acted() -> void:
	for cell in board.units:
		if !board.units[cell].status.Acted and board.units[cell].FACTION_ID == Enums.FACTION_ID.PLAYER:
			board.units[cell].set_acted(true)
			return


func check_end_of_turn() -> void:
	if board.death_list:
		await board._wipe_dead()
	if !board.activeUnit:
		board.turn_step = GameBoard.TURN_STEPS.END
	elif board.activeUnit.can_canto():
		board.turn_step = GameBoard.TURN_STEPS.CANTO
	else:
		board.turn_step = GameBoard.TURN_STEPS.END


func check_next_state() -> void:
	match Global.meta_state:
		Global.META_STATES.GAME_OVER:
			board.state = GameBoard.STATES.GAME_OVER
		Global.META_STATES.VICTORY:
			board.state = GameBoard.STATES.VICTORY
		_:
			turn_change()


func round_change() -> void:
	board.early_end = false
	initialize_turns()


func round_duration_tick() -> void:
	var keys = board.global_effects.keys()
	for eff_id in keys:
		board.global_effects[eff_id].duration -= 1
		if board.global_effects[eff_id].duration <= 0 and board.global_effects[eff_id].type == "Time":
			Global.reset_time_factor()
			board.global_effects.erase(eff_id)
		else:
			board.global_effects.erase(eff_id)


func check_end_of_round_events() -> void:
	if board.cursor.visible:
		board.cursor.visible = false
	if GameState.state != GameState.gState.GB_END_OF_ROUND:
		GameState.change_state(board, GameState.gState.GB_END_OF_ROUND)
	match board.round_step:
		GameBoard.ROUND_STEPS.CHECK:
			board.round_step = GameBoard.ROUND_STEPS.DANMAKU
		GameBoard.ROUND_STEPS.DANMAKU:
			board.round_step = GameBoard.ROUND_STEPS.SCENE
		GameBoard.ROUND_STEPS.SCENE:
			board.round_step = GameBoard.ROUND_STEPS.REINFORCE
		GameBoard.ROUND_STEPS.REINFORCE:
			board.round_step = GameBoard.ROUND_STEPS.END
		GameBoard.ROUND_STEPS.END:
			round_duration_tick()
			round_change()
			board.state = GameBoard.STATES.NEW_TURN
