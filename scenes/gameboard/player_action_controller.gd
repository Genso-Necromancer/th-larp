extends RefCounted
class_name PlayerActionController

var board: GameBoard


func _init(owner: GameBoard) -> void:
	board = owner


func begin_targeting_for_active_action() -> void:
	if !board.active_action:
		return
	board.apply_scene_control_state()

	if board.active_action.Skill:
		board.start_skill_targeting(board.active_action.Skill)
	elif board.active_action.Item:
		board.start_item_targeting(board.active_action.Item)
	elif board.active_action.Weapon:
		board.start_attack_targeting()


func begin_attack_action() -> void:
	if board.activeUnit == null:
		return
	board.start_attack_targeting()


func begin_skill_action(skill) -> void:
	if board.activeUnit == null:
		return
	board.start_skill_targeting(skill)


func commit_wait_action() -> void:
	if board.activeUnit == null:
		return
	board.unit_wait()


func cancel_action_menu_flow() -> void:
	if board.state == GameBoard.STATES.PLAYER_PHASE:
		player_phase_menu_canceled()


func resume_targeting_for_active_action() -> void:
	if board.active_action.Item:
		board.start_item_targeting(board.active_action.Item)
	elif board.active_action.Skill:
		board.start_skill_targeting(board.active_action.Skill)
	elif board.active_action.Weapon:
		board.start_attack_targeting()


func player_phase_menu_canceled() -> void:
	match board.turn_step:
		GameBoard.TURN_STEPS.OPTIONS:
			board.turn_step = GameBoard.TURN_STEPS.START
		GameBoard.TURN_STEPS.ACTIONS:
			if board.is_post_move_step():
				if PlayerData.traded or PlayerData.item_used:
					board.turn_step = GameBoard.TURN_STEPS.ACTIONS
					board.unit_move_ended.emit(board.activeUnit)
				else:
					board.turn_step = GameBoard.TURN_STEPS.START
					board.rollback_pending_selection_state()
					board.request_deselect()
			else:
				board.turn_step = GameBoard.TURN_STEPS.START
				board.rollback_pending_selection_state()
				board.request_deselect()
		GameBoard.TURN_STEPS.FORECAST_ATTACK:
			board.activeUnit.restore_equip()
			resume_targeting_for_active_action()
		_ when board.is_targeting_step():
			board._end_targeting()


func on_gui_move_selected() -> void:
	if board.activeUnit == null:
		return
	board.move_selection()


func on_gui_attack_selected() -> void:
	begin_attack_action()


func on_gui_skill_selected(skill) -> void:
	begin_skill_action(skill)


func on_gui_wait_selected() -> void:
	commit_wait_action()


func on_gui_action_menu_canceled() -> void:
	cancel_action_menu_flow()


func on_gui_item_selected(unit) -> void:
	board.activeUnit = unit
	board._set_action_actor(unit)


func on_gui_trade_selected(unit) -> void:
	board.activeUnit = unit
	board._set_action_actor(unit)


func on_gui_door_selected() -> void:
	board.door_targeting()


func on_gui_seize_selected(cell) -> void:
	SignalTower.action_seize.emit(cell)
	board.unit_seize()
