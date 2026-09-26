extends RefCounted
class_name BoardTargeting

var board: GameBoard


func _init(owner: GameBoard) -> void:
	board = owner


func draw_range(unit: Unit, max_range: int, min_range := 0, reach: Dictionary = {}) -> void:
	var path := get_cells_in_range(unit.cell, max_range, min_range)
	var bands := {}
	if not reach.is_empty():
		bands = get_band_cells(unit.cell, reach)
		path = _merge_band_cell_lists(bands)
	board.snap_path = path
	board.cursor.bump_cursor()
	if reach.is_empty():
		board.current_map.draw_attack(path)
	else:
		board.current_map.draw_attack_bands(bands)
	board.unit_path.stop()


func get_cells_in_range(cell: Vector2i, max_range: int, min_range: int) -> Array:
	var hex_star := AHexGrid2D.new(board.current_map)
	var path: Array = hex_star.find_target_paths(cell, max_range)
	if path.size() != 1 and min_range > 0:
		min_range = clampi(min_range - 1, 0, 1000)
		var invalid := hex_star.find_target_paths(cell, min_range)
		path = hex_star.trim_path(path, invalid)
	return path


func get_band_cells(cell: Vector2i, reach: Dictionary) -> Dictionary:
	var bands := {"Close": [], "Range": [], "Far": []}
	bands.Range = get_cells_in_range(cell, int(reach.get("Max", 0)), int(reach.get("Min", 0)))
	var close_min := _get_band_min(reach, "Close")
	var close_max := _get_band_max(reach, "Close")
	if close_min > 0 or close_max > 0:
		bands.Close = get_cells_in_range(cell, close_max, close_min)
	var far_min := _get_band_min(reach, "Far")
	var far_max := _get_band_max(reach, "Far")
	if far_min > 0 or far_max > 0:
		bands.Far = get_cells_in_range(cell, far_max, far_min)
	return bands


func _merge_band_cell_lists(bands: Dictionary) -> Array:
	var merged := []
	for band_name in ["Close", "Range", "Far"]:
		for cell in bands.get(band_name, []):
			if not merged.has(cell):
				merged.append(cell)
	return merged


func _get_band_min(reach: Dictionary, prefix: String) -> int:
	var min_reach := int(reach.get("%sMin" % prefix, 0))
	var max_reach := int(reach.get("%sMax" % prefix, 0))
	if min_reach == 0:
		min_reach = max_reach
	return min_reach


func _get_band_max(reach: Dictionary, prefix: String) -> int:
	var min_reach := int(reach.get("%sMin" % prefix, 0))
	var max_reach := int(reach.get("%sMax" % prefix, 0))
	if max_reach == 0:
		max_reach = min_reach
	return max_reach


func start_attack_targeting() -> void:
	if board.activeUnit == null:
		return
	var reach: Dictionary = board.activeUnit.get_weapon_reach()
	board.turn_step = GameBoard.TURN_STEPS.ATTACK_TARGET
	board._set_active_action(true, null, null)
	board._clear_action_target()
	board.block_targeting_confirm_for_frame()
	board.apply_targeting_control_state()
	var max_range := int(reach.get("Max", 0))
	max_range = maxi(max_range, _get_band_max(reach, "Close"))
	max_range = maxi(max_range, _get_band_max(reach, "Far"))
	var min_range := int(reach.get("Min", 0))
	var close_min := _get_band_min(reach, "Close")
	if close_min > 0:
		min_range = mini(min_range, close_min)
	var far_min := _get_band_min(reach, "Far")
	if far_min > 0:
		min_range = mini(min_range, far_min)
	draw_range(board.activeUnit, max_range, min_range, reach)


func start_skill_targeting(skill = null) -> void:
	if board.activeUnit == null:
		return
	var active_skill = skill
	if active_skill == null:
		return
	if active_skill is Skill and not board.activeUnit.can_use_skill(active_skill):
		return

	board.turn_step = GameBoard.TURN_STEPS.SKILL_TARGET
	board._set_active_action(active_skill.augment, active_skill, null)
	board._clear_action_target()
	board.block_targeting_confirm_for_frame()
	board.apply_targeting_control_state()

	var reach: Dictionary
	if board.active_action.Weapon:
		reach = board.activeUnit.get_aug_reach(board.active_action.Skill)
	else:
		reach = board.activeUnit.get_skill_reach(board.active_action.Skill)

	draw_range(board.activeUnit, reach.Max, reach.Min, reach)


func start_item_targeting(item: Consumable) -> void:
	if board.activeUnit == null or item == null:
		return
	board._set_active_action(false, null, item)
	board._clear_action_target()
	board.block_targeting_confirm_for_frame()
	draw_range(board.activeUnit, item.max_reach, item.min_reach)
	board.turn_step = GameBoard.TURN_STEPS.ITEM_TARGET
	board.apply_targeting_control_state()


func start_warp_destination_targeting(item: Consumable, target: Unit) -> void:
	if board.activeUnit == null or item == null or target == null:
		return
	board.pending_warp_item = item
	board.pending_warp_target = target
	board._set_action_target(target)
	board.block_targeting_confirm_for_frame()
	var cells := get_valid_warp_destination_cells(board.activeUnit, target)
	board.snap_path = cells
	board.cursor.bump_cursor()
	board.current_map.draw_attack(cells)
	board.unit_path.stop()
	board.turn_step = GameBoard.TURN_STEPS.WARP_TARGET
	board.apply_targeting_control_state()


func door_targeting() -> void:
	if board.activeUnit == null:
		return
	board.turn_step = GameBoard.TURN_STEPS.DOOR_TARGET
	board.block_targeting_confirm_for_frame()
	board.apply_targeting_control_state()
	draw_range(board.activeUnit, 1, 1)


func seek_trade(unit: Unit = null) -> void:
	var trade_unit := unit if unit != null else board.activeUnit
	if trade_unit == null:
		return
	board.activeUnit = trade_unit
	board.turn_step = GameBoard.TURN_STEPS.TRADE_TARGET
	board._clear_action_target()
	board.block_targeting_confirm_for_frame()
	draw_range(board.activeUnit, 1, 1)
	board.apply_targeting_control_state()


func end_targeting(emit_cancel := true) -> void:
	board._wipe_region()
	board.current_map.pathAttack.clear()
	board.cursor.cell = board.activeUnit.cell
	if emit_cancel:
		board.gameboard_targeting_canceled.emit()


func trade_target_selected() -> void:
	if board.targeting_input_blocked:
		return
	if board.focusUnit == null or board.activeUnit == null:
		return
	if board.focusUnit == board.activeUnit:
		return
	if not board._check_friendly(board.activeUnit, board.focusUnit):
		return
	board._set_action_target(board.focusUnit)
	end_targeting(false)
	if board.guiManager:
		board.guiManager.start_action_trade(board.activeUnit, board.targetUnit)


func feature_target_selected(feature: SlotWrapper) -> void:
	if board.targeting_input_blocked:
		return
	if not board.snap_path.has(board.cursor.cell):
		return
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
		if feature is Consumable and board.should_resolve_item_without_forecast(feature):
			board._set_action_target(board.focusUnit)
			if board.is_warp_item(feature):
				start_warp_destination_targeting(feature, board.focusUnit)
				return
			end_targeting(false)
			board.action_confirmed.emit()
			board.resolve_item_without_forecast(feature)
			return
		board.turn_step = GameBoard.TURN_STEPS.FORECAST_ATTACK
		grab_target(board.cursor.cell)


func attack_target_selected() -> void:
	if board.targeting_input_blocked:
		return
	if not board.snap_path.has(board.cursor.cell):
		return
	if board.is_occupied(board.cursor.cell) and not board._check_friendly(board.activeUnit, board.focusUnit):
		board.turn_step = GameBoard.TURN_STEPS.FORECAST_ATTACK
		grab_target(board.cursor.cell)


func warp_destination_selected() -> void:
	if board.targeting_input_blocked:
		return
	if board.pending_warp_item == null or board.pending_warp_target == null:
		return
	if not board.snap_path.has(board.cursor.cell):
		return
	var destination := board.cursor.cell
	var item := board.pending_warp_item
	var target := board.pending_warp_target
	board.pending_warp_item = null
	board.pending_warp_target = null
	end_targeting(false)
	board.action_confirmed.emit()
	board.resolve_warp_without_forecast(item, target, destination)


func get_valid_warp_destination_cells(actor: Unit, target: Unit) -> Array:
	if actor == null or target == null or board.current_map == null:
		return []
	var mag := int(actor.active_stats.get(&"Mag", 0))
	var radius := 2 + int(floor(float(mag) / 4.0))
	var hex := AHexGrid2D.new(board.current_map)
	hex._sort_solids()
	var cells: Array = hex.find_aura(actor.cell, radius)
	var valid_cells := []
	for cell in cells:
		if cell == target.cell:
			continue
		if not hex.is_valid_position(cell):
			continue
		if hex._is_solid_check(cell):
			continue
		if board.units.has(cell):
			continue
		valid_cells.append(cell)
	return valid_cells


func grab_target(cell: Vector2i) -> void:
	var hex_star := AHexGrid2D.new(board.current_map)
	if not board.units.has(cell):
		print("oops")
		return

	board._set_action_target(board.units[cell])
	var distance := hex_star.find_target_distance(board.activeUnit.cell, board.targetUnit.cell)
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
