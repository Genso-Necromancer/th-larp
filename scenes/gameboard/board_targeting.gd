extends RefCounted
class_name BoardTargeting

var board: GameBoard


func _init(owner: GameBoard) -> void:
	board = owner


func draw_range(unit: Unit, max_range: int, min_range := 0) -> void:
	var path := get_cells_in_range(unit.cell, max_range, min_range)
	board.snap_path = path
	board.cursor.bump_cursor()
	board.current_map.draw_attack(path)
	board.unit_path.stop()


func get_cells_in_range(cell: Vector2i, max_range: int, min_range: int) -> Array:
	var hex_star := AHexGrid2D.new(board.current_map)
	var path: Array = hex_star.find_all_paths(cell, max_range)
	if path.size() != 1 and min_range > 0:
		min_range = clampi(min_range - 1, 0, 1000)
		var invalid := hex_star.find_all_paths(cell, min_range)
		path = hex_star.trim_path(path, invalid)
	return path


func start_attack_targeting() -> void:
	if board.activeUnit == null:
		return
	var reach: Dictionary = board.activeUnit.get_weapon_reach()
	board.turn_step = GameBoard.TURN_STEPS.ATTACK_TARGET
	board._set_active_action(true, null, null)
	if GameState:
		GameState.change_state(board, GameState.gState.GB_ATTACK_TARGETING)
	draw_range(board.activeUnit, reach.Max, reach.Min)


func start_skill_targeting(skill = null) -> void:
	if board.activeUnit == null:
		return
	var active_skill = skill
	if active_skill == null:
		return

	board.turn_step = GameBoard.TURN_STEPS.SKILL_TARGET
	board._set_active_action(active_skill.augment, active_skill, null)
	if GameState:
		GameState.change_state(board, GameState.gState.GB_SKILL_TARGETING)

	var reach: Dictionary
	if board.active_action.Weapon:
		reach = board.activeUnit.get_aug_reach(board.active_action.Skill)
	else:
		reach = board.activeUnit.get_skill_reach(board.active_action.Skill)

	draw_range(board.activeUnit, reach.Max, reach.Min)


func start_item_targeting(item: Consumable) -> void:
	if board.activeUnit == null or item == null:
		return
	board._set_active_action(false, null, item)
	draw_range(board.activeUnit, item.max_reach, item.min_reach)
	board.turn_step = GameBoard.TURN_STEPS.ITEM_TARGET
	if GameState:
		GameState.change_state(board, GameState.gState.GB_ITEM_TARGETING)


func door_targeting() -> void:
	if board.activeUnit == null:
		return
	board.turn_step = GameBoard.TURN_STEPS.DOOR_TARGET
	if GameState:
		GameState.change_state(board, GameState.gState.GB_OBJECT_TARGETING)
	draw_range(board.activeUnit, 1, 1)


func seek_trade(unit: Unit = null) -> void:
	var trade_unit := unit if unit != null else board.activeUnit
	if trade_unit == null:
		return
	board.activeUnit = trade_unit
	board.turn_step = GameBoard.TURN_STEPS.TRADE_TARGET
	draw_range(board.activeUnit, 1, 1)
	if GameState:
		GameState.change_state(board, GameState.gState.GB_TRADE_TARGETING)


func end_targeting() -> void:
	board._wipe_region()
	board.current_map.pathAttack.clear()
	board.cursor.cell = board.activeUnit.cell
	board.gameboard_targeting_canceled.emit()


func trade_target_selected() -> void:
	if board.focusUnit == null or board.activeUnit == null:
		return
	if board.focusUnit == board.activeUnit:
		return
	if not board._check_friendly(board.activeUnit, board.focusUnit):
		return
	board._set_action_target(board.focusUnit)
	end_targeting()
	if board.guiManager:
		board.guiManager.start_action_trade(board.activeUnit, board.targetUnit)


func feature_target_selected(feature: SlotWrapper) -> void:
	if not board.is_occupied(board.cursor.cell):
		return
	if not feature:
		print("No Valid SkillID")
		return

	var friendly := false
	var valid := false
	if board.focusUnit.FACTION_ID == board.activeUnit.FACTION_ID or board.focusUnit.FACTION_ID == Enums.FACTION_ID.NPC:
		friendly = true

	match feature.target:
		Enums.SKILL_TARGET.SELF:
			if board.activeUnit == board.focusUnit:
				valid = true
		Enums.SKILL_TARGET.ENEMY:
			if not friendly:
				valid = true
		Enums.SKILL_TARGET.ALLY:
			if friendly and board.activeUnit != board.focusUnit:
				valid = true
		Enums.SKILL_TARGET.SELF_ALLY:
			if friendly:
				valid = true
		Enums.SKILL_TARGET.MAP:
			if board.activeUnit != board.focusUnit:
				valid = true

	if valid:
		board.turn_step = GameBoard.TURN_STEPS.FORECAST_ATTACK
		grab_target(board.cursor.cell)


func attack_target_selected() -> void:
	if board.is_occupied(board.cursor.cell) and not board._check_friendly(board.activeUnit, board.focusUnit):
		board.turn_step = GameBoard.TURN_STEPS.FORECAST_ATTACK
		grab_target(board.cursor.cell)


func grab_target(cell: Vector2i) -> void:
	var hex_star := AHexGrid2D.new(board.current_map)
	if not board.units.has(cell):
		print("oops")
		return

	board._set_action_target(board.units[cell])
	var distance := hex_star.compute_cost(board.activeUnit.cell, board.targetUnit.cell, board.activeUnit)
	var reach := [distance, distance]

	board._set_action_forecast(board.combatManager.get_forecast(board.activeUnit, board.targetUnit, board.active_action))
	SignalTower.forecast_predicted.emit({
		"results": board.get_last_forecast(),
		"attacker_unit": board.activeUnit,
		"defender_unit": board.targetUnit
	})

	var mode := 0 if board.active_action.Weapon else 1

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	board.target_focused.emit(mode, reach)
