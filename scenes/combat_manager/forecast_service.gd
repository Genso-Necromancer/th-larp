extends CombatServiceBase
class_name ForecastService

var ACTION_TYPE = Enums.ACTION_TYPE
var _hex: AHexGrid2D = null

func get_forecast(a: UnitSim, t: UnitSim, action: Dictionary) -> CombatResults:
	var cr := CombatResults.new()
	cr.reset(CombatResults.MODE.FORECAST)

	cr.units["attacker_id"] = a.id
	cr.units["defender_id"] = t.id

	var action_type := _get_action_type(a, t, action)
	cr.meta["combat_type"] = int(action_type)
	cr.meta["deathmatch_rounds"] = 0
	cr.meta["vantage"] = false

	var round := cr.add_round()

	# --- Initiator preview ---
	var initiator_action_node := _add_forecast_action(cr, round, a, t, action, action_type, true)

	# --- Counter eligibility preview ---
	var counter_possible := false
	if a.id != t.id and action_type != ACTION_TYPE.FRIENDLY_SKILL:
		counter_possible = t.can_counterattack() and _reach_check(t, a) # defender reaching attacker

	# Store on initiator node for UI convenience
	initiator_action_node["counter_possible"] = counter_possible

	# If eligible, build defender preview action on the right side
	if counter_possible:
		var counter_action := {"Weapon": true, "Skill": null, "Item": null}
		_add_forecast_action(cr, round, t, a, counter_action, action_type, false)

	return cr

func _add_forecast_action(
	cr: CombatResults,
	round: Dictionary,
	actor: UnitSim,
	target: UnitSim,
	action: Dictionary,
	action_type: int,
	is_initiator: bool
) -> Dictionary:
	var action_node := cr.add_action(round, actor.id, target.id, action_type, is_initiator)
	_fill_action_source_fields(action_node, action)

	# Multi-swing count UI (x#)
	var base_swings := _get_base_swing_count(actor, action)
	action_node["swing_count"] = base_swings

	# Clash preview components
	var clash := _evaluate_clash(actor, target, action)

	# Follow-up icon only (no extra swing previews)
	action_node["followup_possible"] = bool(clash.get("FUP", false))

	# Forecast damage preview:
	# base -> apply slayer -> subtract reduction
	var base := int(clash.get("Dmg", 0))
	var charge_bonus := int(clash.get("ChargeBonus", 0))
	var reduction := int(clash.get("reduction", 0))
	var slayer_mult := _get_slayer_mult_for_forecast(actor, target, action)

	var scaled := int(round(float(base) * slayer_mult))
	var preview_dmg := maxi(0, scaled - reduction)

	# Single representative swing preview (UI uses swing_count separately)
	var swing := cr.add_swing(action_node)
	swing["hit_chance"] = clamp_chance(int(clash.get("Hit", 0)))
	swing["crit_chance"] = clamp_chance(int(clash.get("Crit", 0)))
	swing["dmg"] = preview_dmg if bool(clash.get("CanDmg", true)) else 0
	swing["reduction"] = reduction

	# Barrier shown as +Barrier next to DEF, with its proc chance
	swing["barrier"] = int(clash.get("BarrierAmt", 0))
	swing["bar_prc"] = int(clash.get("BarPrc", 0))

	# Useful for UI/debug
	swing["slayer_mult"] = slayer_mult
	var total_swings := int(action_node["swing_count"])
	var total_preview_dmg := preview_dmg
	if total_swings > 1:
		var later_base := maxi(0, base - charge_bonus)
		var later_scaled := int(round(float(later_base) * slayer_mult))
		var later_dmg := maxi(0, later_scaled - reduction)
		total_preview_dmg += later_dmg * (total_swings - 1)
	action_node["target_life_after"] = _get_remaining_life(target, total_preview_dmg, 1)
	action_node["actor_life_after"] = int(actor.current_life)
	
	# Effects preview (weapon + skill/item as appropriate)
	var effs := _evaluate_effects_preview(actor, target, action)
	for e in effs:
		var effect_res: Effect = e.get("effect", null)
		if effect_res != null and int(effect_res.type) == Enums.EFFECT_TYPE.RELOC:
			continue
		swing["effects"].append(e)

	return action_node


func _evaluate_effects_preview(a: UnitSim, t: UnitSim, action: Dictionary) -> Array:
	var sources: Array = []

	var is_weapon_attack := bool(action.get("Weapon", false))
	var skill_or_item = action.get("Item", null)
	if skill_or_item == null:
		skill_or_item = action.get("Skill", null)

	if is_weapon_attack:
		var wep = a.get_equipped_weapon()
		if wep != null:
			sources.append(wep)
		if a.equipped_attack_effects != null and not a.equipped_attack_effects.is_empty():
			sources.append({"effects": a.equipped_attack_effects})

	if skill_or_item != null:
		sources.append(skill_or_item)

	if sources.is_empty():
		return []

	var chance: int = int(a.combat_data.get("EffHit", 0))
	var resist: int = int(t.combat_data.get("Resist", 0))
	var out: Array = []

	for src in sources:
		var effects := _get_source_effects(src)
		if effects.is_empty():
			continue

		for effect: Effect in effects:
			# Ignore equip-only effects in forecast
			if effect.target == Enums.EFFECT_TARGET.EQUIPPED: continue
			#potential global skip, commented out until tested
			#if effect.target == Enums.EFFECT_TARGET.GLOBAL: continue
			var focus_is_actor := (effect.target == Enums.EFFECT_TARGET.SELF)
			var use_resist := (not focus_is_actor) and bool(effect.hostile)

			var always_proc := (int(effect.proc) == -1)
			var proc_chance := 0
			if not always_proc:
				proc_chance = chance + int(effect.proc)
				if use_resist:
					proc_chance -= resist
				proc_chance = clamp_chance(proc_chance)

			# value formatting
			var value = effect.value
			var resolved_value = value
			var focus := a if focus_is_actor else t

			if value and effect.type == Enums.EFFECT_TYPE.DAMAGE:
				resolved_value = _factor_dmg(focus, effect)
			elif value and effect.type == Enums.EFFECT_TYPE.HEAL:
				resolved_value = _factor_healing(a, focus, effect)
			elif value and effect.type == Enums.EFFECT_TYPE.DOT:
				resolved_value = _factor_dmg(focus, effect)
			elif value and effect.type == Enums.EFFECT_TYPE.HOT:
				resolved_value = _factor_healing(a, focus, effect)
			elif typeof(value) == TYPE_FLOAT:
				resolved_value = int(round(float(value) * 100.0))

			var slayer := (effect.type == Enums.EFFECT_TYPE.SLAYER and int(effect.sub_rule) == int(t.spec))

			out.append({
				"effect": effect,
				"is_self": focus_is_actor,
				"always_proc": always_proc,
				"proc_chance": proc_chance,
				"value": resolved_value,
				"slayer": slayer,
				"requires_hit": bool(effect.on_hit),
				"procced": false
			})

	return out

# NOTE: below helpers can stay here for now; later we’ll pull them into a shared “CombatMath” service
func _evaluate_clash(a: UnitSim, t: UnitSim, action: Dictionary) -> Dictionary:
	var results := {}

	var aData
	var tData := t.combat_data
	var tAct := t.active_stats

	var special = null
	var item = action.get("Item", null)
	var skill = action.get("Skill", null)
	var is_weapon := bool(action.get("Weapon", false))
	if item != null:
		special = item
		aData = a.get_skill_combat_stats(special, is_weapon)
	elif skill != null:
		special = skill
		aData = a.get_skill_combat_stats(special, is_weapon)
	else:
		aData = a.combat_data
	var instant_mods := _get_instant_stat_modifiers(a, t, action)
	var actor_mods: Dictionary = instant_mods.get("Actor", {})
	var target_mods: Dictionary = instant_mods.get("Target", {})

	# CanMiss
	results["CanMiss"] = bool(aData.get("CanMiss", true))

	# Hit
	var actor_hit := int(aData.Hit) + int(actor_mods.get("Hit", 0))
	var target_graze := int(tData.Graze) + int(target_mods.get("Graze", 0))
	var hit := actor_hit - target_graze
	hit -= _get_action_range_band_penalty(a, t, action, special, is_weapon)
	results["Hit"] = clampi(hit, 0, 1000)

	# DmgType
	var dmg_type := int(aData.Type)
	results["DmgType"] = dmg_type

	# CanDmg + base Dmg (UNREDUCED)
	if not bool(aData.get("CanDmg", true)):
		results["CanDmg"] = false
		results["Dmg"] = 0
	else:
		results["CanDmg"] = true
		var charge_bonus := _get_charge_bonus(a, t, action, is_weapon)
		results["Dmg"] = clampi(int(aData.Dmg) + int(actor_mods.get("Dmg", 0)) + charge_bonus, 0, 1000)
		results["ChargeBonus"] = charge_bonus

	# reduction = (Def/Mag + DRes) for phys/mag, DRes for true
	var def_part := 0
	var terrain_def := int(t.get_terrain_bonus().get("DefBonus", 0))
	if dmg_type == Enums.DAMAGE_TYPE.PHYS:
		def_part = int(tAct.Def) + int(target_mods.get("Def", 0)) + terrain_def
	elif dmg_type == Enums.DAMAGE_TYPE.MAG:
		def_part = int(tAct.Mag) + int(target_mods.get("Mag", 0))
	elif dmg_type == Enums.DAMAGE_TYPE.TRUE:
		def_part = 0

	var dres := int(tData.get("DRes", 0))
	var reduction := def_part + dres
	if dmg_type == Enums.DAMAGE_TYPE.TRUE:
		reduction = 0
	results["reduction"] = max(0, reduction)

	# CanCrit + Crit + crit_range
	if not bool(aData.get("CanCrit", true)):
		results["CanCrit"] = false
		results["Crit"] = 0
		results["crit_range"] = [0, 0]
	else:
		results["CanCrit"] = true
		var crit := int(aData.Crit) + int(actor_mods.get("Crit", 0)) - (int(tData.Luck) + int(target_mods.get("Luck", 0)))
		results["Crit"] = clampi(crit, 0, 1000)

		# crit_min/max from weapon/skill/item. weapon-skill adds them.
		var cmin := 0
		var cmax := 0

		var wep = a.get_equipped_weapon()
		if wep != null and is_weapon:
			cmin += int(_source_value(wep, "crit_min", 0))
			cmax += int(_source_value(wep, "crit_max", 0))

		if special != null:
			cmin += int(_source_value(special, "crit_min", 0))
			cmax += int(_source_value(special, "crit_max", 0))

		results["crit_range"] = [max(0, cmin), max(0, cmax)]

	# Barrier: eligible for weapon + weapon-skill, not for pure skills/items
	var barrier_eligible := is_weapon and not _is_pure_skill_or_item(action)
	if barrier_eligible and dmg_type == Enums.DAMAGE_TYPE.PHYS:
		results["BarrierAmt"] = int(tData.get("Barrier", 0)) + int(target_mods.get("Barrier", 0))
		results["BarPrc"] = int(tData.get("BarPrc", 0)) + int(target_mods.get("BarPrc", 0))
	else:
		results["BarrierAmt"] = 0
		results["BarPrc"] = 0

	# Follow-up preview: weapon-based only (pure skills never follow-up)
	results["FUP"] = bool(_speed_check(a, t)) and is_weapon and special == null

	return results


func _get_instant_stat_modifiers(actor: UnitSim, target: UnitSim, action: Dictionary) -> Dictionary:
	var mods := {"Actor": {}, "Target": {}}
	for src in _get_action_effect_sources(actor, action):
		for effect: Effect in _get_source_effects(src):
			if effect == null or not bool(effect.instant):
				continue
			if effect.type != Enums.EFFECT_TYPE.BUFF and effect.type != Enums.EFFECT_TYPE.DEBUFF:
				continue
			if not _effect_rule_passes(effect, actor, target):
				continue
			var focus_key := "Actor" if effect.target == Enums.EFFECT_TARGET.SELF else "Target"
			var stat_name := _effect_sub_type_to_stat_name(effect.sub_type)
			if stat_name == "":
				continue
			var value := int(effect.value)
			mods[focus_key][stat_name] = int(mods[focus_key].get(stat_name, 0)) + value
	return mods


func _get_action_effect_sources(actor: UnitSim, action: Dictionary) -> Array:
	var sources: Array = []
	var is_weapon_attack := bool(action.get("Weapon", false))
	var skill_or_item = action.get("Item", null)
	if skill_or_item == null:
		skill_or_item = action.get("Skill", null)
	if is_weapon_attack:
		var wep = actor.get_equipped_weapon()
		if wep != null:
			sources.append(wep)
		if actor.equipped_attack_effects != null and not actor.equipped_attack_effects.is_empty():
			sources.append({"effects": actor.equipped_attack_effects})
	if skill_or_item != null:
		sources.append(skill_or_item)
	return sources


func _effect_rule_passes(effect: Effect, actor: UnitSim, target: UnitSim) -> bool:
	match int(effect.rule_type):
		Enums.RULE_TYPE.NONE:
			return true
		Enums.RULE_TYPE.TARGET_SPEC:
			return int(effect.sub_rule) == int(target.spec)
		Enums.RULE_TYPE.SELF_SPEC:
			return int(effect.sub_rule) == int(actor.spec)
		Enums.RULE_TYPE.TIME:
			return int(effect.sub_rule) == int(Global.time_of_day)
		_:
			return true


func _effect_sub_type_to_stat_name(sub_type) -> String:
	var sub_type_int := int(sub_type) if typeof(sub_type) == TYPE_INT else Enums.SUB_TYPE.NONE
	match sub_type_int:
		Enums.SUB_TYPE.BARPRC:
			return "BarPrc"
		Enums.SUB_TYPE.EFFHIT:
			return "EffHit"
		Enums.SUB_TYPE.DRES:
			return "DRes"
		Enums.SUB_TYPE.NONE, Enums.SUB_TYPE.ALL, Enums.SUB_TYPE.RANDOM:
			return ""
		_:
			return Enums.SUB_TYPE.keys()[sub_type_int].to_pascal_case()


func _fill_action_source_fields(action_node: Dictionary, action_input: Dictionary) -> void:
	action_node["uses_weapon"] = bool(action_input.get("Weapon", false))

	var skill = action_input.get("Skill", null)
	if skill != null:
		action_node["skill_ref"] = skill
		action_node["skill_id"] = String(skill.id)

	var item = action_input.get("Item", null)
	if item != null:
		action_node["item_ref"] = item
		action_node["item_id"] = String(item.id)


func _get_action_type(unit1: UnitSim, unit2: UnitSim, action: Dictionary) -> int:
	# Mirrors the original CombatManager logic / Resolver sim logic
	if action.get("Weapon", false):
		return ACTION_TYPE.WEAPON

	# If both are enemies, treat as friendly (enemy-enemy support)
	if unit1.team == Enums.FACTION_ID.ENEMY and unit2.team == Enums.FACTION_ID.ENEMY:
		return ACTION_TYPE.FRIENDLY_SKILL

	# If neither is enemy (player/npc side), treat as friendly
	if unit1.team != Enums.FACTION_ID.ENEMY and unit2.team != Enums.FACTION_ID.ENEMY:
		return ACTION_TYPE.FRIENDLY_SKILL

	# Otherwise, hostile
	return ACTION_TYPE.HOSTILE_SKILL


func _reach_check(unit: UnitSim, target: UnitSim) -> bool:
	var wep = unit.get_equipped_weapon()
	if wep == null:
		return false

	var minR := int(wep.min_reach)
	var maxR := int(wep.max_reach)

	if _hex == null: _hex = AHexGrid2D.new(Global.map_ref)
	var distance := _hex.find_target_distance(unit.cell, target.cell)
	if distance >= minR and distance <= maxR:
		return true
	return _is_distance_in_range_band(wep, distance, "close") or _is_distance_in_range_band(wep, distance, "far")


func _get_action_range_band_penalty(actor: UnitSim, target: UnitSim, action: Dictionary, special, is_weapon: bool) -> int:
	if not is_weapon:
		return 0
	var source = actor.get_equipped_weapon()
	if source == null:
		return 0
	if _hex == null:
		_hex = AHexGrid2D.new(Global.map_ref)
	var distance := _hex.find_target_distance(actor.cell, target.cell)
	return _range_band_hit_penalty(source, distance)


func _get_charge_bonus(actor: UnitSim, target: UnitSim, action: Dictionary, is_weapon: bool) -> int:
	if not is_weapon:
		return 0
	if _has_brace_effect(target):
		return 0
	var source = actor.get_equipped_weapon()
	if source == null:
		return 0
	var charge_value := int(_source_value(source, "charge_value", 0))
	if charge_value <= 0:
		return 0
	var hexes := int(action.get("ChargeHexes", 0))
	return charge_value * maxi(0, hexes)


func _get_remaining_life(unit: UnitSim, delta: int, swings := 1) -> int:
	# delta: +damage, -healing
	var total :int= delta * max(1, int(swings))
	var after := int(unit.current_life) - total
	return clampi(after, 0, 9999)


func _get_skill_swing_count(skill) -> int:
	var swings := 1
	for effect in _get_source_effects(skill):
		if effect.type == Enums.EFFECT_TYPE.MULTI_SWING and effect.multi_swing > swings:
			swings = effect.multi_swing
	return swings


func _is_pure_skill_or_item(a: Dictionary) -> bool:
	# skill/item without weapon backing
	return (a.get("Skill", null) != null or a.get("Item", null) != null) and not bool(a.get("Weapon", false))


func _get_base_swing_count(actor: UnitSim, action: Dictionary) -> int:
	var special = action.get("Item", null)
	if special == null:
		special = action.get("Skill", null)

	if special != null:
		return _get_skill_swing_count(special)

	var ms = actor.get_multi_swing()
	return int(ms) if ms else 1


func _get_slayer_mult_from_effect(effect: Effect) -> float:
	if typeof(effect.value) == TYPE_FLOAT:
		var mult := float(effect.value)
		if mult > 0.0:
			return mult
	if typeof(effect.value) == TYPE_INT:
		var raw := int(effect.value)
		if raw > 0:
			return float(raw) / 100.0
	return float(Global.slayerMulti)


func _is_pre_damage_effect(effect: Effect) -> bool:
	if effect == null:
		return false
	match int(effect.type):
		Enums.EFFECT_TYPE.SLAYER, Enums.EFFECT_TYPE.CRIT_BUFF:
			return true
		_:
			return false


func _get_slayer_mult_for_forecast(actor: UnitSim, target: UnitSim, action: Dictionary) -> float:
	var sources: Array = []

	if bool(action.get("Weapon", false)):
		var wep = actor.get_equipped_weapon()
		if wep != null:
			sources.append(wep)

	var special = action.get("Item", null)
	if special == null:
		special = action.get("Skill", null)
	if special != null:
		sources.append(special)

	var best := 1.0
	for src in sources:
		for effect: Effect in _get_source_effects(src):
			if effect.type != Enums.EFFECT_TYPE.SLAYER:
				continue
			if int(effect.sub_rule) != int(target.spec):
				continue
			best = max(best, _get_slayer_mult_from_effect(effect))
	return best


func _get_source_effects(source) -> Array[Effect]:
	var out: Array[Effect] = []
	if source == null:
		return out

	if source is SlotWrapper:
		if source.effects == null:
			return out
		for effect in source.effects:
			if effect is Effect:
				out.append(effect)
		return out

	if typeof(source) != TYPE_DICTIONARY:
		return out

	var raw_effects = source.get("effects", [])
	if raw_effects == null:
		return out

	if raw_effects is Dictionary:
		raw_effects = raw_effects.values()

	for entry in raw_effects:
		if entry is Effect:
			out.append(entry)
		elif typeof(entry) == TYPE_DICTIONARY:
			var effect := Effect.from_data(entry)
			if effect != null:
				out.append(effect)
		elif typeof(entry) == TYPE_STRING:
			var path := String(entry)
			if path != "" and ResourceLoader.exists(path):
				var loaded = load(path)
				if loaded is Effect:
					out.append(loaded)

	return out
