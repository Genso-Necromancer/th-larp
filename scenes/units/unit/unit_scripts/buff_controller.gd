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
func apply_effect(effect: Effect,source:Enums.EFFECT_SOURCE=Enums.EFFECT_SOURCE.BUFF) -> void:
	if effect == null:
		printerr("[BuffController] Tried to apply null effect")
		return

	if effect.duration_type == Enums.DURATION_TYPE.PERMANENT:
		_apply_permanent_stat_mod(effect)
		return

	var pool = _get_pool(effect)

	var effect_id = effect.id
	if effect.stack:
		effect_id = _generate_unique_id(pool, effect.id)

	pool[effect_id] = {
		"effect": effect,
		"duration": effect.duration,
		"source": source
	}

	unit.update_stats()


func remove_effect(effect_id: String) -> void:
	if active_buffs.has(effect_id):
		active_buffs.erase(effect_id)

	if active_debuffs.has(effect_id):
		active_debuffs.erase(effect_id)

	unit.update_stats()


func clear_all() -> void:
	active_buffs.clear()
	active_debuffs.clear()
	unit.update_stats()



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
			var effect = pool[id].effect
			var stat_name = subKeys[effect.sub_type].to_pascal_case()
			mods[stat_name] = mods.get(stat_name, 0) + effect.value
	return mods



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


# INTERNAL HELPERS
func _get_pool(effect: Effect) -> Dictionary:
	if effect.type == Enums.EFFECT_TYPE.BUFF:
		return active_buffs
	return active_debuffs


func _generate_unique_id(pool: Dictionary, base_name: String) -> String:
	var i := 0
	var new_name := base_name + str(i)
	while pool.has(new_name):
		i += 1
		new_name = base_name + str(i)
	return new_name
