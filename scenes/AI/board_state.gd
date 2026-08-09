extends Node
##Representation of the board's current state for AI evaluation
class_name BoardState

# Hex neighbor offsets for odd-q layout. Keeping them local avoids depending
# on the live pathfinder for every simulated move query.
const ODDQ_OFFSETS_EVEN := [
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
	Vector2i(0, -1),
]

const ODDQ_OFFSETS_ODD := [
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]

var map:GameMap
var units:Dictionary[Vector2i,UnitSim]
var units_by_id:Dictionary[String,UnitSim]
var turn:Enums.FACTION_ID
var turn_order:Array[StringName]
var terminal_conditions:Array[Objective]


# Build the sim state from live board units. Every unit enters as a UnitSim
# snapshot so later mutation never touches the live board.
func _init(source_units:Dictionary[Vector2i,Unit], source_turn:Enums.FACTION_ID, source_turn_order:Array[StringName], source_map:GameMap):
	units = {}
	units_by_id = {}
	turn = source_turn
	turn_order = source_turn_order.duplicate()
	map = source_map
	terminal_conditions = map.objectives if map else []
	for cell in source_units.keys():
		var source_unit = source_units[cell]
		if source_unit == null:
			continue
		_add_unit(source_unit.to_sim())


##Copies the current state of the board
func clone() -> BoardState:
	var newState = BoardState.new({},turn,turn_order,map)
	newState.units.clear()
	newState.units_by_id.clear()
	newState.turn = turn
	newState.turn_order = turn_order.duplicate()
	newState.map = map
	newState.terminal_conditions = terminal_conditions.duplicate()
	for unit_id in units_by_id.keys():
		var sim := units_by_id[unit_id] as UnitSim
		if sim == null:
			continue
		newState._add_unit(sim.clone())
	return newState


##Applies an action to the BoardState
func apply(turn_data:Turn)->BoardState:
	var sim:BoardState = clone()
	if turn_data == null:
		return sim
	for action_key in turn_data.turn_actions.keys():
		var action := turn_data.turn_actions[action_key] as Action
		if action == null:
			continue
		sim.apply_action(action)
	if not sim.turn_order.is_empty():
		sim.turn = sim.turn_order.pop_front()
	return sim


# Single-action application is the shared mutation entry point used by both
# evaluation and future search / lookahead.
func apply_action(action: Action) -> void:
	if action == null:
		return
	match action.type:
		Action.ACTION_TYPE.MOVE:
			_apply_move(action)
		Action.ACTION_TYPE.ATTACK:
			_apply_attack(action)
		Action.ACTION_TYPE.SKILL_HOSTILE:
			_apply_skill_hostile(action)
		Action.ACTION_TYPE.SKILL_FRIENDLY:
			_apply_skill_friendly(action)
		Action.ACTION_TYPE.WAIT:
			_apply_wait(action)
		Action.ACTION_TYPE.TRADE:
			_apply_trade(action)
		Action.ACTION_TYPE.USE_ITEM:
			_apply_use_item(action)
		Action.ACTION_TYPE.CANTO:
			_apply_canto(action)
		Action.ACTION_TYPE.DOOR:
			_apply_door(action)
		Action.ACTION_TYPE.CHEST:
			_apply_chest(action)
		Action.ACTION_TYPE.WALL:
			_apply_wall(action)
		Action.ACTION_TYPE.TIME_WARP:
			_apply_time_warp(action)


##Returns if BoardState is terminal
func is_terminal()->bool:
	return false

##Retrieves unit at given cell
func get_unit_at(cell: Vector2i)->UnitSim:
	return units.get(cell, null)

func get_unit_by_id(unit_id: String) -> UnitSim:
	return units_by_id.get(unit_id, null)

func get_terrain_data(cell: Vector2i)->Dictionary:
	return map.get_terrain_data(cell) if map else {}


func get_terrain_tags(cell: Vector2i) -> Dictionary:
	return map.get_terrain_tags(cell) if map else {}


func get_terrain_values(cell: Vector2i) -> Dictionary:
	return map.get_terrain_values(cell) if map else {}


func get_context_data(cell: Vector2i) -> Dictionary:
	return map.get_context_data(cell) if map else {"Hint": "", "Priority": 0}


func get_context_hint(cell: Vector2i) -> String:
	return String(get_context_data(cell).get("Hint", ""))


func get_context_priority(cell: Vector2i) -> int:
	return int(get_context_data(cell).get("Priority", 0))


func get_move_cost(unit: UnitSim, cell: Vector2i) -> int:
	if map == null or unit == null:
		return 1
	return maxi(1, int(ceil(map.get_movement_cost(cell, unit.move_type))))


func is_occupied(cell: Vector2i) -> bool:
	return units.has(cell)


func has_unit(unit_id: String) -> bool:
	return units_by_id.has(unit_id)


func get_units() -> Array[UnitSim]:
	var out: Array[UnitSim] = []
	for unit_id in units_by_id.keys():
		var sim := units_by_id[unit_id] as UnitSim
		if sim != null:
			out.append(sim)
	return out


func get_units_for_faction(faction: Enums.FACTION_ID) -> Array[UnitSim]:
	var out: Array[UnitSim] = []
	for sim in get_units():
		if sim.team == faction:
			out.append(sim)
	return out


func can_unit_take_turn(unit: UnitSim) -> bool:
	if unit == null or not unit.can_act():
		return false
	if not unit.has_status("Dazed"):
		return true
	for ally in get_units_for_faction(unit.team):
		if ally == null or ally.id == unit.id:
			continue
		if not ally.can_act():
			continue
		if not ally.has_status("Dazed"):
			return false
	return true


func get_enemy_units_for(unit: UnitSim) -> Array[UnitSim]:
	var out: Array[UnitSim] = []
	if unit == null:
		return out
	for sim in get_units():
		if sim.team != unit.team:
			out.append(sim)
	return out


func get_ally_units_for(unit: UnitSim) -> Array[UnitSim]:
	var out: Array[UnitSim] = []
	if unit == null:
		return out
	for sim in get_units():
		if sim.id != unit.id and sim.team == unit.team:
			out.append(sim)
	return out


func get_aura_sources_for_cell(cell: Vector2i, team_filter := -1) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	for sim in get_units():
		if sim == null or sim.owned_auras == null or sim.owned_auras.is_empty():
			continue
		if team_filter > -1 and int(sim.team) != int(team_filter):
			continue
		for aura_data in sim.owned_auras:
			if typeof(aura_data) != TYPE_DICTIONARY:
				continue
			var radius := int(aura_data.get("radius", 0))
			if radius <= 0:
				continue
			if cell.distance_to(sim.cell) > radius:
				continue
			var snapshot := aura_data.duplicate(true)
			snapshot["source"] = sim.id
			snapshot["source_cell"] = sim.cell
			sources.append(snapshot)
	return sources


# BoardState owns enough hex math to answer move and range questions without
# consulting the live board pathfinder, which still reasons about live units.
func is_cell_in_bounds(cell: Vector2i) -> bool:
	if map == null:
		return false
	return map.get_used_rect().has_point(cell)


func get_neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var offsets := ODDQ_OFFSETS_EVEN if fposmod(cell.x, 2) == 0 else ODDQ_OFFSETS_ODD
	for offset in offsets:
		var neighbor :Vector2i= cell + offset
		if is_cell_in_bounds(neighbor):
			out.append(neighbor)
	return out


func oddq_to_axial(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x, cell.y - int((cell.x - fposmod(cell.x, 2)) / 2))


func axial_distance(a: Vector2i, b: Vector2i) -> int:
	var vec := a - b
	return int((abs(vec.x) + abs(vec.x + vec.y) + abs(vec.y)) / 2)


func get_hex_distance(a: Vector2i, b: Vector2i) -> int:
	return axial_distance(oddq_to_axial(a), oddq_to_axial(b))


func _is_hostile_team(compare_team: int, other_team: int) -> bool:
	if compare_team == Enums.FACTION_ID.ENEMY and other_team == Enums.FACTION_ID.ENEMY:
		return false
	if compare_team != Enums.FACTION_ID.ENEMY and other_team != Enums.FACTION_ID.ENEMY:
		return false
	return true


func _get_solid_cells_for(unit: UnitSim) -> Dictionary:
	var solid := {}
	if map == null or unit == null:
		return solid

	var walls := map.get_walls()
	for cell in walls.get("Wall", []):
		solid[cell] = true

	for cell in walls.get("WallShoot", []):
		solid[cell] = true

	for cell in walls.get("WallFly", []):
		if unit.move_type == Enums.MOVE_TYPE.FLY:
			continue
		solid[cell] = true

	for other in get_units():
		if other == null or other.id == unit.id:
			continue
		if _is_hostile_team(int(unit.team), int(other.team)):
			if unit.move_type == Enums.MOVE_TYPE.FLY or unit.has_passive_type(Enums.PASSIVE_TYPE.PASS):
				continue
			solid[other.cell] = true
	return solid


# Constraints like leash and position lock filter the legal action surface
# before scoring, rather than becoming soft penalties later.
func get_effective_move_budget(unit: UnitSim) -> int:
	if unit == null:
		return 0
	var budget := int(unit.active_stats.get("Move", 0))
	if unit.remaining_move > 0:
		budget = min(budget, unit.remaining_move)
	if unit.has_active_leash():
		budget = min(budget, unit.leash_radius)
	return maxi(0, budget)


func refresh_unit_position_context(unit: UnitSim) -> void:
	if unit == null:
		return
	unit.set_position_context(unit.cell, get_terrain_tags(unit.cell), get_aura_sources_for_cell(unit.cell))


func remove_unit(unit_id: String) -> void:
	var sim := get_unit_by_id(unit_id)
	if sim == null:
		return
	units.erase(sim.cell)
	units_by_id.erase(unit_id)


func set_unit_cell(unit_id: String, new_cell: Vector2i) -> void:
	var sim := get_unit_by_id(unit_id)
	if sim == null:
		return
	units.erase(sim.cell)
	sim.cell = new_cell
	units[new_cell] = sim
	refresh_unit_position_context(sim)


func can_unit_end_on_cell(unit_id: String, cell: Vector2i) -> bool:
	var sim := get_unit_by_id(unit_id)
	if sim == null:
		return false
	if sim.is_position_locked() and cell != sim.cell:
		return false
	if is_occupied(cell) and get_unit_at(cell).id != unit_id:
		return false
	return true


func get_door_at(cell: Vector2i):
	if map == null or map.doors == null:
		return null
	return map.doors.get(cell, null)


func get_chest_at(cell: Vector2i):
	if map == null or map.chests == null:
		return null
	return map.chests.get(cell, null)


func get_breakable_wall_at(cell: Vector2i):
	if map == null:
		return null
	for child in map.get_children():
		if child is BreakableWall and child.cell == cell:
			return child
	return null


# Object interaction uses tile-side team labels from the map so the AI avoids
# sabotaging its own defenses while still allowing future traversal rules.
func _get_object_team_label(cell: Vector2i) -> StringName:
	if map == null or map.modifier == null:
		return &""
	var tile_data: TileData = map.modifier.get_cell_tile_data(cell)
	if tile_data == null:
		return &""
	var team_value = tile_data.get_custom_data("Team")
	return StringName(team_value) if team_value != null else &""


func _can_target_team_label(unit: UnitSim, team_label: StringName) -> bool:
	if unit == null:
		return false
	match int(unit.team):
		Enums.FACTION_ID.ENEMY:
			return team_label != &"Enemy"
		Enums.FACTION_ID.NPC:
			return team_label == &"Enemy"
		Enums.FACTION_ID.PLAYER:
			return team_label != &"Player"
		_:
			return false


func _is_door_accessible_for(unit: UnitSim, door) -> bool:
	if unit == null or door == null:
		return false
	if not door.enabled or door.is_destroyed or not door.is_locked:
		return false
	if not unit.has_passive_type(Enums.PASSIVE_TYPE.LOCKPICK):
		return false
	return _can_target_team_label(unit, _get_object_team_label(door.cell))


func _is_chest_accessible_for(unit: UnitSim, chest) -> bool:
	if unit == null or chest == null:
		return false
	if not chest.enabled or not chest.is_locked:
		return false
	if not unit.has_passive_type(Enums.PASSIVE_TYPE.LOCKPICK):
		return false
	return true


func _is_wall_accessible_for(unit: UnitSim, wall) -> bool:
	if unit == null or wall == null:
		return false
	if not wall.enabled or wall.is_destroyed:
		return false
	return _can_target_team_label(unit, _get_object_team_label(wall.cell))


# Targeting helpers mirror the live board's skill/item targeting contracts.
# The sim generator stays on the same SELF/ALLY/ENEMY/MAP semantics as gameplay.
func _get_weapon_reach(sim: UnitSim) -> Dictionary:
	if sim == null:
		return {}
	return sim.weapon_reach.duplicate(true) if sim.weapon_reach != null else {}


func _is_cell_in_reach(origin: Vector2i, target: Vector2i, reach: Dictionary) -> bool:
	if reach == null or reach.is_empty():
		return false
	var min_range := int(reach.get("Min", 1))
	var max_range := int(reach.get("Max", 1))
	var distance := get_hex_distance(origin, target)
	if distance >= min_range and distance <= max_range:
		return true
	return _is_distance_in_reach_band(reach, distance, "Close") or _is_distance_in_reach_band(reach, distance, "Far")


func _is_distance_in_reach_band(reach: Dictionary, distance: int, prefix: String) -> bool:
	var min_reach := int(reach.get("%sMin" % prefix, 0))
	var max_reach := int(reach.get("%sMax" % prefix, 0))
	if min_reach == 0 and max_reach == 0:
		return false
	if min_reach == 0:
		min_reach = max_reach
	if max_reach == 0:
		max_reach = min_reach
	return distance >= min_reach and distance <= max_reach


func _is_friendly_pair(actor: UnitSim, target: UnitSim) -> bool:
	if actor == null or target == null:
		return false
	return not _is_hostile_team(int(actor.team), int(target.team))


func _matches_skill_target(actor: UnitSim, target: UnitSim, target_type: int) -> bool:
	if actor == null:
		return false
	match target_type:
		Enums.SKILL_TARGET.SELF:
			return target != null and target.id == actor.id
		Enums.SKILL_TARGET.ENEMY:
			return target != null and _is_hostile_team(int(actor.team), int(target.team))
		Enums.SKILL_TARGET.ALLY:
			return target != null and target.id != actor.id and _is_friendly_pair(actor, target)
		Enums.SKILL_TARGET.SELF_ALLY:
			return target != null and _is_friendly_pair(actor, target)
		_:
			return false


func _is_skill_augment_valid(actor: UnitSim, skill) -> bool:
	if actor == null or skill == null:
		return false
	if not bool(skill.get("augment", false)):
		return true
	var wep := actor.get_equipped_weapon()
	if wep == null or wep.is_empty():
		return false
	var skill_cat := int(skill.get("weapon_category", Enums.WEAPON_CATEGORY.ANY))
	var skill_sub := int(skill.get("sub_group", Enums.WEAPON_SUB.NONE))
	var weapon_cat := int(wep.get("category", Enums.WEAPON_CATEGORY.NONE))
	var weapon_sub := int(wep.get("sub_group", Enums.WEAPON_SUB.NONE))
	if skill_cat != Enums.WEAPON_CATEGORY.ANY and weapon_cat != skill_cat and weapon_sub != skill_sub:
		return false
	var min_reach := int(skill.get("min_reach", 0))
	var max_reach := int(skill.get("max_reach", 0))
	if min_reach == 0 and max_reach == 0:
		return true
	var weapon_min := int(wep.get("min_reach", 0))
	var weapon_max := int(wep.get("max_reach", 0))
	return range(min_reach, max_reach + 1).has(weapon_min) or range(min_reach, max_reach + 1).has(weapon_max)


func _get_skill_reach_for_sim(actor: UnitSim, skill) -> Dictionary:
	if actor == null or skill == null:
		return {}
	if bool(skill.get("augment", false)):
		if not _is_skill_augment_valid(actor, skill):
			return {}
		var wep := actor.get_equipped_weapon()
		if wep == null or wep.is_empty():
			return {}
		var reach := {
			"Min": int(wep.get("min_reach", 0)),
			"Max": int(wep.get("max_reach", 0)),
			"CloseMin": int(wep.get("close_min_reach", 0)),
			"CloseMax": int(wep.get("close_max_reach", 0)),
			"FarMin": int(wep.get("far_min_reach", 0)),
			"FarMax": int(wep.get("far_max_reach", 0)),
		}
		var skill_min := int(skill.get("min_reach", 0))
		var skill_max := int(skill.get("max_reach", 0))
		if skill_min > 0 and skill_max > 0:
			reach.Min = skill_min
			reach.Max = skill_max
		reach.Min += int(skill.get("bonus_min_range", 0))
		reach.Max += int(skill.get("bonus_max_range", 0))
		return reach
	return {
		"Min": int(skill.get("min_reach", 0)),
		"Max": int(skill.get("max_reach", 0)),
	}


func _get_item_reach(item) -> Dictionary:
	if item == null:
		return {}
	var item_resource = _load_item_resource(item)
	var min_reach := int(item.get("min_reach", item.get("MinRange", item_resource.min_reach if item_resource != null else 0)))
	var max_reach := int(item.get("max_reach", item.get("MaxRange", item_resource.max_reach if item_resource != null else 0)))
	return {
		"Min": min_reach,
		"Max": max_reach,
	}


func _get_item_target_type(item) -> int:
	if item == null:
		return Enums.SKILL_TARGET.NONE
	var item_resource = _load_item_resource(item)
	var default_target = item_resource.target if item_resource != null else Enums.SKILL_TARGET.NONE
	var raw_target = item.get("target", item.get("Target", default_target))
	if typeof(raw_target) == TYPE_STRING:
		match String(raw_target).to_lower():
			"self":
				return Enums.SKILL_TARGET.SELF
			"ally":
				return Enums.SKILL_TARGET.ALLY
			"self_ally", "selfally":
				return Enums.SKILL_TARGET.SELF_ALLY
			"enemy":
				return Enums.SKILL_TARGET.ENEMY
			"map":
				return Enums.SKILL_TARGET.MAP
			_:
				return Enums.SKILL_TARGET.NONE
	return int(raw_target)


func _is_supported_ai_item(item) -> bool:
	if item == null:
		return false
	var item_class := String(item.get("class", item.get("Class", "")))
	return item_class == "Consumable" or item_class == "Ofuda"


func _load_item_resource(item):
	if item == null or typeof(item) != TYPE_DICTIONARY:
		return null
	var path := String(item.get("Properties", item.get("path", "")))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


func _generate_targeted_unit_actions_for_cells(unit_id: String, move_cells: Array[Vector2i], target_type: int, action_type: int, payload_key: String, payload) -> Array[Action]:
	var actions: Array[Action] = []
	var actor := get_unit_by_id(unit_id)
	if actor == null:
		return actions
	var candidate_units := get_units()
	var reach := {}
	if payload_key == "skill":
		reach = _get_skill_reach_for_sim(actor, payload)
	elif payload_key == "item":
		reach = _get_item_reach(payload)
	if reach.is_empty():
		return actions

	for move_cell in move_cells:
		for target in candidate_units:
			if not _matches_skill_target(actor, target, target_type):
				continue
			if not _is_cell_in_reach(move_cell, target.cell, reach):
				continue
			var action := Action.new()
			action.unit_id = actor.id
			action.type = action_type
			action.from_cell = move_cell
			action.target_cell = target.cell
			action.target_unit_id = target.id
			action.moved_hexes = get_hex_distance(actor.cell, move_cell)
			if payload_key == "skill":
				action.skill = payload
			elif payload_key == "item":
				action.item = payload
			actions.append(action)
	return actions


func _generate_targeted_map_actions_for_cells(unit_id: String, move_cells: Array[Vector2i], reach: Dictionary, action_type: int, payload_key: String, payload) -> Array[Action]:
	var actions: Array[Action] = []
	var actor := get_unit_by_id(unit_id)
	if actor == null or reach.is_empty():
		return actions
	var used_rect := map.get_used_rect() if map != null else Rect2i()
	for move_cell in move_cells:
		for x in range(used_rect.position.x, used_rect.end.x):
			for y in range(used_rect.position.y, used_rect.end.y):
				var target_cell := Vector2i(x, y)
				if target_cell == move_cell:
					continue
				if not _is_cell_in_reach(move_cell, target_cell, reach):
					continue
				var action := Action.new()
				action.unit_id = actor.id
				action.type = action_type
				action.from_cell = move_cell
				action.target_cell = target_cell
				if payload_key == "skill":
					action.skill = payload
				elif payload_key == "item":
					action.item = payload
				actions.append(action)
	return actions


# Reachability is a lightweight board-side BFS over simulated occupancy and
# move costs. It is the foundation for every generated action.
func get_reachable_cells_for_unit(unit_id: String, custom_budget := -1) -> Dictionary[Vector2i, int]:
	var unit := get_unit_by_id(unit_id)
	var reachable: Dictionary[Vector2i, int] = {}
	if unit == null:
		return reachable

	if unit.is_position_locked():
		reachable[unit.cell] = 0
		return reachable

	var budget := custom_budget if custom_budget > -1 else get_effective_move_budget(unit)
	reachable[unit.cell] = 0
	if budget <= 0:
		return reachable

	var solid := _get_solid_cells_for(unit)
	var frontier: Array[Vector2i] = [unit.cell]

	while not frontier.is_empty():
		var current :Vector2i= frontier.pop_front()
		var current_cost := int(reachable.get(current, 0))
		for neighbor in get_neighbor_cells(current):
			if solid.has(neighbor):
				continue
			var step_cost := get_move_cost(unit, neighbor)
			var next_cost := current_cost + step_cost
			if next_cost > budget:
				continue
			if is_occupied(neighbor) and get_unit_at(neighbor).id != unit.id:
				continue
			if reachable.has(neighbor) and int(reachable[neighbor]) <= next_cost:
				continue
			reachable[neighbor] = next_cost
			frontier.append(neighbor)

	return reachable


func get_reachable_cells_list_for_unit(unit_id: String, custom_budget := -1) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in get_reachable_cells_for_unit(unit_id, custom_budget).keys():
		cells.append(cell)
	return cells


func generate_move_actions_for_unit(unit_id: String, include_wait := true) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions

	if include_wait:
		var wait_action := Action.new()
		wait_action.unit_id = unit.id
		wait_action.type = Action.ACTION_TYPE.WAIT
		wait_action.from_cell = unit.cell
		wait_action.target_cell = unit.cell
		actions.append(wait_action)

	for cell in get_reachable_cells_for_unit(unit_id).keys():
		if cell == unit.cell:
			continue
		var move_action := Action.new()
		move_action.unit_id = unit.id
		move_action.type = Action.ACTION_TYPE.MOVE
		move_action.from_cell = unit.cell
		move_action.target_cell = cell
		actions.append(move_action)

	return actions


# Action generation is split by intent so task-aware filtering can reuse the
# same low-level pieces instead of rebuilding them.
func generate_attack_actions_for_unit(unit_id: String) -> Array[Action]:
	return _generate_attack_actions_for_cells(unit_id, get_reachable_cells_list_for_unit(unit_id))


func _generate_attack_actions_for_cells(unit_id: String, move_cells: Array[Vector2i]) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions

	var reach := _get_weapon_reach(unit)
	if reach.is_empty():
		return actions

	for move_cell in move_cells:
		for enemy in get_enemy_units_for(unit):
			if enemy == null or not enemy.is_alive():
				continue
			if not _is_cell_in_reach(move_cell, enemy.cell, reach):
				continue
			var action := Action.new()
			action.unit_id = unit.id
			action.type = Action.ACTION_TYPE.ATTACK
			action.from_cell = move_cell
			action.target_cell = enemy.cell
			action.target_unit_id = enemy.id
			action.moved_hexes = get_hex_distance(unit.cell, move_cell)
			actions.append(action)

	return actions


func generate_hold_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions

	actions.append_array(_generate_attack_actions_for_cells(unit_id, [unit.cell]))

	var wait_action := Action.new()
	wait_action.unit_id = unit.id
	wait_action.type = Action.ACTION_TYPE.WAIT
	wait_action.from_cell = unit.cell
	wait_action.target_cell = unit.cell
	actions.append(wait_action)
	return actions


func generate_door_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions
	if unit.ai_task != Unit.AI_TASK.BREACH and not unit.has_passive_type(Enums.PASSIVE_TYPE.LOCKPICK):
		return actions

	for move_cell in get_reachable_cells_for_unit(unit_id).keys():
		for neighbor in get_neighbor_cells(move_cell):
			var door = get_door_at(neighbor)
			if not _is_door_accessible_for(unit, door):
				continue
			var action := Action.new()
			action.unit_id = unit.id
			action.type = Action.ACTION_TYPE.DOOR
			action.from_cell = move_cell
			action.target_cell = neighbor
			actions.append(action)

	return actions


func generate_chest_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions
	if unit.ai_task != Unit.AI_TASK.LOOT and not unit.has_passive_type(Enums.PASSIVE_TYPE.LOCKPICK):
		return actions

	for move_cell in get_reachable_cells_for_unit(unit_id).keys():
		for neighbor in get_neighbor_cells(move_cell):
			var chest = get_chest_at(neighbor)
			if not _is_chest_accessible_for(unit, chest):
				continue
			var action := Action.new()
			action.unit_id = unit.id
			action.type = Action.ACTION_TYPE.CHEST
			action.from_cell = move_cell
			action.target_cell = neighbor
			actions.append(action)

	return actions


func generate_wall_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions

	for move_cell in get_reachable_cells_for_unit(unit_id).keys():
		for neighbor in get_neighbor_cells(move_cell):
			var wall = get_breakable_wall_at(neighbor)
			if not _is_wall_accessible_for(unit, wall):
				continue
			var action := Action.new()
			action.unit_id = unit.id
			action.type = Action.ACTION_TYPE.WALL
			action.from_cell = move_cell
			action.target_cell = neighbor
			actions.append(action)

	return actions


func generate_skill_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions

	var move_cells := get_reachable_cells_list_for_unit(unit_id)
	for skill in unit.iter_skills():
		if typeof(skill) != TYPE_DICTIONARY:
			continue
		if not unit.can_use_skill(skill):
			continue
		var target_type := int(skill.get("target", Enums.SKILL_TARGET.NONE))
		match target_type:
			Enums.SKILL_TARGET.ENEMY:
				actions.append_array(_generate_targeted_unit_actions_for_cells(unit_id, move_cells, target_type, Action.ACTION_TYPE.SKILL_HOSTILE, "skill", skill))
			Enums.SKILL_TARGET.SELF, Enums.SKILL_TARGET.ALLY, Enums.SKILL_TARGET.SELF_ALLY:
				actions.append_array(_generate_targeted_unit_actions_for_cells(unit_id, move_cells, target_type, Action.ACTION_TYPE.SKILL_FRIENDLY, "skill", skill))
			Enums.SKILL_TARGET.MAP:
				actions.append_array(_generate_targeted_map_actions_for_cells(unit_id, move_cells, _get_skill_reach_for_sim(unit, skill), Action.ACTION_TYPE.SKILL_FRIENDLY, "skill", skill))
	return actions


func generate_item_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	var unit := get_unit_by_id(unit_id)
	if unit == null or not unit.can_act():
		return actions

	var move_cells := get_reachable_cells_list_for_unit(unit_id)
	for item in unit.iter_inventory():
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if not _is_supported_ai_item(item):
			continue
		if not unit.has_enough_comp(int(item.get("cost", 0))):
			continue
		var target_type := _get_item_target_type(item)
		match target_type:
			Enums.SKILL_TARGET.ENEMY:
				actions.append_array(_generate_targeted_unit_actions_for_cells(unit_id, move_cells, target_type, Action.ACTION_TYPE.USE_ITEM, "item", item))
			Enums.SKILL_TARGET.SELF, Enums.SKILL_TARGET.ALLY, Enums.SKILL_TARGET.SELF_ALLY:
				actions.append_array(_generate_targeted_unit_actions_for_cells(unit_id, move_cells, target_type, Action.ACTION_TYPE.USE_ITEM, "item", item))
			Enums.SKILL_TARGET.MAP:
				actions.append_array(_generate_targeted_map_actions_for_cells(unit_id, move_cells, _get_item_reach(item), Action.ACTION_TYPE.USE_ITEM, "item", item))
	return actions


func generate_task_actions_for_unit(unit_id: String) -> Array[Action]:
	var unit := get_unit_by_id(unit_id)
	if unit == null:
		return []

	match unit.ai_task:
		Unit.AI_TASK.LOOT:
			return generate_chest_actions_for_unit(unit_id)
		Unit.AI_TASK.BREACH:
			var actions := generate_door_actions_for_unit(unit_id)
			actions.append_array(generate_wall_actions_for_unit(unit_id))
			return actions
		Unit.AI_TASK.HOLD:
			return generate_hold_actions_for_unit(unit_id)
		_:
			return []


# Preferred actions narrow the candidate set when a task has a strong map role
# like LOOT, BREACH, or HOLD. Otherwise the evaluator sees the full legal set.
func generate_legal_actions_for_unit(unit_id: String) -> Array[Action]:
	var actions: Array[Action] = []
	actions.append_array(generate_move_actions_for_unit(unit_id, true))
	actions.append_array(generate_attack_actions_for_unit(unit_id))
	actions.append_array(generate_skill_actions_for_unit(unit_id))
	actions.append_array(generate_item_actions_for_unit(unit_id))
	actions.append_array(generate_door_actions_for_unit(unit_id))
	actions.append_array(generate_chest_actions_for_unit(unit_id))
	actions.append_array(generate_wall_actions_for_unit(unit_id))
	return actions


func generate_preferred_actions_for_unit(unit_id: String) -> Array[Action]:
	var task_actions := generate_task_actions_for_unit(unit_id)
	if not task_actions.is_empty():
		return task_actions
	return generate_legal_actions_for_unit(unit_id)

## Adds unit to state
func _add_unit(sim: UnitSim):
	if sim == null:
		return
	units[sim.cell] = sim
	units_by_id[sim.id] = sim
	refresh_unit_position_context(sim)

# These mutators are intentionally shallow for now. They update board position
# and acted state so evaluation can reason about outcomes before full sim
# resolution exists for every action category.
func _apply_move(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if not can_unit_end_on_cell(unit.id, action.target_cell):
		return
	set_unit_cell(unit.id, action.target_cell)


func _apply_attack(action:Action):
	var attacker := get_unit_by_id(action.unit_id)
	var defender := get_unit_by_id(action.target_unit_id)
	if attacker == null or defender == null:
		return
	attacker.moved_hexes = int(action.moved_hexes)
	if action.from_cell != Vector2i.ZERO and attacker.cell != action.from_cell:
		if can_unit_end_on_cell(attacker.id, action.from_cell):
			set_unit_cell(attacker.id, action.from_cell)
	attacker.status["Acted"] = true



func _apply_skill_hostile(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if action.from_cell != Vector2i.ZERO and unit.cell != action.from_cell:
		if can_unit_end_on_cell(unit.id, action.from_cell):
			set_unit_cell(unit.id, action.from_cell)
	unit.status["Acted"] = true

func _apply_skill_friendly(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if action.from_cell != Vector2i.ZERO and unit.cell != action.from_cell:
		if can_unit_end_on_cell(unit.id, action.from_cell):
			set_unit_cell(unit.id, action.from_cell)
	unit.status["Acted"] = true

func _apply_wait(action:Action):
	var unit:= get_unit_by_id(action.unit_id)
	if unit == null:
		return
	unit.status["Acted"] = true
func _apply_trade(action:Action): pass
func _apply_use_item(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if action.from_cell != Vector2i.ZERO and unit.cell != action.from_cell:
		if can_unit_end_on_cell(unit.id, action.from_cell):
			set_unit_cell(unit.id, action.from_cell)
	unit.status["Acted"] = true
func _apply_canto(action:Action):
	_apply_move(action)
	var unit := get_unit_by_id(action.unit_id)
	if unit != null:
		unit.status["Acted"] = true
func _apply_door(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if action.from_cell != Vector2i.ZERO and unit.cell != action.from_cell:
		if can_unit_end_on_cell(unit.id, action.from_cell):
			set_unit_cell(unit.id, action.from_cell)
	unit.status["Acted"] = true
func _apply_chest(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if action.from_cell != Vector2i.ZERO and unit.cell != action.from_cell:
		if can_unit_end_on_cell(unit.id, action.from_cell):
			set_unit_cell(unit.id, action.from_cell)
	unit.status["Acted"] = true
func _apply_wall(action:Action):
	var unit := get_unit_by_id(action.unit_id)
	if unit == null:
		return
	if action.from_cell != Vector2i.ZERO and unit.cell != action.from_cell:
		if can_unit_end_on_cell(unit.id, action.from_cell):
			set_unit_cell(unit.id, action.from_cell)
	unit.status["Acted"] = true
func _apply_time_warp(action:Action): pass
