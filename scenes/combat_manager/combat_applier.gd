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
	if comp_actor != 0:
		_apply_composure_delta(actor, -abs(comp_actor))
	if comp_target != 0:
		_apply_composure_delta(target, -abs(comp_target))

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

		"durability":
			# Pass A: owner_id means “reduce currently equipped weapon durability”
			var owner_id := String(event.get("owner_id", ""))
			var delta := int(event.get("amount", 0)) # typically -1
			if delta == 0:
				return
			var owner: Unit = _get_unit(unit_map, owner_id)
			if owner == null:
				return

			# We only support negative deltas for now
			if delta < 0:
				_reduce_actor_weapon_durability(owner, -delta)
			else:
				# Optional: support repairing in future
				_reduce_actor_weapon_durability(owner, -delta) # no-op if negative required

		_:
			# Unknown event type: ignore for now
			pass

# -------------------------
# Durability
# -------------------------

func _reduce_actor_weapon_durability(actor: Unit, cost: int) -> void:
	# PASS A: this is intentionally conservative—only reduces if we can confidently find an equipped item.
	# You track durability on Item.dur. :contentReference[oaicite:8]{index=8}
	if actor == null or cost <= 0:
		return

	var item :Weapon= _get_equipped_item(actor)
	if item == null:
		return

	if item is Item:
		# setter clamps & emits durability_reduced(item) :contentReference[oaicite:9]{index=9}
		item.dur = item.dur - cost

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

func _apply_composure_delta(unit: Unit, delta: int) -> void:
	if unit == null or delta == 0:
		return
	if unit.has_method("apply_composure"):
		unit.apply_composure(delta)
		return
	if unit.get("composure"):
		unit.composure = max(0, int(unit.composure) + delta)

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
