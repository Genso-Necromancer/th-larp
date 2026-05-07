extends RefCounted
class_name BoardEventResolver

var board: GameBoard


func _init(owner: GameBoard) -> void:
	board = owner


func process_event_queue() -> void:
	board.turn_step = GameBoard.TURN_STEPS.PROCESSING
	board.current_map.check_map_completion()
	board.update_canto_trigger_from_last_results()
	if board.active_died:
		handle_active_unit_death()
	elif Global.meta_state == Global.META_STATES.GAME_OVER:
		board.turn_step = GameBoard.TURN_STEPS.END_PHASE
	elif board.exp_events:
		board.turn_step = GameBoard.TURN_STEPS.EXP_GRANT
	else:
		board.turn_step = GameBoard.TURN_STEPS.END_PHASE


func handle_active_unit_death() -> void:
	board.active_died = false
	match board.state:
		GameBoard.STATES.PLAYER_PHASE:
			board.turn_step = GameBoard.TURN_STEPS.EVENT_QUEUE
		GameBoard.STATES.ENEMY_PHASE, GameBoard.STATES.NPC_PHASE:
			board.turn_step = GameBoard.TURN_STEPS.EVENT_QUEUE


func process_exp_events() -> void:
	board.turn_step = GameBoard.TURN_STEPS.PROCESSING
	for event in board.exp_events:
		var recip: Unit
		var trig: Unit
		match event.Type:
			"Kill":
				recip = event.Killer
				trig = event.Kill
		if recip:
			recip.add_exp(event.Type, trig)
			await board.continue_turn
	board.exp_events.clear()
	board.turn_step = GameBoard.TURN_STEPS.EVENT_QUEUE


func on_animation_handler_sequence_complete() -> void:
	var has_post_events = check_effect_queue()
	board.apply_default_control_state()
	board._wipe_region()
	board.current_map.pathAttack.clear()
	if board.activeUnit:
		board.cursor.cell = board.activeUnit.cell
	if has_post_events:
		board.turn_step = GameBoard.TURN_STEPS.EFFECT_QUEUE
	else:
		update_unit_bars()


func update_unit_bars() -> void:
	board.turn_step = GameBoard.TURN_STEPS.BAR_ANIM
	board.bar_queue.append(board.activeUnit)
	board.bar_queue.append(board.targetUnit)
	board.activeUnit.update_life_bar()
	board.targetUnit.update_life_bar()


func on_bars_updated(unit: Unit) -> void:
	board.bar_queue.erase(unit)
	if !board.bar_queue and board.turn_step == GameBoard.TURN_STEPS.BAR_ANIM:
		board.turn_step = GameBoard.TURN_STEPS.EVENT_QUEUE


func check_effect_queue() -> bool:
	return board.effect_queue.size() > 0


func run_effect_queue() -> void:
	var post_events = sort_effect_queue()
	var type = Enums.EFFECT_TYPE
	var event_keys = post_events.keys()
	for actor in event_keys:
		for event in post_events[actor]:
			var t = event.Type
			var effect = event.EffectId
			var target = event.Target
			var is_wait = true
			match t:
				type.RELOC:
					board.combatManager.start_relocation(actor, target, effect)
				_:
					is_wait = false
			if is_wait:
				await board.continue_queue
	board.call_deferred("_clear_effect_queue")


func on_effect_complete() -> void:
	board.continue_queue.emit()
	update_unit_bars()


func sort_effect_queue() -> Dictionary:
	var seen := {}
	var post_events := {}
	for event in board.effect_queue:
		if !post_events.has(event.Actor):
			post_events[event.Actor] = []
			seen[event.Actor] = []
		if seen[event.Actor].has(event.Type):
			continue
		else:
			seen[event.Actor].append(event.Type)
			post_events[event.Actor].append(event)
	return post_events


func add_effect_queue(new_event) -> void:
	board.effect_queue.append(new_event)


func clear_effect_queue() -> void:
	board.effect_queue.clear()
	board.turn_step = GameBoard.TURN_STEPS.EVENT_QUEUE
