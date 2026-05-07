extends Node
##Used to simulate units within the AI's thinking process
class_name UnitSim

# Snapshot state copied from a live Unit for AI evaluation.
var id:String
var team:Enums.FACTION_ID
var spec:Enums.SPEC_ID
var cell:Vector2i
var origin_cell:Vector2i
var current_life:int
var comp:int
var remaining_move:int = 0
var ai_role:int = Unit.AI_ROLE.NONE
var ai_task:int = Unit.AI_TASK.NONE
var ai_lock_position:bool = false
var leash_radius:int = -1
var leash_consumed:bool = false
var one_time_leash:bool = false
var total_stats:Dictionary
var active_stats:Dictionary
#var total_stats:Dictionary[StringName,int]
#var active_stats:Dictionary[StringName,int]
#Specific Typing removed for now as other scripts lack the typing and Godot does not play nice between the two, even if valid
var status:Dictionary
var status_data:Dictionary
var weapon:Dictionary
var inventory:Dictionary
var natural:Dictionary
var skills:Dictionary
var passives:Dictionary
var auras
var threats:Array
var move_type:Enums.MOVE_TYPE
var terrain_tags:Dictionary
var terrain_bonus:Dictionary
var combat_data:Dictionary
var weapon_reach:Dictionary # {"Min": int, "Max": int} optional
var equipped_effects: Array[Dictionary] = [] # list of Effect.convert_to_data() dicts (+ optional instance fields)
var active_buffs: Dictionary = {}
var active_debuffs: Dictionary = {}
var owned_auras: Array[Dictionary] = []
var active_auras: Array[Dictionary] = []


# Clone is the backbone of branching AI evaluation.
# Every hypothetical line should operate on an isolated copy.
func clone() -> UnitSim:
	var c = UnitSim.new()
	c.id = id
	c.team = team
	c.spec = spec
	c.cell = cell
	c.origin_cell = origin_cell
	c.current_life = current_life
	c.comp = comp
	c.remaining_move = remaining_move
	c.ai_role = ai_role
	c.ai_task = ai_task
	c.ai_lock_position = ai_lock_position
	c.leash_radius = leash_radius
	c.leash_consumed = leash_consumed
	c.one_time_leash = one_time_leash
	c.total_stats = total_stats.duplicate(true) if total_stats != null else {}
	c.active_stats = active_stats.duplicate(true) if active_stats != null else {}
	c.status = status.duplicate(true) if status != null else {}
	c.status_data = status_data.duplicate(true) if status_data != null else {}
	c.passives = passives.duplicate(true) if passives != null else {}
	c.skills = skills.duplicate(true) if skills != null else {}
	c.inventory = inventory.duplicate(true) if inventory != null else {}
	c.weapon = weapon.duplicate(true) if weapon != null else {}
	c.natural = natural.duplicate(true) if natural != null else {}
	c.threats = threats.duplicate() if threats != null else []
	c.move_type = move_type
	c.terrain_tags = terrain_tags.duplicate(true) if terrain_tags != null else {}
	c.terrain_bonus = terrain_bonus.duplicate(true) if terrain_bonus != null else {}
	c.combat_data = combat_data.duplicate(true) if combat_data != null else {}
	c.weapon_reach = weapon_reach.duplicate(true) if weapon_reach != null else {} # optional but very helpful
	c.equipped_effects = equipped_effects.duplicate(true) if equipped_effects != null else []
	c.active_buffs = active_buffs.duplicate(true) if active_buffs != null else {}
	c.active_debuffs = active_debuffs.duplicate(true) if active_debuffs != null else {}
	c.owned_auras = owned_auras.duplicate(true) if owned_auras != null else []
	c.active_auras = active_auras.duplicate(true) if active_auras != null else []
	c.recompute_derived_state()
	return c

# Simple mutators used by sim-side resolution.
func apply_dmg(amount: int) -> void:
	if amount <= 0:
		return
	current_life = max(0, current_life - amount)
	# Optional: mirror simple “wake on damage” behavior in sim, if you track statuses:
	# if status.get("Sleep", false): status["Sleep"] = false

func apply_heal(amount: int, max_life: int = 9999) -> void:
	if amount <= 0:
		return
	current_life = min(max_life, current_life + amount)

# Basic state and eligibility checks used by action generation.
func is_alive() -> bool:
	return current_life > 0

func has_status(key) -> bool:
	# Supports both String and StringName keys
	if status == null:
		return false
	if status.has(key):
		return bool(status[key])
	# Common fallback if some systems stored StringName
	if typeof(key) == TYPE_STRING and status.has(StringName(key)):
		return bool(status[StringName(key)])
	return false

func can_act() -> bool:
	if not is_alive():
		return false

	# PASS A: common “cannot act” flags
	# Adjust keys to match what you actually store (e.g. "Acted", "Sleep", etc.)
	if has_status("Acted"):
		return false
	if has_status("Sleep"):
		return false

	return true


func can_counterattack() -> bool:
	if not is_alive():
		return false
	if has_status("Sleep"):
		return false
	return true


func can_canto() -> bool:
	return remaining_move > 0 and has_passive_type(Enums.PASSIVE_TYPE.CANTO)


func is_position_locked() -> bool:
	return ai_lock_position


func has_active_leash() -> bool:
	return leash_radius > -1 and not leash_consumed


func consume_leash() -> void:
	leash_consumed = true
	if one_time_leash:
		leash_radius = -1

# These iterators normalize the saved dictionary layout into flat arrays.
# That keeps downstream AI code from caring how Unit serializes its data.
func iter_passives() -> Array:
	var out: Array = []
	if passives == null:
		return out

	if passives is Dictionary:
		for k in passives.keys():
			var p = passives[k]
			if p != null:
				out.append(p)

	return out


func iter_skills() -> Array:
	var out: Array = []
	if skills == null:
		return out
	if skills is Dictionary:
		for k in skills.keys():
			var s = skills[k]
			if s != null:
				out.append(s)
	return out


func iter_inventory() -> Array:
	var out: Array = []
	if inventory == null:
		return out
	if inventory is Dictionary:
		for k in inventory.keys():
			var item = inventory[k]
			if item != null:
				out.append(item)
	return out

# Passive helpers are grouped here because they are used by both legality
# checks and combat-context rebuilding.
func has_passive_type(p_type: int) -> bool:
	for p in iter_passives():
		if p is Dictionary and int(p.type) == p_type:
			return true
	return false


func get_best_passive_proc(p_type: int, default_proc := 0) -> int:
	var best := default_proc
	for p in iter_passives():
		if p is Dictionary and int(p.type) == p_type:
			best = maxi(best, int(p.proc))
	return best


# Source helpers let the sim read either live-style resources or serialized
# dictionaries without duplicating the same null/type checks everywhere.
func _source_value(source, key: String, default_value = null):
	if source == null:
		return default_value
	if typeof(source) == TYPE_DICTIONARY:
		return source.get(key, default_value)
	return source.get(key) if source.get(key) != null else default_value


func _source_bool(source, key: String, default_value := false) -> bool:
	var value = _source_value(source, key, default_value)
	return bool(value)


# Skill combat data mirrors the live Unit contract closely enough for forecast
# and resolver code to treat sim actions like live actions.
func get_skill_combat_stats(special, augmented := false) -> Dictionary:
	var stats := combat_data.duplicate(true)
	var dmg_stat := 0
	var attack = get_equipped_weapon() if augmented else special
	var skill_dmg_type = _source_value(special, "dmg_type", null)
	var type_lord = skill_dmg_type if augmented and skill_dmg_type else _source_value(attack, "dmg_type", Enums.DAMAGE_TYPE.PHYS)
	stats["Type"] = int(type_lord)

	match int(type_lord):
		Enums.DAMAGE_TYPE.PHYS:
			dmg_stat = int(stats.get("PwrBase", 0))
		Enums.DAMAGE_TYPE.MAG:
			dmg_stat = int(stats.get("MagBase", 0))
		Enums.DAMAGE_TYPE.TRUE:
			dmg_stat = 0

	stats["CanDmg"] = _source_bool(special, "can_dmg", true)
	if not bool(stats["CanDmg"]):
		stats["Dmg"] = 0
	elif augmented:
		stats["Dmg"] = dmg_stat + int(_source_value(attack, "dmg", 0)) + int(_source_value(special, "dmg", 0))
	else:
		stats["Dmg"] = dmg_stat + int(_source_value(attack, "dmg", 0))

	stats["CanMiss"] = _source_bool(special, "can_miss", true)

	if augmented:
		stats["Hit"] = int(stats.get("HitBase", 0)) + int(_source_value(attack, "hit", 0)) + int(_source_value(special, "hit", 0))
	else:
		stats["Hit"] = int(stats.get("HitBase", 0)) + int(_source_value(attack, "hit", 0))

	var skill_crit = _source_value(special, "crit", null)
	stats["CanCrit"] = _source_bool(special, "can_crit", true)
	if not bool(stats["CanCrit"]):
		stats["Crit"] = 0
	elif skill_crit == null:
		stats["Crit"] = 0
	elif augmented:
		stats["Crit"] = int(stats.get("CritBase", 0)) + int(_source_value(attack, "crit", 0)) + int(skill_crit)
	else:
		stats["Crit"] = int(stats.get("CritBase", 0)) + int(_source_value(attack, "crit", 0))

	return stats

# Equipment and environment lookups feed the derived combat rebuild.
func get_equipped_weapon()->Dictionary:
	if weapon != null and not weapon.is_empty():
		return weapon
	if natural != null and not natural.is_empty():
		return natural
	return {}

func get_multi_swing():
	var swings := 0

	for ed in equipped_effects:
		if typeof(ed) != TYPE_DICTIONARY:
			continue

		var etype := int(ed.get("type", -1))
		if etype != Enums.EFFECT_TYPE.MULTI_SWING:
			continue

		# Prefer multi_swing field; fall back to value for older content
		var v := int(ed.get("multi_swing", 0))
		if v <= 0:
			v = int(ed.get("value", 0))

		if v > swings:
			swings = v

	return false if swings <= 0 else swings


func get_terrain_bonus() -> Dictionary:
	var bonus := {"GrzBonus": 0, "DefBonus": 0, "PwrBonus": 0, "MagBonus": 0, "HitBonus": 0}
	if move_type == Enums.MOVE_TYPE.FLY:
		return bonus
	if terrain_bonus != null and not terrain_bonus.is_empty():
		return terrain_bonus.duplicate(true)

	var tags := terrain_tags if terrain_tags != null else {}
	var terrain_data := PlayerData.terrainData
	var base_type := String(tags.get("BaseType", ""))
	var mod_type := String(tags.get("ModType", ""))

	if base_type != "" and terrain_data.has(base_type):
		for key in bonus.keys():
			bonus[key] += int(terrain_data[base_type].get(key, 0))

	if mod_type != "" and terrain_data.has(mod_type):
		for key in bonus.keys():
			bonus[key] += int(terrain_data[mod_type].get(key, 0))

	return bonus


# Position context is applied after hypothetical movement so terrain and aura
# driven bonuses are recalculated from the simulated destination.
func set_position_context(new_cell: Vector2i, new_terrain_tags: Dictionary = {}, new_active_auras: Array = []) -> void:
	cell = new_cell
	terrain_tags = new_terrain_tags.duplicate(true)
	terrain_bonus = {}
	active_auras = new_active_auras.duplicate(true)
	recompute_derived_state()


func _collect_effect_modifiers(effects: Array) -> Dictionary:
	var mods := {}
	var sub_keys = Enums.SUB_TYPE.keys()
	for effect_data in effects:
		if typeof(effect_data) != TYPE_DICTIONARY:
			continue
		var sub_type = int(effect_data.get("sub_type", -1))
		if sub_type < 0 or sub_type >= sub_keys.size():
			continue
		var stat_name = sub_keys[sub_type].to_pascal_case()
		mods[stat_name] = mods.get(stat_name, 0) + int(effect_data.get("value", 0))
	return mods


func get_buff_modifiers() -> Dictionary:
	var mods := {}
	for pool in [active_buffs, active_debuffs]:
		for id in pool.keys():
			var entry = pool[id]
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var effect_data = entry.get("effect", {})
			var effect_mods = _collect_effect_modifiers([effect_data])
			for key in effect_mods.keys():
				mods[key] = mods.get(key, 0) + int(effect_mods[key])
	return mods


func get_aura_modifiers() -> Dictionary:
	var mods := {}
	for aura_data in active_auras:
		if typeof(aura_data) != TYPE_DICTIONARY:
			continue
		var aura_effects = aura_data.get("effects", [])
		var aura_mods = _collect_effect_modifiers(aura_effects)
		for key in aura_mods.keys():
			mods[key] = mods.get(key, 0) + int(aura_mods[key])
	return mods


func recompute_derived_state() -> void:
	var derived_stats := total_stats.duplicate(true) if total_stats != null else {}
	var terrain_mods := get_terrain_bonus()
	var buff_mods := get_buff_modifiers()
	var aura_mods := get_aura_modifiers()

	for pool in [terrain_mods, buff_mods, aura_mods]:
		for key in pool.keys():
			if derived_stats.has(key):
				derived_stats[key] += int(pool[key])

	if has_status("Sleep"):
		derived_stats["Move"] = 0

	active_stats = derived_stats

	var wep := get_equipped_weapon()
	var combat := {
		"Type": int(wep.get("damage_type", Enums.DAMAGE_TYPE.PHYS)),
		"Dmg": 0,
		"Hit": 0,
		"Graze": 0,
		"Barrier": int(wep.get("barrier", 0)),
		"BarPrc": 0,
		"Crit": 0,
		"Luck": int(derived_stats.get("Cha", 0)),
		"CompRes": clampi((int(derived_stats.get("Cha", 0)) / 2) + (int(derived_stats.get("Eleg", 0)) / 2), -200, 75),
		"CompBonus": int(derived_stats.get("Cha", 0)) / 4,
		"PwrBase": int(derived_stats.get("Pwr", 0)),
		"MagBase": int(derived_stats.get("Mag", 0)),
		"HitBase": (int(derived_stats.get("Eleg", 0)) * 2) + int(derived_stats.get("Cha", 0)),
		"CritBase": int(derived_stats.get("Eleg", 0)),
		"Resist": int(derived_stats.get("Cha", 0)) * 2,
		"EffHit": int(derived_stats.get("Cha", 0)),
		"DRes": 0,
		"CanMiss": true,
	}

	match int(combat["Type"]):
		Enums.DAMAGE_TYPE.PHYS:
			combat["Dmg"] = int(wep.get("dmg", 0)) + int(derived_stats.get("Pwr", 0)) + int(terrain_mods.get("PwrBonus", 0))
		Enums.DAMAGE_TYPE.MAG:
			combat["Dmg"] = int(wep.get("dmg", 0)) + int(derived_stats.get("Mag", 0)) + int(terrain_mods.get("MagBonus", 0))
		Enums.DAMAGE_TYPE.TRUE:
			combat["Dmg"] = int(wep.get("dmg", 0))

	combat["Hit"] = int(combat["HitBase"]) + int(wep.get("hit", 0)) + int(terrain_mods.get("HitBonus", 0))
	combat["Graze"] = (int(derived_stats.get("Cele", 0)) * 2) + int(derived_stats.get("Cha", 0)) + int(terrain_mods.get("GrzBonus", 0))
	combat["BarPrc"] = (int(derived_stats.get("Eleg", 0)) / 2) + (int(derived_stats.get("Def", 0)) / 2) + int(wep.get("barrier_chance", 0)) + int(terrain_mods.get("DefBonus", 0))
	combat["Crit"] = int(combat["CritBase"]) + int(wep.get("crit", 0))

	if has_status("Sleep"):
		combat["Graze"] = 0
		combat["BarPrc"] = 0

	combat_data = combat


func apply_aura_enter(aura_data: Dictionary) -> void:
	active_auras.append(aura_data.duplicate(true))
	recompute_derived_state()


func apply_aura_exit(source_id: String = "", aura_path: String = "") -> void:
	for i in range(active_auras.size() - 1, -1, -1):
		var aura_data = active_auras[i]
		if typeof(aura_data) != TYPE_DICTIONARY:
			continue
		if source_id != "" and String(aura_data.get("source_id", "")) != source_id:
			continue
		if aura_path != "" and String(aura_data.get("path", "")) != aura_path:
			continue
		active_auras.remove_at(i)
	recompute_derived_state()
