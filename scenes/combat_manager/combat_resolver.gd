extends CombatServiceBase
class_name CombatResolver

var ACTION_TYPE = Enums.ACTION_TYPE
var passive_helper := CombatPassiveHelper.new()

#var _hex := AHexGrid2D.new(Global.map_ref) # watch this variable closely when debugging map transitions
var _hex :AHexGrid2D

# Public entry points
func resolve_live(attacker_sim: UnitSim, defender_sim: UnitSim, attacker_action: Dictionary) -> CombatResults:
	var policy := LiveOutcomePolicy.new()
	if !_hex:
		_hex = AHexGrid2D.new(Global.map_ref) # watch this variable closely when debugging map transitions
	return _resolve(attacker_sim, defender_sim, attacker_action, CombatResults.MODE.LIVE, policy)

func resolve_sim_hit_success(attacker_sim, defender_sim, action):
	if !_hex:
		_hex = AHexGrid2D.new(Global.map_ref) # watch this variable closely when debugging map transitions
	return _resolve(attacker_sim, defender_sim, action, CombatResults.MODE.SIM, SimOutcomePolicy.new(SimOutcomePolicy.SCENARIO.HIT_SUCCESS))

func resolve_sim_hit_failure(attacker_sim, defender_sim, action):
	if !_hex:
		_hex = AHexGrid2D.new(Global.map_ref) # watch this variable closely when debugging map transitions
	return _resolve(attacker_sim, defender_sim, action, CombatResults.MODE.SIM, SimOutcomePolicy.new(SimOutcomePolicy.SCENARIO.HIT_FAIL))

# Core resolver
func _resolve(attacker_sim: UnitSim, defender_sim: UnitSim, attacker_action: Dictionary, mode: int, policy: CombatOutcomePolicy) -> CombatResults:
	var cr := CombatResults.new()
	cr.reset(mode)

	cr.units["attacker_id"] = attacker_sim.id
	cr.units["defender_id"] = defender_sim.id

	policy.begin(self)

	var action_type := _get_action_type(attacker_sim, defender_sim, attacker_action)
	cr.meta["combat_type"] = int(action_type)

	# ----------------------------
	# Pre-combat flow changers
	# ----------------------------
	var deathmatch_extra := 0
	var dm_effect := _find_multi_round_effect(attacker_action)
	if dm_effect:
		var dm_ok := true if int(dm_effect.proc) == -1 else policy.decide_effect_proc(clamp_chance(int(dm_effect.proc)))
		if dm_ok:
			deathmatch_extra = maxi(0, int(dm_effect.multi_round))
	cr.meta["deathmatch_rounds"] = deathmatch_extra
	var rounds_remaining := 1 + deathmatch_extra

	var vantage := false
	if action_type == ACTION_TYPE.WEAPON or action_type == ACTION_TYPE.HOSTILE_SKILL:
		vantage = _vantage_triggers(attacker_sim, defender_sim, policy)
	cr.meta["vantage"] = vantage

	if vantage:
		var tmp := attacker_sim
		attacker_sim = defender_sim
		defender_sim = tmp

		attacker_action = _as_basic_weapon_action()

		cr.units["attacker_id"] = attacker_sim.id
		cr.units["defender_id"] = defender_sim.id

	# ----------------------------
	# Round loop
	# ----------------------------
	for r in range(rounds_remaining):
		if attacker_sim.current_life <= 0 or defender_sim.current_life <= 0:
			break

		var rnd := cr.add_round()

		var attacker_was_hit := false
		var defender_was_hit := false
		var attacker_dmg_taken := 0
		var defender_dmg_taken := 0

		# Weapon-skill only allowed on first initiator strike of round 0
		var allow_weapon_skill := (r == 0) and bool(attacker_action.get("Weapon", false)) and (attacker_action.get("Skill", null) != null)
		var initiator_action := attacker_action if allow_weapon_skill else (_as_basic_weapon_action() if bool(attacker_action.get("Weapon", false)) else attacker_action)

		# 1) Attacker strike
		var atk_action_data := cr.add_action(rnd, attacker_sim.id, defender_sim.id, action_type, true)
		_fill_action_source_fields(atk_action_data, initiator_action)
		atk_action_data["swing_count"] = _get_swing_count(attacker_sim, initiator_action)

		var atk_sum := _add_action_result(
			cr,
			atk_action_data,
			attacker_sim,
			defender_sim,
			initiator_action,
			action_type,
			true,
			policy,
			{"allow_weapon_skill": allow_weapon_skill}
		)

		defender_was_hit = bool(atk_sum.get("target_was_hit", false))
		defender_dmg_taken = int(atk_sum.get("target_damage_taken", 0))

		if defender_sim.current_life <= 0:
			continue

		# Pure skill/item that deals damage blocks counter + follow-up
		var attacker_used_pure_skill := _is_pure_skill_or_item(initiator_action)
		var blocked_counter := attacker_used_pure_skill and bool(defender_dmg_taken)
		var blocked_followup := attacker_used_pure_skill or blocked_counter

		# 2) Counter
		if not blocked_counter:
			var can_attempt := defender_sim.can_counterattack() and _can_reach(defender_sim, attacker_sim)
			if can_attempt:
				var allow := false
				var vengeance_proc := false

				if not defender_was_hit:
					allow = true
				else:
					# VENGEANCE supersedes COUNTER
					var ven_base := defender_sim.get_best_passive_proc(Enums.PASSIVE_TYPE.VENGEANCE, 0)
					if ven_base > 0:
						var ven_chance := clamp_chance(ven_base + int(defender_dmg_taken / 2))
						vengeance_proc = policy.decide_effect_proc(ven_chance)
						if vengeance_proc:
							allow = true

					if not allow:
						var ctr_base := defender_sim.get_best_passive_proc(Enums.PASSIVE_TYPE.COUNTER, 0)
						if ctr_base > 0:
							allow = policy.decide_effect_proc(clamp_chance(ctr_base))

				if allow:
					var def_action := _as_basic_weapon_action()
					var def_action_data := cr.add_action(rnd, defender_sim.id, attacker_sim.id, action_type, false)
					def_action_data["swing_count"] = _get_swing_count(defender_sim, def_action)
					def_action_data["counter_possible"] = true

					var def_sum := _add_action_result(
						cr,
						def_action_data,
						defender_sim,
						attacker_sim,
						def_action,
						action_type,
						false,
						policy,
						{
							"apply_vengeance_bonus": vengeance_proc,
							"vengeance_bonus": defender_dmg_taken
						}
					)

					attacker_was_hit = bool(def_sum.get("target_was_hit", false))
					attacker_dmg_taken = int(def_sum.get("target_damage_taken", 0))

		if attacker_sim.current_life <= 0 or defender_sim.current_life <= 0:
			continue

		# 3) Follow-up (attacker only): weapon-only, basic weapon only.
		# A follow-up only occurs if the first exchange dealt no damage:
		# the initiator failed to damage the defender, then also avoided damage from retaliation.
		if not blocked_followup and bool(initiator_action.get("Weapon", false)):
			var exchange_dealt_damage := defender_dmg_taken > 0 or attacker_dmg_taken > 0
			if attacker_sim.current_life > 0 and defender_sim.current_life > 0 and (not exchange_dealt_damage) and _speed_check(attacker_sim, defender_sim):
				var fup_action := _as_basic_weapon_action()
				var fup_node := cr.add_action(rnd, attacker_sim.id, defender_sim.id, ACTION_TYPE.WEAPON, true)
				fup_node["swing_count"] = _get_swing_count(attacker_sim, fup_action)

				atk_action_data["followup_possible"] = true
				_add_action_result(cr, fup_node, attacker_sim, defender_sim, fup_action, ACTION_TYPE.WEAPON, true, policy)
	
	return cr

func _add_action_result(
	cr: CombatResults,
	action_data: Dictionary,
	actor: UnitSim,
	target: UnitSim,
	action: Dictionary,
	action_type: int,
	is_initiator: bool,
	policy: CombatOutcomePolicy,
	ctx: Dictionary = {}
) -> Dictionary:
	var apply_vengeance_bonus := bool(ctx.get("apply_vengeance_bonus", false))
	var vengeance_bonus := int(ctx.get("vengeance_bonus", 0))
	var swings := _get_swing_count(actor, action)
	action_data["swing_count"] = swings

	var target_was_hit := false
	var target_damage_taken := 0

	for swing_i in range(swings):
		var swing := cr.add_swing(action_data)
		if swing_i == 0 and bool(action.get("Weapon", false)):
			_emit_durability_event(swing, actor.id, -1)
		elif swing_i == 0 and action.get("Item", null) is Item:
			_emit_durability_event(swing, actor.id, -1, EFFECT_PHASE.POST_DAMAGE, action.get("Item"))

		var clash := _evaluate_clash(actor, target, action)
		if swing_i == 0:
			action["ChargeHexes"] = 0
		swing["hit_chance"] = clamp_chance(int(clash.get("Hit", 0)))
		swing["crit_chance"] = clamp_chance(int(clash.get("Crit", 0)))
		swing["reduction"] = int(clash.get("reduction", 0))

		# --- HIT / FATED ---
		var did_hit := true
		if bool(clash.get("CanMiss", true)):
			did_hit = policy.decide_hit(int(swing["hit_chance"]))

		if not did_hit:
			var fated_proc := actor.get_best_passive_proc(Enums.PASSIVE_TYPE.FATED, 0)
			if fated_proc > 0 and policy.decide_effect_proc(clamp_chance(fated_proc)):
				did_hit = true
				swing["events"].append({"type": "fated_hit", "actor_id": actor.id, "target_id": target.id})

		swing["hit"] = did_hit
		target_was_hit = target_was_hit or did_hit

		# --- PRE / POST effect resolution ---
		var crit_bonus := 0
		var crit_min_bonus := 0
		var crit_max_bonus := 0
		var post_proc_effects: Array = []

		var eff_records := _evaluate_effects(actor, target, action)

		for eff in eff_records:
			if bool(eff.get("requires_hit", false)) and not did_hit:
				continue
			var always_proc := bool(eff.get("always_proc", false))
			var proc_chance := int(eff.get("proc_chance", 0))
			var procced := true if always_proc else policy.decide_effect_proc(proc_chance)

			eff["procced"] = procced
			var effect_res: Effect = eff.get("effect", null)
			if effect_res == null:
				continue
			if int(effect_res.type) != Enums.EFFECT_TYPE.RELOC:
				swing["effects"].append(eff)

			if not procced:
				continue

			var phase := _classify_effect_phase(effect_res)

			# PRE_DAMAGE effects modify local combat math before crit/dmg
			if phase == EFFECT_PHASE.PRE_DAMAGE:
				match int(effect_res.type):
					Enums.EFFECT_TYPE.SLAYER:
						if bool(eff.get("slayer", false)):
							var mult := _get_slayer_mult_from_effect(effect_res)
							swing["slayer_mult"] = max(float(swing.get("slayer_mult", 1.0)), mult)

					Enums.EFFECT_TYPE.CRIT_BUFF:
						# Pass A: support crit chance + crit range bonuses
						crit_bonus += int(effect_res.crit_rate)

						if effect_res.crit_dmg is Array and effect_res.crit_dmg.size() >= 2:
							crit_min_bonus += int(effect_res.crit_dmg[0])
							crit_max_bonus += int(effect_res.crit_dmg[1])

						# crit_mult intentionally deferred until you decide the contract

					_:
						pass

				_emit_effect_event(swing, actor, target, eff)

			else:
				# POST_DAMAGE effects are emitted after base damage is known/applied
				post_proc_effects.append(eff)

		# --- CRIT + CRIT DMG (after PRE_DAMAGE effects) ---
		var crit_dmg := 0
		var did_crit := false

		var crit_chance := int(clash.get("Crit", 0)) + crit_bonus
		crit_chance = clamp_chance(crit_chance)
		swing["crit_chance"] = crit_chance

		if did_hit and bool(clash.get("CanCrit", false)) and policy.decide_crit(crit_chance):
			did_crit = true

			var cmin := int(clash.get("crit_range", [0, 0])[0]) if clash.get("crit_range", [0, 0]).size() > 0 else 0
			var cmax := int(clash.get("crit_range", [0, 0])[1]) if clash.get("crit_range", [0, 0]).size() > 1 else 0

			cmin += crit_min_bonus
			cmax += crit_max_bonus

			cmin = max(0, cmin)
			cmax = max(cmin, cmax)

			crit_dmg = policy.decide_crit_dmg(cmin, cmax)

		swing["crit"] = did_crit
		swing["crit_dmg"] = crit_dmg

		# --- BARRIER roll ---
		var barrier_applied := 0
		var barrier_amt := int(clash.get("BarrierAmt", 0))
		var bar_prc := int(clash.get("BarPrc", 0))
		swing["bar_prc"] = bar_prc

		var barrier_eligible := bool(action.get("Weapon", false)) and not _is_pure_skill_or_item(action)
		if barrier_eligible and did_hit and int(clash.get("DmgType", Enums.DAMAGE_TYPE.PHYS)) == Enums.DAMAGE_TYPE.PHYS:
			if barrier_amt > 0 and bar_prc > 0 and policy.decide_effect_proc(clamp_chance(bar_prc)):
				barrier_applied = barrier_amt
		swing["barrier"] = barrier_applied


		# --- DAMAGE factoring ---
		var dmg := 0
		if did_hit and bool(clash.get("CanDmg", false)):
			var base := int(clash.get("Dmg", 0))
			var mult := float(swing.get("slayer_mult", 1.0))

			base = int(round(float(base) * mult))
			if apply_vengeance_bonus:
				base += vengeance_bonus
			base += crit_dmg

			var reduction := int(swing.get("reduction", 0))
			base = maxi(0, base - (reduction + barrier_applied))
			dmg = base

		swing["dmg"] = dmg

		_apply_swing_composure(actor, target, swing, action, action_type, swing_i, clash, did_hit, did_crit, dmg, policy)

		# Apply base weapon damage first
		if did_hit and dmg > 0:
			target_damage_taken += dmg
			_emit_damage_event(swing, actor.id, target.id, dmg, EFFECT_PHASE.POST_DAMAGE)
			target.apply_dmg(dmg)
			if target.current_life <= 0:
				swing["target_dead"] = true

		# --- POST_DAMAGE effects ---
		for eff in post_proc_effects:
			var effect_res: Effect = eff.get("effect", null)
			if effect_res == null:
				continue

			# LIFE_STEAL depends on actual damage dealt by this swing
			if int(effect_res.type) == Enums.EFFECT_TYPE.LIFE_STEAL:
				eff["value"] = _factor_life_steal(dmg, effect_res.value)

			_emit_effect_event(swing, actor, target, eff)

		_debug_print_swing(actor, target, swing_i, swing, policy)

		if target.current_life <= 0:
			swing["target_dead"] = true
			break

	return {
		"target_was_hit": target_was_hit,
		"target_damage_taken": target_damage_taken,
	}


func _debug_print_swing(actor: UnitSim, target: UnitSim, swing_index: int, swing: Dictionary, policy: CombatOutcomePolicy) -> void:
	var hit_roll_text := "Auto"
	if policy is LiveOutcomePolicy:
		var live_policy := policy as LiveOutcomePolicy
		if live_policy.last_hit_roll >= 0:
			hit_roll_text = str(live_policy.last_hit_roll)
	print(
		"[Combat] Swing %d | Attacker: %s | Target: %s | Hit%%: %d | Roll: %s | Hit: %s | Damage: %d" % [
			swing_index + 1,
			actor.id,
			target.id,
			int(swing.get("hit_chance", 0)),
			hit_roll_text,
			str(bool(swing.get("hit", false))),
			int(swing.get("dmg", 0))
		]
	)


# ============================
# utilities
# ============================

func _get_action_type(u1: UnitSim, u2: UnitSim, action: Dictionary) -> int:
	if action.get("Weapon", false):
		return ACTION_TYPE.WEAPON
	elif u1.team == Enums.FACTION_ID.ENEMY and u2.team == Enums.FACTION_ID.ENEMY:
		return ACTION_TYPE.FRIENDLY_SKILL
	elif u1.team != Enums.FACTION_ID.ENEMY and u2.team != Enums.FACTION_ID.ENEMY:
		return ACTION_TYPE.FRIENDLY_SKILL
	return ACTION_TYPE.HOSTILE_SKILL


func _get_swing_count(actor: UnitSim, action: Dictionary) -> int:
	var swings := 1

	# Skill/Item multi-swing
	var special = action.get("Item", null)
	if special == null:
		special = action.get("Skill", null)

	if special != null:
		for effect in _get_source_effects(special):
			if effect.type == Enums.EFFECT_TYPE.MULTI_SWING and int(effect.multi_swing) > swings:
				swings = int(effect.multi_swing)
		return max(swings, 1)

	# Weapon multi-swing (actor passive/weapon effects already consolidated in UnitSim.get_multi_swing())
	if bool(action.get("Weapon", false)):
		var ms = actor.get_multi_swing()
		swings = int(ms) if ms else 1

	return max(swings, 1)


func _evaluate_clash(actor: UnitSim, target: UnitSim, action: Dictionary) -> Dictionary:
	var a_cd
	var t_cd := target.combat_data
	var special = action.get("Item", null)
	if special == null:
		special = action.get("Skill", null)
	var is_weapon := bool(action.get("Weapon", false))
	if special != null:
		a_cd = actor.get_skill_combat_stats(special, is_weapon)
	else:
		a_cd = actor.combat_data
	var instant_mods := _get_instant_stat_modifiers(actor, target, action)
	var actor_mods: Dictionary = instant_mods.get("Actor", {})
	var target_mods: Dictionary = instant_mods.get("Target", {})

	var can_miss := true
	var can_dmg := true
	var can_crit := true

	var actor_hit := int(a_cd.get("Hit", 0)) + int(actor_mods.get("Hit", 0))
	var target_graze := int(t_cd.get("Graze", 0)) + int(target_mods.get("Graze", 0))
	var hit := actor_hit - target_graze
	hit -= _get_action_range_band_penalty(actor, target, action, special, is_weapon)
	hit = clampi(hit, 0, 1000)
	var raw_hit := clampi(actor_hit - _get_action_range_band_penalty(actor, target, action, special, is_weapon), 0, 1000)
	var graze := clampi(target_graze, 0, 1000)

	var dmg_type := int(a_cd.get("Type", Enums.DAMAGE_TYPE.PHYS))
	if special != null:
		can_miss = bool(a_cd.get("CanMiss", true))
		can_dmg = bool(a_cd.get("CanDmg", true))
		can_crit = bool(a_cd.get("CanCrit", true))

	var dr := int(t_cd.get("DRes", 0))
	var reduction := 0
	var terrain_def := int(target.get_terrain_bonus().get("DefBonus", 0))
	match dmg_type:
		Enums.DAMAGE_TYPE.PHYS:
			reduction = int(target.active_stats.get(&"Def", 0)) + int(target_mods.get("Def", 0)) + terrain_def + dr
		Enums.DAMAGE_TYPE.MAG:
			reduction = int(target.active_stats.get(&"Mag", 0)) + int(target_mods.get("Mag", 0)) + dr
		Enums.DAMAGE_TYPE.TRUE:
			reduction = 0
			
	var charge_bonus := _get_charge_bonus(actor, target, action, is_weapon)
	var dmg := int(a_cd.get("Dmg", 0)) + int(actor_mods.get("Dmg", 0))
	dmg += charge_bonus
	dmg = clampi(dmg, 0, 1000)

	var crit := int(a_cd.get("Crit", 0)) + int(actor_mods.get("Crit", 0)) - (int(t_cd.get("Luck", 0)) + int(target_mods.get("Luck", 0)))
	crit = clampi(crit, 0, 1000)
	
	var crit_range: Array[int] = _get_crit_range(actor, action)

	var barrier_amt := 0
	var bar_prc := 0
	if bool(action.get("Weapon", false)) and not _is_pure_skill_or_item(action) and dmg_type == Enums.DAMAGE_TYPE.PHYS:
		barrier_amt = int(t_cd.get("Barrier", 0)) + int(target_mods.get("Barrier", 0))
		bar_prc = int(t_cd.get("BarPrc", 0)) + int(target_mods.get("BarPrc", 0))

	return {
		"CanMiss": can_miss,
		"RawHit": raw_hit,
		"Graze": graze,
		"CanDmg": can_dmg,
		"CanCrit": can_crit,
		"Hit": hit,
		"Dmg": dmg,
		"Crit": crit,
		"ChargeBonus": charge_bonus,
		"crit_range":crit_range,
		"DmgType": dmg_type,
		"BarrierAmt": barrier_amt,
		"BarPrc": bar_prc,
		"reduction": reduction,
}


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
		var wep := actor.get_equipped_weapon()
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


func _apply_swing_composure(
	actor: UnitSim,
	target: UnitSim,
	swing: Dictionary,
	action: Dictionary,
	action_type: int,
	swing_index: int,
	clash: Dictionary,
	did_hit: bool,
	did_crit: bool,
	dmg: int,
	policy: CombatOutcomePolicy
) -> void:
	var comp := Global.composure_values
	if typeof(comp) != TYPE_DICTIONARY or comp.is_empty():
		return

	var actor_delta := 0
	var target_delta := 0
	var actor_reasons: Array[String] = []
	var target_reasons: Array[String] = []
	var is_friendly_action: bool = action_type == ACTION_TYPE.FRIENDLY_SKILL
	var special = action.get("Item", null)
	if special == null:
		special = action.get("Skill", null)
	var has_special: bool = special != null
	var uses_attack_tax: bool = not is_friendly_action and not has_special

	if uses_attack_tax:
		var atk_cost := int(comp.get("atk", 0))
		actor_delta += atk_cost
		if atk_cost > 0:
			actor_reasons.append("attack")

	if swing_index == 0:
		if special != null:
			var skill_cost := int(_source_value(special, "cost", 0))
			actor_delta += skill_cost
			if skill_cost > 0:
				var cost_label: String = "item cost" if action.get("Item", null) != null else "skill cost"
				actor_reasons.append(cost_label)

	if not is_friendly_action:
		if not did_hit:
			if _miss_consumes_composure(clash, swing, policy):
				var evade_cost := int(comp.get("evade", 0))
				target_delta += evade_cost
				if evade_cost > 0:
					target_reasons.append("evade")
		else:
			var hit_cost := int(comp.get("hit", 0))
			target_delta += hit_cost
			if hit_cost > 0:
				target_reasons.append("hit")
			if dmg > 0:
				var ratio :int= max(1, int(comp.get("dmg_ratio", 1)))
				var dmg_cost := int(floor(float(dmg) / float(ratio)))
				target_delta += dmg_cost
				if dmg_cost > 0:
					target_reasons.append("damage")
			if did_crit:
				var crit_loss := int(comp.get("crit_loss", 0))
				var crit_restore := int(comp.get("crit_restore", 0))
				target_delta += crit_loss
				actor_delta -= crit_restore
				if crit_loss > 0:
					target_reasons.append("crit taken")
				if crit_restore > 0:
					actor_reasons.append("crit restore")

	swing["comp_actor"] = actor_delta
	swing["comp_target"] = target_delta
	swing["comp_actor_reasons"] = actor_reasons
	swing["comp_target_reasons"] = target_reasons

	if actor_delta != 0:
		actor.apply_composure(actor_delta)
	if target_delta != 0:
		target.apply_composure(target_delta)


func _miss_consumes_composure(clash: Dictionary, swing: Dictionary, policy: CombatOutcomePolicy) -> bool:
	var final_hit := clampi(int(swing.get("hit_chance", 0)), 0, 1000)
	var raw_hit := clampi(int(clash.get("RawHit", final_hit)), 0, 1000)
	var graze := clampi(int(clash.get("Graze", 0)), 0, 1000)

	if graze <= 0 or raw_hit <= final_hit:
		return false

	if policy is LiveOutcomePolicy:
		var live_policy := policy as LiveOutcomePolicy
		return live_policy.last_hit_roll > final_hit and live_policy.last_hit_roll <= raw_hit

	return true


func _get_crit_range(actor: UnitSim, action: Dictionary) -> Array[int]:
	var cmin := 0
	var cmax := 0
	var special = action.get("Item", null)
	if special == null:
		special = action.get("Skill", null)
	var is_weapon := bool(action.get("Weapon", false))

	if is_weapon:
		var wep = actor.get_equipped_weapon()
		if wep != null:
			cmin += int(wep.get("crit_min", 0))
			cmax += int(wep.get("crit_max", 0))

	if special != null:
		cmin += int(special.crit_min)
		cmax += int(special.crit_max)

	return Array([max(0, cmin), max(0, cmax)], TYPE_INT, "", null)


func _get_action_range_band_penalty(actor: UnitSim, target: UnitSim, action: Dictionary, special, is_weapon: bool) -> int:
	if not is_weapon:
		return 0
	var source = actor.get_equipped_weapon()
	if source == null:
		return 0
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


func _evaluate_effects(actor: UnitSim, target: UnitSim, action: Dictionary) -> Array:
	# Collect effect sources based on action type:
	# - Weapon-only: weapon effects
	# - Skill/Item-only: skill/item effects
	# - Weapon-skill hybrid: weapon effects + skill effects
	var sources: Array = []

	var is_weapon_attack := bool(action.get("Weapon", false))
	var skill_or_item = action.get("Item", null)
	
	if skill_or_item == null:
		skill_or_item = action.get("Skill", null)

	if is_weapon_attack:
		var wep := actor.get_equipped_weapon()
		if wep != null:
			sources.append(wep)
		if actor.equipped_attack_effects != null and not actor.equipped_attack_effects.is_empty():
			sources.append({"effects": actor.equipped_attack_effects})

	if skill_or_item != null:
		sources.append(skill_or_item)

	if sources.is_empty():
		return []

	var eff_hit := int(actor.combat_data.get("EffHit", 0))
	var resist := int(target.combat_data.get("Resist", 0))

	var out: Array = []

	for src in sources:
		var effects := _get_source_effects(src)
		if effects.is_empty():
			continue

		for effect: Effect in effects:
			# Ignore equip-only effects in combat resolution
			if effect.target == Enums.EFFECT_TARGET.EQUIPPED:
				continue

			# Instant effects are not handled here (flow-changing / global)
			if bool(effect.instant):
				if not _is_pre_damage_effect(effect):
					continue

			# Focus choice based on target flag:
			# SELF/GLOBAL => actor-focus, TARGET => target-focus
			if effect.target == Enums.EFFECT_TARGET.GLOBAL: continue
			var focus_is_actor := (effect.target == Enums.EFFECT_TARGET.SELF)

			# Hostile means "can be resisted"; self/global never use resist
			var use_resist := (not focus_is_actor) and bool(effect.hostile)

			# proc == -1 means always proc
			var always_proc := (int(effect.proc) == -1)

			var proc_chance := 0
			if not always_proc:
				proc_chance = eff_hit + int(effect.proc)
				if use_resist:
					proc_chance -= resist
				proc_chance = clamp_chance(proc_chance)

			# Resolve value formatting
			var value = effect.value
			var resolved_value = value
			if value and effect.type == Enums.EFFECT_TYPE.DAMAGE:
				# damage factoring uses target defense / DRes rules
				resolved_value = _factor_dmg(target, effect)
			elif value and effect.type == Enums.EFFECT_TYPE.HEAL:
				resolved_value = _factor_healing(actor, target, effect)
			elif value and effect.type == Enums.EFFECT_TYPE.DOT:
				resolved_value = _factor_dmg(target, effect)
			elif value and effect.type == Enums.EFFECT_TYPE.HOT:
				resolved_value = _factor_healing(actor, target, effect)
			elif typeof(value) == TYPE_FLOAT:
				resolved_value = int(round(float(value) * 100.0))

			# Slayer flag (you can also convert to a mult later)
			var slayer := (effect.type == Enums.EFFECT_TYPE.SLAYER and int(effect.sub_rule) == int(target.spec))

			out.append({
				"effect": effect,
				"is_self": focus_is_actor,   # "true" => apply to actor, else target
				"always_proc": always_proc,
				"proc_chance": proc_chance,
				"value": resolved_value,
				"slayer": slayer,
				"warp_destination": action.get("WarpDestination", null),
				"requires_hit": bool(effect.on_hit),
				"procced": false
			})
			

	return out

func _emit_damage_event(swing: Dictionary, source_id: String, target_id: String, amount: int, phase: int = EFFECT_PHASE.POST_DAMAGE) -> void:
	_push_event(swing, {"type": "damage", "source_id": source_id, "target_id": target_id, "amount": amount}, phase)

func _emit_heal_event(swing: Dictionary, source_id: String, target_id: String, amount: int, phase: int = EFFECT_PHASE.POST_DAMAGE) -> void:
	_push_event(swing, {"type": "heal", "source_id": source_id, "target_id": target_id, "amount": amount}, phase)

func _emit_durability_event(swing: Dictionary, owner_id: String, amount: int, phase: int = EFFECT_PHASE.POST_DAMAGE, item: Item = null) -> void:
	var event := {"type": "durability", "owner_id": owner_id, "amount": amount}
	if item != null:
		event["item"] = item
	_push_event(swing, event, phase)

func _emit_effect_event(swing: Dictionary, actor: UnitSim, target: UnitSim, eff: Dictionary) -> void:
	var effect_res: Effect = eff.get("effect", null)
	if effect_res == null:
		return

	var is_self := bool(eff.get("is_self", false))
	var focus: UnitSim = actor if is_self else target
	var focus_id := focus.id
	var value = eff.get("value", null)

	var phase := _classify_effect_phase(effect_res)

	# warn if designer forgot instant for pre-required types
	_warn_if_instant_missing(effect_res)

	match int(effect_res.type):
		Enums.EFFECT_TYPE.SLAYER:
			# Resolver already uses slayer_mult; still emit for visuals/debug if desired.
			_push_event(swing, {"type": "slayer", "target_id": focus_id, "effect": effect_res}, phase)

		Enums.EFFECT_TYPE.DAMAGE:
			if value != null and int(value) > 0:
				_emit_damage_event(swing, actor.id, focus_id, int(value), phase)
				# SIM requirement: apply immediately to UnitSim (phase-correct because this function is called in order)
				focus.apply_dmg(int(value))

		Enums.EFFECT_TYPE.HEAL, Enums.EFFECT_TYPE.LIFE_STEAL:
			if value != null and int(value) > 0:
				_emit_heal_event(swing, actor.id, focus_id, int(value), phase)
				focus.apply_heal(int(value))

		Enums.EFFECT_TYPE.COMP_DMG:
			if value != null and int(value) != 0:
				_push_event(swing, {"type": "comp_dmg", "target_id": focus_id, "amount": int(value), "source_id": actor.id}, phase)
				focus.apply_composure(abs(int(value)))

		Enums.EFFECT_TYPE.COMP_HEAL:
			if value != null and int(value) != 0:
				_push_event(swing, {"type": "comp_heal", "target_id": focus_id, "amount": int(value), "source_id": actor.id}, phase)
				focus.apply_composure(-abs(int(value)))

		Enums.EFFECT_TYPE.BUFF, Enums.EFFECT_TYPE.DEBUFF:
			_push_event(swing, {"type": "buff", "target_id": focus_id, "effect": effect_res, "context_id": actor.id}, phase)

		Enums.EFFECT_TYPE.STATUS:
			_push_event(swing, {"type": "status", "target_id": focus_id, "effect": effect_res}, phase)

		Enums.EFFECT_TYPE.CURE:
			_push_event(swing, {"type": "cure", "target_id": focus_id, "effect": effect_res}, phase)

		Enums.EFFECT_TYPE.PURGE:
			_push_event(swing, {"type": "purge", "target_id": focus_id, "effect": effect_res}, phase)

		Enums.EFFECT_TYPE.PURITY:
			_push_event(swing, {"type": "purity", "target_id": focus_id, "effect": effect_res}, phase)

		Enums.EFFECT_TYPE.DOT, Enums.EFFECT_TYPE.HOT, Enums.EFFECT_TYPE.STATUS_BUFFER:
			_push_event(swing, {"type": "buff", "target_id": focus_id, "effect": effect_res, "context_id": actor.id}, phase)

		Enums.EFFECT_TYPE.RELOC:
			var event := {"type": "reloc", "source_id": actor.id, "target_id": focus_id, "effect": effect_res}
			if eff.get("warp_destination", null) is Vector2i:
				event["destination"] = eff.get("warp_destination")
			_push_event(swing, event, phase)

		Enums.EFFECT_TYPE.ADD_SKILL:
			_push_event(swing, {"type": "add_skill", "target_id": focus_id, "skill": effect_res.skill}, phase)

		Enums.EFFECT_TYPE.ADD_PASSIVE:
			_push_event(swing, {"type": "add_passive", "target_id": focus_id, "passive": effect_res.passive}, phase)

		Enums.EFFECT_TYPE.TIME:
			# Pass A: emit intent; CombatManager/Time system can consume.
			_push_event(swing, {"type": "time", "source_id": actor.id, "effect": effect_res}, phase)

		Enums.EFFECT_TYPE.MULTI_SWING, Enums.EFFECT_TYPE.MULTI_ROUND:
			# These are not swing on-hit events in the resolver flow.
			# Ignored safely.
			pass

		_:
			# unknown types won't crash; just emit generic for debug
			_push_event(swing, {"type": "effect", "target_id": focus_id, "effect": effect_res, "value": value}, phase)

# combat flow
func _is_basic_weapon_action(action: Dictionary) -> bool:
	return bool(action.get("Weapon", false)) and not action.get("Skill", null) and not action.get("Item", null)

func _is_non_weapon_skill_action(action: Dictionary) -> bool:
	return action.get("Skill", null) != null or action.get("Item", null) != null

func _can_follow_up(actor: UnitSim, target: UnitSim, action: Dictionary) -> bool:
	# Only weapon attacks can follow-up
	if not bool(action.get("Weapon", false)):
		return false
	if action.get("Skill", null) != null:
		return false
	if action.get("Item", null) != null:
		return false
	return _speed_check(actor, target)

func _can_counter(defender: UnitSim, attacker: UnitSim, defender_action: Dictionary, defender_was_hit: bool, defender_damage_taken_this_round: int, policy: CombatOutcomePolicy) -> Dictionary:
	# returns { "can": bool, "via": "NONE|VENGEANCE|COUNTER" }
	if defender.current_life <= 0:
		return {"can": false, "via": "NONE"}

	# Non-weapon skills prevent counters if they hit (your rule) — that is enforced
	# by callers (they should pass whether the incoming action hit).
	# Here we only decide if defender is allowed to counter at all.

	# Must be able to reach attacker to counter with a weapon.
	if not _can_reach(defender, attacker):
		return {"can": false, "via": "NONE"}

	# Standard: can counter if not hit
	if not defender_was_hit:
		return {"can": true, "via": "NONE"}

	# If was hit, only COUNTER passive or VENGEANCE proc allows counter.
	# VENGEANCE supersedes COUNTER.
	if passive_helper.has_passive(defender, Enums.PASSIVE_TYPE.VENGEANCE):
		var prc := passive_helper.vengeance_proc_chance(defender, defender_damage_taken_this_round)
		if policy.decide_effect_proc(clamp_chance(prc)):
			return {"can": true, "via": "VENGEANCE"}

	if passive_helper.has_passive(defender, Enums.PASSIVE_TYPE.COUNTER):
		var cprc := passive_helper.counter_proc_chance(defender)
		if policy.decide_effect_proc(clamp_chance(cprc)):
			return {"can": true, "via": "COUNTER"}

	return {"can": false, "via": "NONE"}

# Reach
func _get_reach(unit: UnitSim) -> Dictionary:
	var wr = unit.weapon_reach
	if wr is Dictionary:
		var minr := int(wr.get("Min", 1))
		var maxr := int(wr.get("Max", 1))
		return {
			"Min": minr,
			"Max": maxr,
			"CloseMin": int(wr.get("CloseMin", 0)),
			"CloseMax": int(wr.get("CloseMax", 0)),
			"FarMin": int(wr.get("FarMin", 0)),
			"FarMax": int(wr.get("FarMax", 0)),
		}
	return {"Min": 1, "Max": 1, "CloseMin": 0, "CloseMax": 0, "FarMin": 0, "FarMax": 0}

func _can_reach(attacker: UnitSim, defender: UnitSim) -> bool:
	var r := _get_reach(attacker)
	var distance := _hex.find_target_distance(attacker.cell, defender.cell)
	if distance >= int(r["Min"]) and distance <= int(r["Max"]):
		return true
	if _is_distance_in_reach_band(r, distance, "Close") or _is_distance_in_reach_band(r, distance, "Far"):
		return true
	return false


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

#Slayer Multi
func _get_slayer_mult_from_effect(effect: Effect) -> float:
	# Convention:
	# - if effect.value is float => use it as multiplier (e.g. 1.5)
	# - if int => interpret as percent (e.g. 150 => 1.5)
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

#Flow manipulators Deathmatch/vantage
func _find_multi_round_effect(action: Dictionary) -> Effect:
	# DeathMatch lives as EFFECT_TYPE.MULTI_ROUND on the "attack" (skill/item/weapon-skill resource)
	var attack = action.get("Skill", null)
	if attack == null:
		attack = action.get("Item", null)
	# If you later support weapon-skill effects living on weapon too, check weapon here.

	if attack == null:
		return null

	for e: Effect in _get_source_effects(attack):
		if e != null and int(e.type) == Enums.EFFECT_TYPE.MULTI_ROUND:
			return e
	return null

func _vantage_triggers(attacker: UnitSim, defender: UnitSim, policy: CombatOutcomePolicy) -> bool:
	var v_proc := defender.get_best_passive_proc(Enums.PASSIVE_TYPE.VANTAGE, 0)
	if attacker.get_best_passive_proc(Enums.PASSIVE_TYPE.VANTAGE, 0): return false
	elif v_proc <= 0: return false
	# proc roll (Vantage guaranteed if proc=100)
	if not policy.decide_effect_proc(clamp_chance(v_proc)): return false
	# speed gate identical to follow-up requirement
	return _speed_check(defender, attacker)
	
#Action checkers
func _is_weapon_action(a: Dictionary) -> bool:
	# weapon and weapon-skill
	return bool(a.get("Weapon", false))

func _is_pure_skill_or_item(a: Dictionary) -> bool:
	# skill/item without weapon backing
	return (a.get("Skill", null) != null or a.get("Item", null) != null) and not bool(a.get("Weapon", false))

func _as_basic_weapon_action() -> Dictionary:
	return {"Weapon": true, "Skill": null, "Item": null}

#Effect utility
enum EFFECT_PHASE { PRE_DAMAGE, POST_DAMAGE }

func _classify_effect_phase(effect_res: Effect) -> int:
	if effect_res == null:
		return EFFECT_PHASE.POST_DAMAGE
	return EFFECT_PHASE.PRE_DAMAGE if bool(effect_res.instant) else EFFECT_PHASE.POST_DAMAGE


func _warn_if_instant_missing(effect_res: Effect) -> void:
	# Runtime warning as a safety net (editor warnings are in Effect.gd too)
	if effect_res == null or bool(effect_res.instant):
		return

	match int(effect_res.type):
		Enums.EFFECT_TYPE.SLAYER, Enums.EFFECT_TYPE.CRIT_BUFF:
			push_warning("Effect should have instant=true to work as intended: %s (%s)" % [
				effect_res.resource_path if effect_res.resource_path != "" else str(effect_res),
				Enums.EFFECT_TYPE.keys()[int(effect_res.type)]
			])
		_:
			pass


func _push_event(swing: Dictionary, ev: Dictionary, phase: int) -> void:
	# Ensure buckets exist (older results safety)
	if not swing.has("events_pre"):
		swing["events_pre"] = []
	if not swing.has("events_post"):
		swing["events_post"] = []
	if not swing.has("events"):
		swing["events"] = []

	if phase == EFFECT_PHASE.PRE_DAMAGE:
		swing["events_pre"].append(ev)
	else:
		swing["events_post"].append(ev)

	# Back-compat combined stream (keeps older systems working)
	swing["events"].append(ev)

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
