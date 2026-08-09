# BuffController.gd
# Handles all temporary buff/debuff logic, duration ticking, stat aggregation and effect stacking
class_name BuffController
extends RefCounted

var unit : Unit

# Structure:
# active_buffs  = { "id_0": {"effect": Effect, "duration": int}, ... }
# active_debuffs = { "id_0": { ... }, ... }
var active_buffs : Dictionary = {}
var active_debuffs : Dictionary = {}

func _init(u: Unit) -> void:
	unit = u

# APPLYING / REMOVING BUFFS
func apply_effect(effect: Effect,source:Enums.EFFECT_SOURCE=Enums.EFFECT_SOURCE.BUFF,context=null) -> void:
	if effect == null:
		printerr("[BuffController] Tried to apply null effect")
		return

	if effect.duration_type == Enums.DURATION_TYPE.PERMANENT:
		_apply_permanent_stat_mod(effect)
		return
		
	if effect.stack:
		_add_stack(effect, source, context)
	else:
		_apply_or_refresh(effect, source)


func remove_effect(effect: Effect, context = null) -> void:
	if effect.stack:
		_remove_stack(effect, context)
	else:
		_remove_nonstack(effect)


func clear_all() -> void:
	active_buffs.clear()
	active_debuffs.clear()
	unit.update_stats()

# Effect Application
func _add_stack(effect: Effect, source, context) -> void:
	var pool = _get_pool(effect)

	var stack_key := ""
	if context != null:
		stack_key = str(context.get_instance_id())
	else:
		stack_key = "generic"

	var id := "%s_%s" % [effect.id, stack_key]

	if pool.has(id):
		return # already stacked

	pool[id] = {
		"effect": effect,
		"duration": effect.duration,
		"source": source
	}

	unit.update_stats()

func _apply_or_refresh(effect: Effect, source:= Enums.EFFECT_SOURCE.AURA) -> void:
	var pool = _get_pool(effect)

	for id in pool.keys():
		var entry = pool[id]
		if entry.effect.id == effect.id and entry.source == source:
			entry.duration = effect.duration
			unit.update_stats()
			return

	pool[effect.id] = {
		"effect": effect,
		"duration": effect.duration,
		"source": source
	}
	unit.update_stats()

func _remove_stack(effect: Effect, context) -> void:
	if context == null:
		return

	var stack_key := str(context.get_instance_id())
	var id := "%s_%s" % [effect.id, stack_key]

	if active_buffs.erase(id) or active_debuffs.erase(id):
		unit.update_stats()

func _remove_nonstack(effect: Effect) -> void:
	for pool in [active_buffs, active_debuffs]:
		for id in pool.keys():
			if pool[id].effect.id == effect.id:
				pool.erase(id)
				unit.update_stats()
				return


# DURATION TICK
func tick(duration_type: Enums.DURATION_TYPE) -> void:
	_tick_group(active_buffs, duration_type)
	_tick_group(active_debuffs, duration_type)
	unit.update_stats()


func _tick_group(pool: Dictionary, d_type:Enums.DURATION_TYPE) -> void:
	var to_remove := []

	for id in pool.keys():
		var entry = pool[id]

		if entry.effect.duration_type != d_type:
			continue

		_apply_periodic_effect(entry.effect)
		entry.duration -= 1

		if entry.duration <= 0:
			to_remove.append(id)

	for id in to_remove:
		pool.erase(id)


# AGGREGATION FOR StatsBlock
func get_modifiers() -> Dictionary:
	var mods := {}
	var subKeys = Enums.SUB_TYPE.keys()

	for pool in [active_buffs, active_debuffs]:
		for id in pool.keys():
			var entry = pool[id]
			if int(entry.get("source", Enums.EFFECT_SOURCE.NONE)) == Enums.EFFECT_SOURCE.ITEM:
				continue
			var effect = entry.effect
			if effect == null:
				continue
			if effect is CompBreak:
				_apply_comp_break_modifiers(mods, effect)
				continue
			if effect.type != Enums.EFFECT_TYPE.BUFF and effect.type != Enums.EFFECT_TYPE.DEBUFF:
				continue
			if typeof(effect.sub_type) != TYPE_INT:
				continue
			if effect.sub_type < 0 or effect.sub_type >= subKeys.size():
				continue
			var stat_name = subKeys[effect.sub_type].to_pascal_case()
			mods[stat_name] = mods.get(stat_name, 0) + effect.value
	return mods


func has_effect_id(effect_id: String) -> bool:
	for pool in [active_buffs, active_debuffs]:
		for entry in pool.values():
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var effect: Effect = entry.get("effect", null)
			if effect != null and effect.id == effect_id:
				return true
	return false


func get_tray_entries() -> Array[Dictionary]:
	var grouped: Dictionary = {}
	_add_tray_entries_from_pool(grouped, active_buffs, true)
	_add_tray_entries_from_pool(grouped, active_debuffs, false)
	var entries: Array[Dictionary] = []
	for key in grouped.keys():
		var group: Dictionary = grouped[key]
		entries.append({
			"id": String(key),
			"tooltip_id": "effects:%s" % String(key),
			"icon": String(group.get("icon", "buff")),
			"kind": String(group.get("kind", "buff")),
			"effect_keys": group.get("effect_keys", []),
		})
	return entries


func get_tray_effect_entry(effect_key: String) -> Dictionary:
	if active_buffs.has(effect_key):
		var buff_entry = active_buffs[effect_key]
		if typeof(buff_entry) == TYPE_DICTIONARY:
			return buff_entry
	if active_debuffs.has(effect_key):
		var debuff_entry = active_debuffs[effect_key]
		if typeof(debuff_entry) == TYPE_DICTIONARY:
			return debuff_entry
	return {}


func get_tray_effect_entries(icon_key: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	_collect_tray_effect_entries(entries, active_buffs, icon_key, true)
	_collect_tray_effect_entries(entries, active_debuffs, icon_key, false)
	return entries


func remove_effect_by_id(effect_id: String) -> bool:
	for pool in [active_buffs, active_debuffs]:
		for key in pool.keys():
			var entry = pool[key]
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var effect: Effect = entry.get("effect", null)
			if effect == null or effect.id != effect_id:
				continue
			pool.erase(key)
			unit.update_stats()
			return true
	return false


func purge_curable_buffs(sub_type: Enums.SUB_TYPE = Enums.SUB_TYPE.ALL, ignore_curable := false) -> int:
	return _remove_from_pool(active_buffs, sub_type, ignore_curable)


func cure_curable_debuffs(sub_type: Enums.SUB_TYPE = Enums.SUB_TYPE.ALL, ignore_curable := false) -> int:
	return _remove_from_pool(active_debuffs, sub_type, ignore_curable)


func _remove_from_pool(pool: Dictionary, sub_type: Enums.SUB_TYPE, ignore_curable := false) -> int:
	var to_remove := []
	for key in pool.keys():
		var entry = pool[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var effect: Effect = entry.get("effect", null)
		if effect == null:
			continue
		if not ignore_curable and not bool(effect.curable):
			continue
		if sub_type != Enums.SUB_TYPE.ALL and int(effect.sub_type) != int(sub_type):
			continue
		to_remove.append(key)

	for key in to_remove:
		pool.erase(key)

	if not to_remove.is_empty():
		unit.update_stats()
	return to_remove.size()


# PERMANENT STAT MODIFIERS
func _apply_permanent_stat_mod(effect: Effect) -> void:
	var statKeys = Enums.CORE_STAT.keys()
	var stat = effect.sub_type

	# Convert int -> stat name
	if typeof(stat) == TYPE_INT:
		stat = statKeys[stat]

	if typeof(stat) != TYPE_STRING:
		printerr("[BuffController] Invalid permanent stat mod type: ", stat)
		return

	# Apply to unit's mod_stats
	unit.mod_stats[stat] += effect.value
	unit.update_stats()


func _apply_comp_break_modifiers(mods: Dictionary, effect: CompBreak) -> void:
	mods["Hit"] = mods.get("Hit", 0) + int(effect.hit_penalty)
	mods["Graze"] = mods.get("Graze", 0) + int(effect.graze_penalty)
	mods["Crit"] = mods.get("Crit", 0) + int(effect.crit_penalty)


func _add_tray_entries_from_pool(grouped: Dictionary, pool: Dictionary, positive: bool) -> void:
	for key in pool.keys():
		var entry = pool[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if int(entry.get("source", Enums.EFFECT_SOURCE.NONE)) == Enums.EFFECT_SOURCE.ITEM:
			continue
		var effect: Effect = entry.get("effect", null)
		if effect == null:
			continue
		var icon := _get_tray_icon(effect, positive)
		if not grouped.has(icon):
			grouped[icon] = {
				"icon": icon,
				"kind": "buff" if positive else "debuff",
				"effect_keys": [],
			}
		grouped[icon].effect_keys.append(String(key))


func _collect_tray_effect_entries(entries: Array[Dictionary], pool: Dictionary, icon_key: String, positive: bool) -> void:
	for key in pool.keys():
		var entry:Dictionary= pool[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if int(entry.get("source", Enums.EFFECT_SOURCE.NONE)) == Enums.EFFECT_SOURCE.ITEM:
			continue
		var effect: Effect = entry.get("effect", null)
		if effect == null:
			continue
		if _get_tray_icon(effect, positive) != icon_key:
			continue
		var copy := entry.duplicate(true)
		copy["key"] = String(key)
		copy["kind"] = "buff" if positive else "debuff"
		entries.append(copy)


func _get_tray_icon(effect: Effect, positive: bool) -> String:
	match int(effect.type):
		Enums.EFFECT_TYPE.BUFF, Enums.EFFECT_TYPE.HOT, Enums.EFFECT_TYPE.STATUS_BUFFER:
			return "buff"
		Enums.EFFECT_TYPE.DEBUFF, Enums.EFFECT_TYPE.DOT:
			return "debuff"
	return "buff" if positive else "debuff"


# INTERNAL HELPERS
func _get_pool(effect: Effect) -> Dictionary:
	if (
		effect.type == Enums.EFFECT_TYPE.BUFF
		or effect.type == Enums.EFFECT_TYPE.HOT
		or effect.type == Enums.EFFECT_TYPE.STATUS_BUFFER
	):
		return active_buffs
	return active_debuffs


func consume_status_buffer(status_sub_type: Enums.SUB_TYPE) -> bool:
	for key in active_buffs.keys():
		var entry = active_buffs[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var effect: Effect = entry.get("effect", null)
		if effect == null or effect.type != Enums.EFFECT_TYPE.STATUS_BUFFER:
			continue
		if effect.sub_type != Enums.SUB_TYPE.ALL and int(effect.sub_type) != int(status_sub_type):
			continue
		active_buffs.erase(key)
		unit.update_stats()
		return true
	return false


func _apply_periodic_effect(effect: Effect) -> void:
	if effect == null:
		return
	var amount := _resolve_periodic_amount(effect)
	if amount <= 0:
		return
	match int(effect.type):
		Enums.EFFECT_TYPE.DOT:
			unit.apply_dmg(amount)
		Enums.EFFECT_TYPE.HOT:
			unit.apply_heal(amount)


func _resolve_periodic_amount(effect: Effect) -> int:
	if typeof(effect.value) == TYPE_FLOAT:
		var max_life := int(unit.active_stats.get("Life", unit.total_stats.get("Life", unit.current_life)))
		return max(0, int(round(float(max_life) * float(effect.value))))
	return max(0, int(effect.value))


func _generate_unique_id(pool: Dictionary, base_name: String) -> String:
	var i := 0
	var new_name := base_name + str(i)
	while pool.has(new_name):
		i += 1
		new_name = base_name + str(i)
	return new_name
