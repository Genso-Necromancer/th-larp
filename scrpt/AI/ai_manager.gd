extends Node
class_name AiManager

@export var mind : Personality

enum ROUND_INTENT {
	STABLE_DEFENSE,
	EMERGENCY_HOLD,
	PATCH_LINE,
	PRESS_ADVANTAGE,
	PICK_OFF_EXPOSED,
	TASK_WINDOW,
	PREPARE_ENGAGEMENT,
}

enum UNIT_JOB {
	HOLD_POINT,
	BLOCK_PATH,
	HEAL_ALLY,
	BUFF_ALLY,
	DEBUFF_TARGET,
	KILL_TARGET,
	CHIP_TARGET,
	REPOSITION_DEFENSE,
	PRESS_FORWARD,
	PROTECT_BOSS,
	WAIT_IN_FORMATION,
	BREACH,
	LOOT,
}

const LIVE_SUPPORTED_ACTIONS := {
	Action.ACTION_TYPE.MOVE: true,
	Action.ACTION_TYPE.ATTACK: true,
	Action.ACTION_TYPE.SKILL_HOSTILE: true,
	Action.ACTION_TYPE.SKILL_FRIENDLY: true,
	Action.ACTION_TYPE.USE_ITEM: true,
	Action.ACTION_TYPE.WAIT: true,
}

# Live references needed to build and score simulated choices.
var director: GameBoard
var map: GameMap
var forecast_service: ForecastService

# Per-role bias is applied after commander personality, so unit identity
# bends scoring without replacing the map's overall commander intent.
const ROLE_BIASES := {
	Unit.AI_ROLE.NONE: {
		"offense": 1.0,
		"defense": 1.0,
		"position": 1.0,
		"tempo": 1.0,
		"support": 1.0,
		"objective": 1.0,
	},
	Unit.AI_ROLE.OFFENSE: {
		"offense": 1.2,
		"defense": 0.95,
		"position": 0.95,
		"tempo": 1.1,
		"support": 0.8,
		"objective": 1.0,
	},
	Unit.AI_ROLE.DEFENSE: {
		"offense": 0.9,
		"defense": 1.2,
		"position": 1.15,
		"tempo": 0.95,
		"support": 0.9,
		"objective": 1.0,
	},
	Unit.AI_ROLE.SUPPORT: {
		"offense": 0.75,
		"defense": 1.0,
		"position": 1.0,
		"tempo": 0.95,
		"support": 1.35,
		"objective": 1.0,
	},
	Unit.AI_ROLE.SABOTEUR: {
		"offense": 1.1,
		"defense": 0.9,
		"position": 1.05,
		"tempo": 1.05,
		"support": 1.15,
		"objective": 0.95,
	},
	Unit.AI_ROLE.SKIRMISHER: {
		"offense": 1.05,
		"defense": 0.95,
		"position": 1.15,
		"tempo": 1.15,
		"support": 0.85,
		"objective": 1.0,
	},
	Unit.AI_ROLE.OBJECTIVE: {
		"offense": 0.9,
		"defense": 1.0,
		"position": 1.05,
		"tempo": 1.0,
		"support": 0.9,
		"objective": 1.35,
	},
	Unit.AI_ROLE.BOSS: {
		"offense": 1.05,
		"defense": 1.25,
		"position": 1.15,
		"tempo": 0.9,
		"support": 0.85,
		"objective": 1.1,
	},
}

const JOB_PRIORITIES := {
	UNIT_JOB.HOLD_POINT: 100,
	UNIT_JOB.BLOCK_PATH: 95,
	UNIT_JOB.HEAL_ALLY: 90,
	UNIT_JOB.BUFF_ALLY: 80,
	UNIT_JOB.DEBUFF_TARGET: 78,
	UNIT_JOB.KILL_TARGET: 75,
	UNIT_JOB.CHIP_TARGET: 70,
	UNIT_JOB.PROTECT_BOSS: 68,
	UNIT_JOB.REPOSITION_DEFENSE: 60,
	UNIT_JOB.PRESS_FORWARD: 55,
	UNIT_JOB.BREACH: 40,
	UNIT_JOB.LOOT: 30,
	UNIT_JOB.WAIT_IN_FORMATION: 10,
}


func init_ai(game_board: GameBoard):
	director = game_board
	map = get_parent()
	forecast_service = director.combatManager.forecast_service if director and director.combatManager else null


func build_board_state(faction: Enums.FACTION_ID) -> BoardState:
	var turn_order: Array[StringName] = director.turn_order if director else []
	var active_units: Dictionary[Vector2i, Unit] = director.units if director else {}
	return BoardState.new(active_units, faction, turn_order, map)


func get_scored_actions(faction: Enums.FACTION_ID) -> Array[Dictionary]:
	var state := build_board_state(faction)
	var assessment := build_board_assessment(state, faction)
	var round_intent := determine_round_intent(assessment)
	var scored: Array[Dictionary] = []
	print("[AI] Building scored actions for faction: ", Enums.FACTION_ID.keys()[faction])
	print("[AI] Round intent: ", ROUND_INTENT.keys()[round_intent])
	for unit in state.get_units_for_faction(faction):
		if unit == null:
			continue
		var can_take_turn: bool = state.can_unit_take_turn(unit)
		print("[AI] Unit ", unit.id, " | can_act=", unit.can_act(), " | can_take_turn=", can_take_turn, " | cell=", unit.cell, " | role=", Unit.AI_ROLE.keys()[int(unit.ai_role)], " | task=", Unit.AI_TASK.keys()[int(unit.ai_task)])
		if unit == null or not can_take_turn:
			continue
		var assigned_job := assign_unit_job(state, unit, assessment, round_intent)
		var preferred_actions := state.generate_preferred_actions_for_unit(unit.id)
		print("[AI] Preferred actions for ", unit.id, ": ", preferred_actions.size(), " | job=", UNIT_JOB.keys()[assigned_job])
		for action in preferred_actions:
			scored.append({
				"unit_id": unit.id,
				"action": action,
				"job": assigned_job,
				"job_priority": get_job_priority(assigned_job),
				"score": score_action(state, unit, action, assessment, round_intent, assigned_job),
			})
	scored.sort_custom(func(a, b):
		var a_priority := int(a.get("job_priority", 0))
		var b_priority := int(b.get("job_priority", 0))
		if a_priority == b_priority:
			return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
		return a_priority > b_priority
	)
	for i in range(mini(5, scored.size())):
		var entry: Dictionary = scored[i]
		var action: Action = entry.get("action", null)
		if action == null:
			continue
		print("[AI] Candidate ", i + 1, " | unit=", entry.get("unit_id", ""), " | job=", UNIT_JOB.keys()[int(entry.get("job", UNIT_JOB.WAIT_IN_FORMATION))], " | type=", Action.ACTION_TYPE.keys()[int(action.type)], " | from=", action.from_cell, " | target_cell=", action.target_cell, " | target_unit=", action.target_unit_id, " | score=", float(entry.get("score", 0.0)))
	return scored


func get_best_action(faction: Enums.FACTION_ID) -> Dictionary:
	var scored := get_scored_actions(faction)
	if scored.is_empty():
		return {}
	return scored.front()


func is_live_supported_action(action: Action) -> bool:
	if action == null:
		return false
	return bool(LIVE_SUPPORTED_ACTIONS.get(int(action.type), false))


func get_best_executable_action(faction: Enums.FACTION_ID) -> Dictionary:
	var scored := get_scored_actions(faction)
	for entry in scored:
		var action: Action = entry.get("action", null)
		if is_live_supported_action(action):
			print("[AI] Best executable action | unit=", entry.get("unit_id", ""), " | job=", UNIT_JOB.keys()[int(entry.get("job", UNIT_JOB.WAIT_IN_FORMATION))], " | type=", Action.ACTION_TYPE.keys()[int(action.type)], " | score=", float(entry.get("score", 0.0)))
			return entry
		elif action != null:
			print("[AI] Skipping unsupported action type: ", Action.ACTION_TYPE.keys()[int(action.type)], " for unit ", entry.get("unit_id", ""))
	print("[AI] No executable action found for faction: ", Enums.FACTION_ID.keys()[faction])
	return {}


# Top-level action score = board position + tempo + task pressure + action-specific value.
func score_action(state: BoardState, unit: UnitSim, action: Action, assessment: BoardAssessment, round_intent: int, job: int) -> float:
	if state == null or unit == null or action == null:
		return -INF

	var weights: Dictionary = mind.get_category_weights() if mind else {}
	var role_bias: Dictionary = ROLE_BIASES.get(int(unit.ai_role), ROLE_BIASES[Unit.AI_ROLE.NONE])
	var score := 0.0

	score += _score_position(state, unit, action, weights, role_bias)
	score += _score_tempo(state, unit, action, weights, role_bias)
	score += _score_task(state, unit, action, weights, role_bias)
	score += _score_job_alignment(state, unit, action, assessment, round_intent, job, weights, role_bias)

	match action.type:
		Action.ACTION_TYPE.ATTACK, Action.ACTION_TYPE.SKILL_HOSTILE:
			score += _score_hostile_action(state, unit, action, weights, role_bias)
		Action.ACTION_TYPE.SKILL_FRIENDLY:
			score += _score_support_action(state, unit, action, weights, role_bias)
		Action.ACTION_TYPE.USE_ITEM:
			var item_target := state.get_unit_by_id(action.target_unit_id)
			if item_target != null and state._is_hostile_team(int(unit.team), int(item_target.team)):
				score += _score_hostile_action(state, unit, action, weights, role_bias)
			else:
				score += _score_support_action(state, unit, action, weights, role_bias)
		Action.ACTION_TYPE.DOOR, Action.ACTION_TYPE.WALL, Action.ACTION_TYPE.CHEST:
			score += _score_object_action(state, unit, action, weights, role_bias)
		Action.ACTION_TYPE.WAIT:
			score += _score_wait_action(unit, job, weights, role_bias)

	return score


func _score_position(state: BoardState, unit: UnitSim, action: Action, weights: Dictionary, role_bias: Dictionary) -> float:
	var position_weights: Dictionary = _get_dict(weights, "position")
	var terrain_weight := _get_float(position_weights, "terrain", 1.0)
	var objective_weight := _get_float(position_weights, "objective_pressure", 1.0)
	var pressure_weight := _get_float(position_weights, "unit_pressure", 1.0)
	var final_cell := unit.cell
	match action.type:
		Action.ACTION_TYPE.MOVE, Action.ACTION_TYPE.CANTO:
			final_cell = action.target_cell if action.target_cell != Vector2i.ZERO else unit.cell
		_:
			final_cell = action.from_cell if action.from_cell != Vector2i.ZERO else unit.cell
	var terrain_value := _get_terrain_value_for_cell(state, final_cell)
	var score := terrain_value * terrain_weight * _get_float(role_bias, "position", 1.0)
	score += _score_context_hint(state, unit, action, final_cell, weights, role_bias)

	var nearest_enemy_distance := _get_nearest_enemy_distance(state, unit, final_cell)
	if nearest_enemy_distance > -1:
		score += (1.0 / float(nearest_enemy_distance + 1)) * pressure_weight * 0.5 * _get_float(role_bias, "position", 1.0)

	match int(unit.ai_task):
		Unit.AI_TASK.LOOT:
			score += _get_task_progress_to_chests(state, final_cell) * objective_weight * _get_float(role_bias, "objective", 1.0)
		Unit.AI_TASK.BREACH:
			score += _get_task_progress_to_breach_targets(state, final_cell, unit) * objective_weight * _get_float(role_bias, "objective", 1.0)
		Unit.AI_TASK.HOLD:
			if action.from_cell == unit.cell or action.target_cell == unit.cell:
				score += 0.35 * objective_weight * _get_float(role_bias, "objective", 1.0)

	return score


func _score_tempo(_state: BoardState, unit: UnitSim, action: Action, weights: Dictionary, role_bias: Dictionary) -> float:
	var tempo_weights: Dictionary = _get_dict(weights, "tempo")
	var aggression := _get_float(tempo_weights, "aggression", 1.0)
	var wait_weight := _get_float(tempo_weights, "wait", 1.0)
	var tempo := _get_float(tempo_weights, "tempo", 1.0)
	var score := 0.0
	match action.type:
		Action.ACTION_TYPE.WAIT:
			score += 0.25 * wait_weight * _get_float(role_bias, "tempo", 1.0)
		Action.ACTION_TYPE.MOVE:
			score += 0.1 * tempo * _get_float(role_bias, "tempo", 1.0)
		_:
			score += 0.2 * aggression * _get_float(role_bias, "tempo", 1.0)
	if unit.has_active_leash() and action.type != Action.ACTION_TYPE.WAIT:
		score += 0.05
	return score


func _score_task(_state: BoardState, unit: UnitSim, action: Action, _weights: Dictionary, role_bias: Dictionary) -> float:
	var score := 0.0
	match int(unit.ai_task):
		Unit.AI_TASK.LOOT:
			if action.type == Action.ACTION_TYPE.CHEST:
				score += 1.0 * _get_float(role_bias, "objective", 1.0)
		Unit.AI_TASK.BREACH:
			if action.type == Action.ACTION_TYPE.DOOR or action.type == Action.ACTION_TYPE.WALL:
				score += 0.9 * _get_float(role_bias, "objective", 1.0)
		Unit.AI_TASK.HOLD:
			if action.type == Action.ACTION_TYPE.WAIT:
				score += 0.35 * _get_float(role_bias, "objective", 1.0)
	return score


# Hostile actions use the shared forecast service so AI scoring stays aligned
# with the same combat math the player sees in forecast UI.
func _score_hostile_action(state: BoardState, unit: UnitSim, action: Action, weights: Dictionary, role_bias: Dictionary) -> float:
	var offense: Dictionary = _get_dict(weights, "offense")
	var defense: Dictionary = _get_dict(weights, "defense")
	var tuning: Dictionary = _get_dict(weights, "tuning")
	var forecast := _get_action_forecast(state, unit, action)
	if forecast == null:
		return 0.0

	var action_node := _get_initiator_action_node(forecast)
	if action_node.is_empty():
		return 0.0

	var swing := _get_first_swing(action_node)
	var target := state.get_unit_by_id(action.target_unit_id)
	if target == null:
		return 0.0

	var hit_rate := float(swing.get("hit_chance", 0)) / 100.0
	var preview_damage: float = float(swing.get("dmg", 0)) * float(max(1, int(action_node.get("swing_count", 1))))
	var target_life_after := int(action_node.get("target_life_after", target.current_life))
	var expected_damage: float = preview_damage * hit_rate

	var score := 0.0
	score += (expected_damage / 10.0) * _get_float(offense, "damage", 1.0) * _get_float(role_bias, "offense", 1.0)
	score += hit_rate * _get_float(offense, "accuracy", 1.0) * 0.5 * _get_float(role_bias, "offense", 1.0)

	if target_life_after <= 0:
		score += 2.0 * _get_float(offense, "kill_finish", 1.0) * _get_float(role_bias, "offense", 1.0)

	if not bool(action_node.get("counter_possible", false)):
		score += _get_float(tuning, "safe_attack_bonus", 1.0) * _get_float(role_bias, "offense", 1.0)

	var retaliation := _get_counter_damage_against_actor(forecast, unit)
	if retaliation > 0:
		var hp_pct: float = float(unit.current_life) / max(1.0, float(unit.active_stats.get("Life", 1)))
		var survival_weight := _get_float(defense, "survival", 1.0)
		var lethality_weight := _get_float(defense, "lethality_respect", 1.0)
		score -= (retaliation / 10.0) * survival_weight * _get_float(role_bias, "defense", 1.0)
		if hp_pct <= _get_float(defense, "risk_threshold", 0.5):
			score -= (retaliation / 8.0) * lethality_weight * _get_float(role_bias, "defense", 1.0)

	return score


# Friendly actions are still heuristic for now; this pass values stabilizing
# low-health allies without needing a deeper support simulator yet.
func _score_support_action(state: BoardState, unit: UnitSim, action: Action, weights: Dictionary, role_bias: Dictionary) -> float:
	var offense: Dictionary = _get_dict(weights, "offense")
	var defense: Dictionary = _get_dict(weights, "defense")
	var target := state.get_unit_by_id(action.target_unit_id)
	if target == null:
		return 0.0

	var support_bias := _get_float(offense, "support_bias", 1.0) * _get_float(role_bias, "support", 1.0)
	var survival_weight := _get_float(defense, "survival", 1.0) * _get_float(role_bias, "support", 1.0)
	var missing_life: int = max(0, int(target.active_stats.get("Life", 0)) - int(target.current_life))
	var score := (float(missing_life) / 10.0) * support_bias

	if target.id != unit.id:
		score += 0.2 * support_bias

	var hp_pct: float = float(target.current_life) / max(1.0, float(target.active_stats.get("Life", 1)))
	if hp_pct <= _get_float(defense, "risk_threshold", 0.5):
		score += 0.8 * survival_weight

	return score


func _score_object_action(_state: BoardState, _unit: UnitSim, action: Action, weights: Dictionary, role_bias: Dictionary) -> float:
	var position_weights: Dictionary = _get_dict(weights, "position")
	var objective_weight := _get_float(position_weights, "objective_pressure", 1.0)
	var score := 0.0
	match action.type:
		Action.ACTION_TYPE.CHEST:
			score += 1.6
		Action.ACTION_TYPE.DOOR:
			score += 1.0
		Action.ACTION_TYPE.WALL:
			score += 0.8
	return score * objective_weight * _get_float(role_bias, "objective", 1.0)


func _score_wait_action(unit: UnitSim, job: int, weights: Dictionary, role_bias: Dictionary) -> float:
	var tempo_weights: Dictionary = _get_dict(weights, "tempo")
	var wait_weight := _get_float(tempo_weights, "wait", 1.0)
	var score := 0.15 * wait_weight * _get_float(role_bias, "tempo", 1.0)
	if unit.ai_task == Unit.AI_TASK.HOLD:
		score += 0.3 * _get_float(role_bias, "objective", 1.0)
	if int(unit.ai_role) == Unit.AI_ROLE.DEFENSE:
		score += 0.08 * _get_float(role_bias, "objective", 1.0)
	if job == UNIT_JOB.WAIT_IN_FORMATION or job == UNIT_JOB.HOLD_POINT:
		score += 0.2 * _get_float(role_bias, "objective", 1.0)
	return score


func build_board_assessment(state: BoardState, faction: Enums.FACTION_ID) -> BoardAssessment:
	var assessment := BoardAssessment.new()
	assessment.faction = faction
	assessment.objective_context = _determine_objective_context(state, faction)
	assessment.seize_tiles = _get_seize_tiles(state)
	assessment.actions_remaining = state.get_units_for_faction(faction).filter(func(unit): return unit != null and state.can_unit_take_turn(unit)).size()
	assessment.player_can_seize_now = _player_can_seize_now(state)
	assessment.player_can_seize_next_round = _player_can_seize_next_round(state)
	assessment.seize_tile_threatened = assessment.player_can_seize_now or assessment.player_can_seize_next_round
	assessment.healable_allies = _get_healable_allies(state, faction)
	assessment.high_value_targets = _get_high_value_targets(state, faction)
	assessment.safe_attackers = _get_safe_attackers(state, faction)
	assessment.special_tasks_available = _get_special_tasks_available(state, faction)
	assessment.boss_threatened = _is_boss_threatened(state, faction)
	assessment.threatened_allies = _get_threatened_allies(state, faction)
	assessment.line_is_broken = _is_line_broken(state, faction, assessment)
	assessment.tempo_advantage = _has_tempo_advantage(state, faction)
	return assessment


func determine_round_intent(assessment: BoardAssessment) -> int:
	if assessment == null:
		return ROUND_INTENT.STABLE_DEFENSE
	if assessment.objective_context == BoardAssessment.OBJECTIVE_CONTEXT.SEIZE_DEFENSE:
		if assessment.player_can_seize_now or assessment.player_can_seize_next_round or assessment.boss_threatened:
			return ROUND_INTENT.EMERGENCY_HOLD
		if assessment.line_is_broken or not assessment.healable_allies.is_empty():
			return ROUND_INTENT.PATCH_LINE
		if assessment.tempo_advantage and not assessment.high_value_targets.is_empty():
			return ROUND_INTENT.PRESS_ADVANTAGE
		if not assessment.high_value_targets.is_empty():
			return ROUND_INTENT.PICK_OFF_EXPOSED
		if not assessment.special_tasks_available.is_empty():
			return ROUND_INTENT.TASK_WINDOW
		return ROUND_INTENT.PREPARE_ENGAGEMENT
	return ROUND_INTENT.STABLE_DEFENSE


func assign_unit_job(state: BoardState, unit: UnitSim, assessment: BoardAssessment, round_intent: int) -> int:
	if unit == null:
		return UNIT_JOB.WAIT_IN_FORMATION
	match int(unit.ai_task):
		Unit.AI_TASK.LOOT:
			return UNIT_JOB.LOOT
		Unit.AI_TASK.BREACH:
			return UNIT_JOB.BREACH
		Unit.AI_TASK.HOLD:
			return UNIT_JOB.HOLD_POINT

	match int(unit.ai_role):
		Unit.AI_ROLE.SUPPORT:
			if not assessment.healable_allies.is_empty():
				return UNIT_JOB.HEAL_ALLY
			return UNIT_JOB.WAIT_IN_FORMATION
		Unit.AI_ROLE.SABOTEUR:
			if _unit_has_hostile_skill_actions(state, unit):
				return UNIT_JOB.DEBUFF_TARGET
			return UNIT_JOB.CHIP_TARGET
		Unit.AI_ROLE.OFFENSE, Unit.AI_ROLE.SKIRMISHER:
			if _unit_has_hostile_action(state, unit):
				return UNIT_JOB.KILL_TARGET if not assessment.high_value_targets.is_empty() else UNIT_JOB.CHIP_TARGET
			return UNIT_JOB.PRESS_FORWARD
		Unit.AI_ROLE.DEFENSE:
			match round_intent:
				ROUND_INTENT.EMERGENCY_HOLD:
					return UNIT_JOB.BLOCK_PATH
				ROUND_INTENT.PATCH_LINE, ROUND_INTENT.PREPARE_ENGAGEMENT:
					return UNIT_JOB.REPOSITION_DEFENSE
				_:
					return UNIT_JOB.HOLD_POINT
		Unit.AI_ROLE.BOSS:
			if assessment.boss_threatened or round_intent == ROUND_INTENT.EMERGENCY_HOLD:
				return UNIT_JOB.PROTECT_BOSS
			if _unit_has_hostile_action(state, unit) and round_intent in [ROUND_INTENT.PRESS_ADVANTAGE, ROUND_INTENT.PICK_OFF_EXPOSED]:
				return UNIT_JOB.KILL_TARGET
			return UNIT_JOB.HOLD_POINT
		_:
			if _unit_has_hostile_action(state, unit):
				return UNIT_JOB.CHIP_TARGET
			return UNIT_JOB.WAIT_IN_FORMATION


func get_job_priority(job: int) -> int:
	return int(JOB_PRIORITIES.get(job, 0))


func _score_job_alignment(state: BoardState, unit: UnitSim, action: Action, assessment: BoardAssessment, round_intent: int, job: int, _weights: Dictionary, role_bias: Dictionary) -> float:
	var final_cell := unit.cell
	match action.type:
		Action.ACTION_TYPE.MOVE, Action.ACTION_TYPE.CANTO:
			final_cell = action.target_cell if action.target_cell != Vector2i.ZERO else unit.cell
		_:
			final_cell = action.from_cell if action.from_cell != Vector2i.ZERO else unit.cell

	match job:
		UNIT_JOB.HOLD_POINT:
			var score := 0.0
			score += _score_hint_presence(state, final_cell, "HOLD", 0.45)
			score += _score_hint_presence(state, final_cell, "DEFEND", 0.4)
			score += _score_hint_presence(state, final_cell, "BOSS_ZONE", 0.25)
			if action.type == Action.ACTION_TYPE.WAIT:
				score += 0.15
			return score * _get_float(role_bias, "objective", 1.0)
		UNIT_JOB.BLOCK_PATH:
			var block_score := _score_proximity_to_cells(state, final_cell, assessment.seize_tiles, 0.65)
			if action.type == Action.ACTION_TYPE.WAIT:
				block_score += 0.05
			return block_score * _get_float(role_bias, "defense", 1.0)
		UNIT_JOB.HEAL_ALLY:
			return 0.35 if action.type == Action.ACTION_TYPE.SKILL_FRIENDLY or action.type == Action.ACTION_TYPE.USE_ITEM else -0.08
		UNIT_JOB.BUFF_ALLY:
			return 0.25 if action.type == Action.ACTION_TYPE.SKILL_FRIENDLY else -0.05
		UNIT_JOB.DEBUFF_TARGET:
			return 0.3 if action.type == Action.ACTION_TYPE.SKILL_HOSTILE else 0.05 if action.type == Action.ACTION_TYPE.ATTACK else -0.08
		UNIT_JOB.KILL_TARGET:
			return 0.35 if action.type == Action.ACTION_TYPE.ATTACK or action.type == Action.ACTION_TYPE.SKILL_HOSTILE else -0.05
		UNIT_JOB.CHIP_TARGET:
			return 0.2 if action.type == Action.ACTION_TYPE.ATTACK or action.type == Action.ACTION_TYPE.SKILL_HOSTILE else 0.04 if action.type == Action.ACTION_TYPE.MOVE else -0.05
		UNIT_JOB.REPOSITION_DEFENSE:
			var reposition_score := 0.0
			reposition_score += _score_hint_presence(state, final_cell, "HOLD", 0.4)
			reposition_score += _score_hint_presence(state, final_cell, "DEFEND", 0.45)
			reposition_score += _score_hint_presence(state, final_cell, "RALLY", 0.18)
			reposition_score += _score_proximity_to_cells(state, final_cell, assessment.seize_tiles, 0.25)
			if action.type == Action.ACTION_TYPE.MOVE:
				reposition_score += 0.12
			return reposition_score * _get_float(role_bias, "position", 1.0)
		UNIT_JOB.PRESS_FORWARD:
			var pressure_score := _score_hint_presence(state, final_cell, "PRESSURE", 0.35)
			if action.type == Action.ACTION_TYPE.MOVE:
				pressure_score += 0.12
			return pressure_score * _get_float(role_bias, "tempo", 1.0)
		UNIT_JOB.PROTECT_BOSS:
			var boss_score := 0.0
			boss_score += _score_hint_presence(state, final_cell, "BOSS_ZONE", 0.45)
			boss_score += _score_hint_presence(state, final_cell, "DEFEND", 0.22)
			if round_intent == ROUND_INTENT.EMERGENCY_HOLD:
				boss_score += _score_proximity_to_cells(state, final_cell, assessment.seize_tiles, 0.2)
			return boss_score * _get_float(role_bias, "objective", 1.0)
		UNIT_JOB.WAIT_IN_FORMATION:
			var formation_score := 0.0
			formation_score += _score_hint_presence(state, final_cell, "RALLY", 0.25)
			formation_score += _score_hint_presence(state, final_cell, "HOLD", 0.18)
			if action.type == Action.ACTION_TYPE.WAIT:
				formation_score += 0.18
			return formation_score * _get_float(role_bias, "position", 1.0)
		UNIT_JOB.BREACH:
			return 0.45 if action.type == Action.ACTION_TYPE.DOOR or action.type == Action.ACTION_TYPE.WALL else 0.0
		UNIT_JOB.LOOT:
			return 0.45 if action.type == Action.ACTION_TYPE.CHEST else _score_hint_presence(state, final_cell, "LOOT_ROUTE", 0.25)
		_:
			return 0.0


func _determine_objective_context(state: BoardState, faction: Enums.FACTION_ID) -> int:
	if state == null or state.map == null:
		return BoardAssessment.OBJECTIVE_CONTEXT.UNKNOWN
	if faction == Enums.FACTION_ID.PLAYER:
		return BoardAssessment.OBJECTIVE_CONTEXT.UNKNOWN
	for objective in state.map.objectives:
		if objective is Seize:
			return BoardAssessment.OBJECTIVE_CONTEXT.SEIZE_DEFENSE
	return BoardAssessment.OBJECTIVE_CONTEXT.UNKNOWN


func _get_seize_tiles(state: BoardState) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if state == null or state.map == null:
		return out
	for layer in state.map.seizeLayers:
		if layer == null:
			continue
		for cell in layer.get_used_cells():
			if not out.has(cell):
				out.append(cell)
	return out


func _player_can_seize_now(state: BoardState) -> bool:
	var seize_tiles := _get_seize_tiles(state)
	if seize_tiles.is_empty():
		return false
	for unit in state.get_units_for_faction(Enums.FACTION_ID.PLAYER):
		if unit == null or not state.can_unit_take_turn(unit):
			continue
		if seize_tiles.has(unit.cell):
			return true
	return false


func _player_can_seize_next_round(state: BoardState) -> bool:
	var seize_tiles := _get_seize_tiles(state)
	if seize_tiles.is_empty():
		return false
	for unit in state.get_units_for_faction(Enums.FACTION_ID.PLAYER):
		if unit == null:
			continue
		var move_range := int(unit.active_stats.get("Move", 0))
		for seize_cell in seize_tiles:
			if state.get_hex_distance(unit.cell, seize_cell) <= move_range:
				return true
	return false


func _get_healable_allies(state: BoardState, faction: Enums.FACTION_ID) -> Array[String]:
	var out: Array[String] = []
	for unit in state.get_units_for_faction(faction):
		if unit == null:
			continue
		var max_life := int(unit.active_stats.get("Life", unit.current_life))
		if unit.current_life < max_life:
			out.append(unit.id)
	return out


func _get_high_value_targets(state: BoardState, faction: Enums.FACTION_ID) -> Array[String]:
	var out: Array[String] = []
	var enemy_faction := Enums.FACTION_ID.PLAYER if faction != Enums.FACTION_ID.PLAYER else Enums.FACTION_ID.ENEMY
	for unit in state.get_units_for_faction(enemy_faction):
		if unit == null:
			continue
		var max_life :int= max(1, int(unit.active_stats.get("Life", unit.current_life)))
		var hp_pct := float(unit.current_life) / float(max_life)
		if hp_pct <= 0.5:
			out.append(unit.id)
	return out


func _get_safe_attackers(state: BoardState, faction: Enums.FACTION_ID) -> Array[String]:
	var out: Array[String] = []
	for unit in state.get_units_for_faction(faction):
		if unit == null or not state.can_unit_take_turn(unit):
			continue
		for action in state.generate_preferred_actions_for_unit(unit.id):
			if action == null:
				continue
			if action.type == Action.ACTION_TYPE.ATTACK or action.type == Action.ACTION_TYPE.SKILL_HOSTILE:
				var forecast := _get_action_forecast(state, unit, action)
				var action_node := _get_initiator_action_node(forecast)
				if not action_node.is_empty() and not bool(action_node.get("counter_possible", false)):
					out.append(unit.id)
					break
	return out


func _get_special_tasks_available(state: BoardState, faction: Enums.FACTION_ID) -> Array[String]:
	var tasks: Array[String] = []
	for unit in state.get_units_for_faction(faction):
		if unit == null or not state.can_unit_take_turn(unit):
			continue
		match int(unit.ai_task):
			Unit.AI_TASK.LOOT:
				if not tasks.has("LOOT"):
					tasks.append("LOOT")
			Unit.AI_TASK.BREACH:
				if not tasks.has("BREACH"):
					tasks.append("BREACH")
	return tasks


func _is_boss_threatened(state: BoardState, faction: Enums.FACTION_ID) -> bool:
	for unit in state.get_units_for_faction(faction):
		if unit == null or int(unit.ai_role) != Unit.AI_ROLE.BOSS:
			continue
		for enemy in state.get_enemy_units_for(unit):
			var reach_max := int(enemy.weapon_reach.get("Max", 1)) if enemy.weapon_reach != null else 1
			var move_range := int(enemy.active_stats.get("Move", 0))
			if state.get_hex_distance(enemy.cell, unit.cell) <= move_range + reach_max:
				return true
	return false


func _get_threatened_allies(state: BoardState, faction: Enums.FACTION_ID) -> Array[String]:
	var out: Array[String] = []
	for unit in state.get_units_for_faction(faction):
		if unit == null:
			continue
		for enemy in state.get_enemy_units_for(unit):
			var reach_max := int(enemy.weapon_reach.get("Max", 1)) if enemy.weapon_reach != null else 1
			var move_range := int(enemy.active_stats.get("Move", 0))
			if state.get_hex_distance(enemy.cell, unit.cell) <= move_range + reach_max:
				out.append(unit.id)
				break
	return out


func _is_line_broken(state: BoardState, faction: Enums.FACTION_ID, assessment: BoardAssessment) -> bool:
	if assessment.player_can_seize_next_round:
		return true
	if assessment.threatened_allies.size() >= 2:
		return true
	for unit in state.get_units_for_faction(faction):
		if unit == null or int(unit.ai_role) != Unit.AI_ROLE.DEFENSE:
			continue
		var hint := state.get_context_hint(unit.cell)
		if hint != "HOLD" and hint != "DEFEND":
			return true
	return false


func _has_tempo_advantage(state: BoardState, faction: Enums.FACTION_ID) -> bool:
	var allies := state.get_units_for_faction(faction).filter(func(unit): return unit != null and state.can_unit_take_turn(unit)).size()
	var opponents := state.get_units_for_faction(Enums.FACTION_ID.PLAYER if faction != Enums.FACTION_ID.PLAYER else Enums.FACTION_ID.ENEMY).filter(func(unit): return unit != null and state.can_unit_take_turn(unit)).size()
	return allies > opponents


func _unit_has_hostile_action(state: BoardState, unit: UnitSim) -> bool:
	for action in state.generate_preferred_actions_for_unit(unit.id):
		if action == null:
			continue
		if action.type == Action.ACTION_TYPE.ATTACK or action.type == Action.ACTION_TYPE.SKILL_HOSTILE:
			return true
	return false


func _unit_has_hostile_skill_actions(state: BoardState, unit: UnitSim) -> bool:
	for action in state.generate_preferred_actions_for_unit(unit.id):
		if action == null:
			continue
		if action.type == Action.ACTION_TYPE.SKILL_HOSTILE:
			return true
	return false


func _score_hint_presence(state: BoardState, cell: Vector2i, hint_name: String, value: float) -> float:
	var score := 0.0
	if state.get_context_hint(cell) == hint_name:
		score += value
	for neighbor in state.get_neighbor_cells(cell):
		if state.get_context_hint(neighbor) == hint_name:
			score += value * 0.4
	return score


func _score_proximity_to_cells(state: BoardState, cell: Vector2i, targets: Array[Vector2i], value: float) -> float:
	if targets.is_empty():
		return 0.0
	var nearest := -1
	for target in targets:
		var dist := state.get_hex_distance(cell, target)
		if nearest == -1 or dist < nearest:
			nearest = dist
	if nearest == -1:
		return 0.0
	return (1.0 / float(nearest + 1)) * value


# Typed lookup helpers keep nested weight dictionaries readable and avoid
# leaking Variant inference through the evaluator.
func _get_dict(source: Dictionary, key: String, default_value: Dictionary = {}) -> Dictionary:
	var value = source.get(key, default_value)
	return value if value is Dictionary else default_value


func _get_float(source: Dictionary, key: String, default_value := 0.0) -> float:
	var value = source.get(key, default_value)
	if value == null:
		return float(default_value)
	return float(value)


func _score_context_hint(state: BoardState, unit: UnitSim, action: Action, final_cell: Vector2i, weights: Dictionary, role_bias: Dictionary) -> float:
	var position_weights: Dictionary = _get_dict(weights, "position")
	var tempo_weights: Dictionary = _get_dict(weights, "tempo")
	var objective_weight := _get_float(position_weights, "objective_pressure", 1.0) * _get_float(role_bias, "objective", 1.0)
	var position_weight := _get_float(role_bias, "position", 1.0)
	var tempo_weight := _get_float(role_bias, "tempo", 1.0)
	var support_weight := _get_float(role_bias, "support", 1.0)
	var aggression_weight := _get_float(tempo_weights, "aggression", 1.0)
	var score := _score_context_hint_at_cell(state, unit, action, final_cell, objective_weight, position_weight, tempo_weight, support_weight, aggression_weight)

	# Defense-oriented hints should influence local area control, not just exact
	# tile occupancy. Nearby HOLD/DEFEND cells still matter, just less strongly.
	if int(unit.ai_role) == Unit.AI_ROLE.DEFENSE or int(unit.ai_role) == Unit.AI_ROLE.BOSS:
		for neighbor in state.get_neighbor_cells(final_cell):
			score += _score_context_hint_at_cell(state, unit, action, neighbor, objective_weight, position_weight, tempo_weight, support_weight, aggression_weight) * 0.4

	return score


func _score_context_hint_at_cell(state: BoardState, unit: UnitSim, action: Action, cell: Vector2i, objective_weight: float, position_weight: float, tempo_weight: float, support_weight: float, aggression_weight: float) -> float:
	var hint := state.get_context_hint(cell)
	if hint == "":
		return 0.0
	var priority_scale := 1.0 + (0.2 * float(state.get_context_priority(cell)))

	match hint:
		"RALLY":
			if unit.ai_task == Unit.AI_TASK.HOLD or int(unit.ai_role) == Unit.AI_ROLE.DEFENSE or int(unit.ai_role) == Unit.AI_ROLE.SUPPORT:
				return 0.35 * position_weight * priority_scale
			return 0.18 * position_weight
		"HOLD":
			if action.type == Action.ACTION_TYPE.WAIT:
				return 0.45 * objective_weight * priority_scale
			if action.type == Action.ACTION_TYPE.ATTACK and cell == unit.cell:
				return 0.3 * objective_weight * priority_scale
			if int(unit.ai_role) == Unit.AI_ROLE.DEFENSE or int(unit.ai_role) == Unit.AI_ROLE.BOSS:
				return 0.28 * objective_weight * priority_scale
			return 0.12 * objective_weight
		"AMBUSH":
			if int(unit.ai_role) == Unit.AI_ROLE.SKIRMISHER or int(unit.ai_role) == Unit.AI_ROLE.OFFENSE or int(unit.ai_role) == Unit.AI_ROLE.SABOTEUR:
				return 0.3 * position_weight * priority_scale
			return 0.12 * position_weight
		"PRESSURE":
			if action.type != Action.ACTION_TYPE.WAIT:
				return 0.28 * aggression_weight * tempo_weight * priority_scale
			return -0.12 * tempo_weight
		"DEFEND":
			if int(unit.ai_role) == Unit.AI_ROLE.DEFENSE or int(unit.ai_role) == Unit.AI_ROLE.BOSS:
				return 0.45 * objective_weight * priority_scale
			if int(unit.ai_role) == Unit.AI_ROLE.SUPPORT:
				return 0.2 * support_weight * priority_scale
			return 0.18 * objective_weight * priority_scale
		"LOOT_ROUTE":
			if unit.ai_task == Unit.AI_TASK.LOOT:
				return 0.4 * objective_weight * priority_scale
			return 0.08 * objective_weight
		"BOSS_ZONE":
			if int(unit.ai_role) == Unit.AI_ROLE.BOSS:
				return 0.45 * objective_weight * priority_scale
			if int(unit.ai_role) == Unit.AI_ROLE.DEFENSE:
				return 0.22 * objective_weight * priority_scale
			return 0.08 * position_weight
		"NO_IDLE":
			if action.type == Action.ACTION_TYPE.WAIT:
				return -0.35 * tempo_weight
			return 0.08 * tempo_weight
		_:
			return 0.0


# Forecast scoring clones and applies the action first so combat is evaluated
# from the simulated post-move position rather than the live board position.
func _get_action_forecast(state: BoardState, unit: UnitSim, action: Action) -> CombatResults:
	if forecast_service == null:
		return null
	var actor_state := state.clone()
	actor_state.apply_action(action)
	var actor := actor_state.get_unit_by_id(unit.id)
	var target := actor_state.get_unit_by_id(action.target_unit_id)
	if actor == null or target == null:
		return null
	return forecast_service.get_forecast(actor, target, _to_combat_action_dict(action))


func _to_combat_action_dict(action: Action) -> Dictionary:
	match action.type:
		Action.ACTION_TYPE.ATTACK:
			return {"Weapon": true, "Skill": null, "Item": null, "ChargeHexes": int(action.moved_hexes)}
		Action.ACTION_TYPE.SKILL_HOSTILE, Action.ACTION_TYPE.SKILL_FRIENDLY:
			return {"Weapon": bool(action.skill.get("augment", false)) if typeof(action.skill) == TYPE_DICTIONARY else false, "Skill": action.skill, "Item": null, "ChargeHexes": int(action.moved_hexes)}
		Action.ACTION_TYPE.USE_ITEM:
			return {"Weapon": false, "Skill": null, "Item": action.item}
		_:
			return {"Weapon": false, "Skill": null, "Item": null}


# Forecast results are round/action/swing trees; these helpers pull out the
# initiator branch and the first representative swing for scoring.
func _get_initiator_action_node(forecast: CombatResults) -> Dictionary:
	if forecast == null:
		return {}
	for action_node in forecast.get_all_actions():
		if bool(action_node.get("is_initiator", false)):
			return action_node
	return {}


func _get_first_swing(action_node: Dictionary) -> Dictionary:
	var swings: Array = action_node.get("swings", [])
	if swings.is_empty():
		return {}
	return swings.front()


func _get_counter_damage_against_actor(forecast: CombatResults, actor: UnitSim) -> int:
	if forecast == null or actor == null:
		return 0
	for action_node in forecast.get_all_actions():
		if bool(action_node.get("is_initiator", false)):
			continue
		if String(action_node.get("target_id", "")) != actor.id:
			continue
		var swings: Array = action_node.get("swings", [])
		if swings.is_empty():
			return 0
		var swing: Dictionary = swings.front()
		return int(swing.get("dmg", 0)) * max(1, int(action_node.get("swing_count", 1)))
	return 0


# Terrain and task distance helpers are intentionally simple in the first pass.
# They exist to give personality and task weights something concrete to shape.
func _get_terrain_value_for_cell(state: BoardState, cell: Vector2i) -> float:
	var values := state.get_terrain_values(cell)
	if values.is_empty():
		return 0.0
	var old_value := 0.0
	old_value += float(values.get("GrzBonus", 0)) / 100.0
	old_value += float(values.get("DefBonus", 0)) / 10.0
	old_value += float(values.get("PwrBonus", 0)) / 10.0
	old_value += float(values.get("MagBonus", 0)) / 10.0
	old_value += float(values.get("HitBonus", 0)) / 100.0
	return old_value


func _get_nearest_enemy_distance(state: BoardState, unit: UnitSim, from_cell: Vector2i) -> int:
	var nearest := -1
	for enemy in state.get_enemy_units_for(unit):
		var dist := state.get_hex_distance(from_cell, enemy.cell)
		if nearest == -1 or dist < nearest:
			nearest = dist
	return nearest


func _get_task_progress_to_chests(state: BoardState, from_cell: Vector2i) -> float:
	if state.map == null or state.map.chests == null or state.map.chests.is_empty():
		return 0.0
	var nearest := -1
	for cell in state.map.chests.keys():
		var chest = state.map.chests[cell]
		if chest == null or not chest.is_locked:
			continue
		var dist := state.get_hex_distance(from_cell, cell)
		if nearest == -1 or dist < nearest:
			nearest = dist
	if nearest == -1:
		return 0.0
	return 1.0 / float(nearest + 1)


func _get_task_progress_to_breach_targets(state: BoardState, from_cell: Vector2i, unit: UnitSim) -> float:
	var nearest := -1
	if state.map == null:
		return 0.0
	if state.map.doors != null:
		for cell in state.map.doors.keys():
			var door = state.map.doors[cell]
			if not state._is_door_accessible_for(unit, door):
				continue
			var dist := state.get_hex_distance(from_cell, cell)
			if nearest == -1 or dist < nearest:
				nearest = dist
	for child in state.map.get_children():
		if child is BreakableWall and state._is_wall_accessible_for(unit, child):
			var wall_dist := state.get_hex_distance(from_cell, child.cell)
			if nearest == -1 or wall_dist < nearest:
				nearest = wall_dist
	if nearest == -1:
		return 0.0
	return 1.0 / float(nearest + 1)
