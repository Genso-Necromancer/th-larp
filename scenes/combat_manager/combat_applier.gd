extends CombatServiceBase
class_name CombatApplier

# Optional: keep if other systems listen for it
signal warp_selected(actor: Unit, target: Unit, reach)

func apply_results(results: CombatResults, unit_map: Dictionary = {}) -> void:
	if results == null:
		push_warning("CombatApplier.apply_results: results is null")
		return

	# Resolve id->Unit mapping
	if unit_map.is_empty():
		unit_map = _build_unit_map_from_gameboard(results)

	# Validate required units
	var attacker_id := String(results.units.get("attacker_id", ""))
	var defender_id := String(results.units.get("defender_id", ""))
	if _get_unit(unit_map, attacker_id) == null or _get_unit(unit_map, defender_id) == null:
		push_error("CombatApplier.apply_results: missing attacker/defender in unit_map")
		return

	# Apply strictly in order
	for r in results.rounds:
		for a in r.get("actions", []):
			_apply_action(results, a, unit_map)

func _apply_action(results: CombatResults, action: Dictionary, unit_map: Dictionary) -> void:
	var actor: Unit = _get_unit(unit_map, String(action.get("actor_id", "")))
	var target: Unit = _get_unit(unit_map, String(action.get("target_id", "")))
	if actor == null or target == null:
		return

	if _is_dead(actor) or _is_dead(target):
		return

	for swing in action.get("swings", []):
		_apply_swing(results, actor, target, swing, unit_map)
		if _is_dead(target) or bool(swing.get("target_dead", false)):
			break

func _apply_swing(results: CombatResults, actor: Unit, target: Unit, swing: Dictionary, unit_map: Dictionary) -> void:
	# Composure deltas if present
	var comp_actor := int(swing.get("comp_actor", 0))
	var comp_target := int(swing.get("comp_target", 0))
	var comp_actor_reasons: Array = swing.get("comp_actor_reasons", [])
	var comp_target_reasons: Array = swing.get("comp_target_reasons", [])
	if comp_actor != 0:
		_apply_composure_delta(actor, comp_actor, _join_composure_reasons(comp_actor_reasons))
	if comp_target != 0:
		_apply_composure_delta(target, comp_target, _join_composure_reasons(comp_target_reasons))

	# Apply events in phase order.
	# New format: events_pre then events_post
	var pre_events: Array = swing.get("events_pre", [])
	var post_events: Array = swing.get("events_post", [])

	if pre_events.size() > 0 or post_events.size() > 0:
		for ev in pre_events:
			_apply_event(results, ev, unit_map)
		for ev in post_events:
			_apply_event(results, ev, unit_map)
		return

	# Back-compat: older results only used "events"
	for ev in swing.get("events", []):
		_apply_event(results, ev, unit_map)


# Damage / Heal / Event
func _apply_damage(target: Unit, amount: int, source: Unit = null) -> void:
	if target == null or amount <= 0:
		return

	# Your Unit.apply_dmg(int) exists and “strictly handles reducing HP”. (Good.) :contentReference[oaicite:6]{index=6}
	if target.has_method("apply_dmg"):
		target.apply_dmg(amount, source)

		# StatusController expects on_damage_taken hook from apply_dmg; but we can also ensure it:
		var sc :StatusController= _get_status_controller(target)
		if sc:
			sc.on_damage_taken(amount) # wakes Sleep, etc. :contentReference[oaicite:7]{index=7}
		return

	# Fallback if needed
	if target.get("current_life"):
		target.current_life = max(0, int(target.current_life) - amount)
		return

func _apply_heal(target: Unit, amount: int, source: Unit = null) -> void:
	if target == null or amount <= 0:
		return

	if target.has_method("apply_heal"):
		target.apply_heal(amount)
		return
	if target.has_method("heal"):
		target.heal(amount)
		return

	if target.get("current_life") and target.get("max_life"):
		target.current_life = min(int(target.max_life), int(target.current_life) + amount)

func _apply_event(results: CombatResults, event: Dictionary, unit_map: Dictionary) -> void:
	# Only apply in LIVE mode
	if results.mode != CombatResults.MODE.LIVE:
		return
	if event == null or event.is_empty():
		return

	var t := String(event.get("type", ""))

	match t:
		"damage":
			var target_id := String(event.get("target_id", ""))
			var actor_id := String(event.get("actor_id", ""))
			var amount := int(event.get("amount", 0))
			if amount <= 0:
				return
			var target: Unit = _get_unit(unit_map, target_id)
			var actor: Unit = _get_unit(unit_map, actor_id)
			if target:
				_apply_damage(target, amount, actor)

		"heal":
			var target_id := String(event.get("target_id", ""))
			var actor_id := String(event.get("actor_id", ""))
			var amount := int(event.get("amount", 0))
			if amount <= 0:
				return
			var target: Unit = _get_unit(unit_map, target_id)
			var actor: Unit = _get_unit(unit_map, actor_id)
			if target:
				_apply_heal(target, amount, actor)

		"comp_dmg":
			var target_id := String(event.get("target_id", ""))
			var amount := int(event.get("amount", 0))
			if amount <= 0:
				return
			var target: Unit = _get_unit(unit_map, target_id)
			if target:
				_apply_composure_delta(target, abs(amount))

		"comp_heal":
			var target_id := String(event.get("target_id", ""))
			var amount := int(event.get("amount", 0))
			if amount <= 0:
				return
			var target: Unit = _get_unit(unit_map, target_id)
			if target:
				_apply_composure_delta(target, -abs(amount))

		"buff":
			var target_id := String(event.get("target_id", ""))
			var effect = event.get("effect", null)
			if effect == null:
				return

			var target: Unit = _get_unit(unit_map, target_id)
			if target == null:
				return

			var context_id := String(event.get("context_id", ""))
			var context_unit: Unit = _get_unit(unit_map, context_id)

			var bc: BuffController = _get_buff_controller(target)
			if bc:
				# source is BUFF; context is the Unit who caused it (for stacking rules)
				bc.apply_effect(effect, Enums.EFFECT_SOURCE.BUFF, context_unit)
			else:
				push_warning("CombatApplier: missing BuffController on %s" % [target.name])

		"status":
			var target_id := String(event.get("target_id", ""))
			var effect = event.get("effect", null)
			if effect == null:
				return

			var target: Unit = _get_unit(unit_map, target_id)
			if target == null:
				return

			var sc: StatusController = _get_status_controller(target)
			if sc:
				sc.apply_from_effect(effect)
			else:
				push_warning("CombatApplier: missing StatusController on %s" % [target.name])

		"cure":
			var target_id := String(event.get("target_id", ""))
			var effect = event.get("effect", null)
			if effect == null:
				return

			var target: Unit = _get_unit(unit_map, target_id)
			if target == null:
				return

			var sub_type := int(effect.sub_type) if typeof(effect.sub_type) == TYPE_INT else int(Enums.SUB_TYPE.ALL)
			var sc: StatusController = _get_status_controller(target)
			if sc:
				sc.cure_status(sub_type, false)
			var bc: BuffController = _get_buff_controller(target)
			if bc:
				bc.cure_curable_debuffs(sub_type, false)

		"purge":
			var target_id := String(event.get("target_id", ""))
			var effect = event.get("effect", null)
			if effect == null:
				return

			var target: Unit = _get_unit(unit_map, target_id)
			if target == null:
				return

			var sub_type := int(effect.sub_type) if typeof(effect.sub_type) == TYPE_INT else int(Enums.SUB_TYPE.ALL)
			var bc: BuffController = _get_buff_controller(target)
			if bc:
				bc.purge_curable_buffs(sub_type, false)

		"purity":
			var target_id := String(event.get("target_id", ""))
			var effect = event.get("effect", null)
			if effect == null:
				return

			var target: Unit = _get_unit(unit_map, target_id)
			if target == null:
				return

			var sub_type := int(effect.sub_type) if typeof(effect.sub_type) == TYPE_INT else int(Enums.SUB_TYPE.ALL)
			var bc: BuffController = _get_buff_controller(target)
			if bc:
				bc.cure_curable_debuffs(sub_type, false)

		"reloc":
			var actor_id := String(event.get("source_id", ""))
			var target_id := String(event.get("target_id", ""))
			var effect = event.get("effect", null)
			if effect == null:
				return
			var actor: Unit = _get_unit(unit_map, actor_id)
			var target: Unit = _get_unit(unit_map, target_id)
			var destination = event.get("destination", null)
			_apply_relocation(actor, target, effect, destination)

		"durability":
			# owner_id means reduce durability from the action source.
			var owner_id := String(event.get("owner_id", ""))
			var delta := int(event.get("amount", 0)) # typically -1
			if delta == 0:
				return
			var owner: Unit = _get_unit(unit_map, owner_id)
			if owner == null:
				return

			var item = event.get("item", null)
			# We only support negative deltas for now
			if delta < 0:
				if item is Item:
					_reduce_item_durability(owner, item, -delta)
				else:
					_reduce_actor_weapon_durability(owner, -delta)
			else:
				# Optional: support repairing in future
				_reduce_actor_weapon_durability(owner, -delta) # no-op if negative required

		_:
			# Unknown event type: ignore for now
			pass

# -------------------------
# Relocation
# -------------------------

func apply_relocation(actor: Unit, target: Unit, effect: Effect) -> void:
	_apply_relocation(actor, target, effect)


func _apply_relocation(actor: Unit, target: Unit, effect: Effect, destination = null) -> void:
	if actor == null or target == null or effect == null or gameBoard == null:
		return
	var sub_type := int(effect.sub_type) if typeof(effect.sub_type) == TYPE_INT else Enums.SUB_TYPE.NONE
	match sub_type:
		Enums.SUB_TYPE.SHOVE:
			_apply_shove(actor, target, effect)
		Enums.SUB_TYPE.TOSS:
			_apply_toss(actor, target, effect)
		Enums.SUB_TYPE.WARP:
			_apply_warp(actor, target, effect, destination)
		Enums.SUB_TYPE.RESCUE:
			_apply_rescue(actor, target, effect)


func _apply_shove(actor: Unit, target: Unit, effect: Effect) -> void:
	var distance := maxi(1, int(effect.value))
	var hex := AHexGrid2D.new(gameBoard.current_map)
	var result: Dictionary = hex.resolve_shove(actor.cell, target.cell, hex.get_BFS_nhbr(target.cell, true), distance)
	var destination :Vector2i= result.get("Hex", target.cell)
	if destination == target.cell:
		return
	target.shove_unit(destination)


func _apply_toss(actor: Unit, target: Unit, effect: Effect) -> void:
	var distance := maxi(1, int(effect.value))
	var hex := AHexGrid2D.new(gameBoard.current_map)
	var result: Dictionary = hex.resolve_shove(target.cell, actor.cell, hex.get_BFS_nhbr(actor.cell, true), distance)
	var destination :Vector2i= result.get("Hex", target.cell)
	if destination == target.cell:
		return
	target.toss_unit(destination)


func _apply_warp(actor: Unit, target: Unit, effect: Effect, destination = null) -> void:
	if destination is Vector2i:
		if destination == target.cell:
			return
		target.relocate_unit(destination)
		return
	var radius := maxi(1, int(effect.value))
	var fallback_destination := _find_warp_destination(actor, target, radius)
	if fallback_destination == target.cell:
		return
	target.relocate_unit(fallback_destination)


func _apply_rescue(actor: Unit, target: Unit, _effect: Effect) -> void:
	if actor == null or target == null or gameBoard == null or gameBoard.current_map == null:
		return
	var destination := _find_rescue_destination(actor, target)
	if destination == target.cell:
		return
	target.relocate_unit(destination)


func _find_warp_destination(actor: Unit, target: Unit, radius: int) -> Vector2i:
	if actor == null or target == null or gameBoard == null or gameBoard.current_map == null:
		return target.cell
	var hex := AHexGrid2D.new(gameBoard.current_map)
	var cells: Array = hex.find_aura(actor.cell, radius)
	var best := target.cell
	var best_distance := -1
	for cell in cells:
		if cell == actor.cell or cell == target.cell:
			continue
		if gameBoard.units.has(cell):
			continue
		var distance: int = hex.axial_distance(hex.oddq_to_axial(actor.cell), hex.oddq_to_axial(cell))
		if distance > best_distance:
			best = cell
			best_distance = distance
	return best


func _find_rescue_destination(actor: Unit, target: Unit) -> Vector2i:
	if actor == null or target == null or gameBoard == null or gameBoard.current_map == null:
		return target.cell
	var hex := AHexGrid2D.new(gameBoard.current_map)
	hex._sort_solids()
	var max_radius := maxi(1, int(Global.RESCUE_SEARCH_MAX_RADIUS))
	for radius in range(1, max_radius + 1):
		var ring := _get_rescue_ring_clockwise(hex, actor.cell, target.cell, radius)
		for cell in ring:
			if _is_valid_rescue_destination(hex, cell):
				return cell
	return target.cell


func _get_rescue_ring_clockwise(hex: AHexGrid2D, center: Vector2i, target_cell: Vector2i, radius: int) -> Array[Vector2i]:
	var ring := _get_hex_ring_clockwise(hex, center, radius)
	if ring.is_empty():
		return ring
	var target_axial := hex.oddq_to_axial(target_cell)
	var best_index := 0
	var best_distance := 100000
	for i in range(ring.size()):
		var distance := hex.axial_distance(target_axial, hex.oddq_to_axial(ring[i]))
		if distance < best_distance:
			best_distance = distance
			best_index = i
	var rotated: Array[Vector2i] = []
	for offset in range(ring.size()):
		rotated.append(ring[(best_index + offset) % ring.size()])
	return rotated


func _get_hex_ring_clockwise(hex: AHexGrid2D, center: Vector2i, radius: int) -> Array[Vector2i]:
	var axial_dirs: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	]
	var axial := hex.oddq_to_axial(center) + axial_dirs[4] * radius
	var ring: Array[Vector2i] = []
	for side in range(6):
		for _step in range(radius):
			ring.append(hex.axial_to_oddq(axial))
			axial += axial_dirs[side]
	return ring


func _is_valid_rescue_destination(hex: AHexGrid2D, cell: Vector2i) -> bool:
	if not hex.is_valid_position(cell):
		return false
	if hex._is_solid_check(cell):
		return false
	if gameBoard.units.has(cell):
		return false
	return true

# -------------------------
# Durability
# -------------------------

func _reduce_actor_weapon_durability(actor: Unit, cost: int) -> void:
	if actor == null or cost <= 0:
		return

	var item :Weapon= _get_equipped_item(actor)
	if item == null:
		return

	cost += _get_extra_weapon_durability_cost(actor, item)
	_reduce_item_durability(actor, item, cost)


func _reduce_item_durability(actor: Unit, item: Item, cost: int) -> void:
	if actor == null or item == null or cost <= 0:
		return
	if not item.breakable:
		return
	if actor.has_method("reduce_durability"):
		actor.reduce_durability(item, cost)
	else:
		item.dur = item.dur - cost


func _get_extra_weapon_durability_cost(actor: Unit, weapon: Weapon) -> int:
	if actor == null or weapon == null:
		return 0
	if weapon.category != Enums.WEAPON_CATEGORY.BOW:
		return 0

	var extra := 0
	for acc: Accessory in actor.get_equipped_accs():
		if acc is not Quiver:
			continue
		for effect: Effect in acc.effects:
			if effect.type == Enums.EFFECT_TYPE.DURABILITY_COST:
				extra += max(0, int(effect.value))
	return extra

func _get_equipped_item(actor: Unit):
	# Adapt this to your actual inventory/equipment layout.
	# Common patterns:
	# - actor.get_equipped_weapon()
	# - actor.equipped_weapon
	# - actor.inventory[slot] where slot has equipped flag
	if actor.has_method("get_equipped_weapon"):
		return actor.get_equipped_weapon()

	if actor.get("equipped_weapon"):
		return actor.equipped_weapon

	return null

# -------------------------
# Controllers
# -------------------------

func _get_buff_controller(unit: Unit):
	# BuffController is RefCounted and initialized with Unit. :contentReference[oaicite:10]{index=10}
	if unit == null:
		return null
	if unit.get("buff_controller") and unit.buff_controller != null:
		return unit.buff_controller
	if unit.has_method("get_buff_controller"):
		return unit.get_buff_controller()
	return null

func _get_status_controller(unit: Unit):
	# StatusController is RefCounted and initialized with Unit. :contentReference[oaicite:11]{index=11}
	if unit == null:
		return null
	if unit.get("status_controller") and unit.status_controller != null:
		return unit.status_controller
	if unit.has_method("get_status_controller"):
		return unit.get_status_controller()
	return null

# -------------------------
# Composure + misc
# -------------------------

func _apply_composure_delta(unit: Unit, delta: int, reason := "") -> void:
	if unit == null or delta == 0:
		return
	if unit.has_method("spend_composure") and unit.has_method("restore_composure"):
		if delta > 0:
			unit.spend_composure(delta, reason)
		else:
			unit.restore_composure(abs(delta), reason)
		return
	if unit.has_method("apply_composure"):
		unit.apply_composure(delta)
		return
	if unit.get("composure"):
		unit.composure = max(0, int(unit.composure) + delta)


func _join_composure_reasons(reasons: Array) -> String:
	var parts: Array[String] = []
	for entry in reasons:
		if typeof(entry) == TYPE_STRING:
			parts.append(String(entry))
	return ", ".join(parts)

func _is_dead(unit: Unit) -> bool:
	if unit == null:
		return true
	if unit.has_method("is_dead"):
		return bool(unit.is_dead())
	if unit.get("current_life"):
		return int(unit.current_life) <= 0
	return false

# -------------------------
# Unit resolution
# -------------------------

func _get_unit(unit_map: Dictionary, id: String) -> Unit:
	if id == "" or not unit_map.has(id):
		return null
	var u = unit_map[id]
	return u if u is Unit else null

func _build_unit_map_from_gameboard(results: CombatResults) -> Dictionary:
	var map := {}
	if gameBoard and gameBoard.has_method("get_unit_by_id"):
		var a_id := String(results.units.get("attacker_id", ""))
		var d_id := String(results.units.get("defender_id", ""))
		var a = gameBoard.get_unit_by_id(a_id)
		var d = gameBoard.get_unit_by_id(d_id)
		if a: map[a_id] = a
		if d: map[d_id] = d
	return map
