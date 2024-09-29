extends Node
class_name CombatManager
signal combat_resolved
signal time_factor_changed
signal warp_selected
signal jobs_done_cmbtmnger

enum ACTION_TYPE {WEAPON, FRIENDLY_SKILL, HOSTILE_SKILL}

var rng = Global.rng
var fData := {}

var fateChance = 15


#var canReach = false
var gameBoard
var aHex

func init_manager():
	#link up dependancies
	gameBoard = get_parent()
	aHex = gameBoard.hexStar

#FORECAST FUNCTIONS

	##fData Heirarchy
	##fData
	##	[Unit]
	##		SkillId
	##		Initiator
	##		combat
	##			TrueHit
	##			Hit
	##			DMG
	##			Graze
	##			GrazePRC
	##			CRIT
	##			FUP
	##			RLife
	##		effects
	##			ID
	##				PROC
	##		Swings
	##		Counter
	##		Reach
func get_forecast(a: Unit, t: Unit, action) -> Dictionary: #HERE Augments not implemented!!!
	var op : Unit
	fData = {a:{},t: {}}
	fData[a]["SkillId"] = action.Skill
	fData[t]["SkillId"] = false
	fData[a]["Initiator"] = true
	fData[t]["Initiator"] = false
	
	for unit in fData:
		match fData[unit].Initiator:
			true: 
				op = t
				fData[unit]["Counter"] = true
				fData[unit]["Reach"] = true
			false: 
				op = a
				fData[unit]["Counter"] = unit.can_act()
				fData[unit]["Reach"] = _reach_check(t, a)
		
		fData[unit]["Combat"] = _evaluate_clash(unit, op, action)
		fData[unit]["Effects"] = _evaluate_effects(unit, op, fData[unit].SkillId)
		
		if action.Skill:
			fData[unit]["Swings"] = _get_skill_swing_count(action.Skill)
		else:
			fData[unit]["Swings"] = unit.get_multi_swing()
		
			
	for unit in fData:
		var swings = false
		match fData[unit].Initiator:
			true: op = t
			false: op = a
		if fData[unit].Swings:
			swings = fData[unit].Swings
		if fData[unit].Combat.Dmg and fData[unit].Reach and fData[unit].Counter:
			fData[op].Combat["Rlife"] = _get_remaining_life(op, fData[unit].Combat.Dmg, swings)
			
	return fData


func _evaluate_effects(a: Unit, t: Unit, skillId = false): ##returns proc chances of each effect on a skill or weapon. Returns false if there are none.
	#HERE
	#Only considers effects with Target: "Target", some "Self" effects may be relevant.
	#Does not consider "effect" damage, "skill" damage is handled in _evaluate_clash()
	
	#need updating after effect handling is finished. Also lacks "action" compatability
	var attack : Dictionary
	var chance : int = a.combatData.EffHit
	var resist : int = t.combatData.Resist
	var results : Dictionary
	var skillData = UnitData.skillData
	var effectData = UnitData.effectData
	
	if skillId:
		attack = skillData[skillId]
	else:
		attack = a.get_equipped_weapon()
	if !attack.has("Effects"):
		return false
	
	for id in attack.Effects:
		var effect = effectData[id]
		var value = effect.Value
		results = {id:{}}
			
		if effect.Target != Enums.EFFECT_TARGET.TARGET:
			results[id]["Self"] = true
		else: results[id]["Self"] = false
		
		if effect.Proc == -1:
			results[id]["Proc"] = false
		elif results[id].Self:
			results[id]["Proc"] = chance + effect.Proc
			results[id].Proc = clampi(results[id].Proc, 0, 100)
		else:
			results[id]["Proc"] = (chance + effect.Proc) - resist
			results[id].Proc = clampi(results[id].Proc, 0, 100)
			
		if value and effect.Type == Enums.EFFECT_TYPE.DAMAGE:
			results[id]["Value"] = _factor_dmg(t, effect)
		elif value and effect.Type == Enums.EFFECT_TYPE.HEAL:
			results[id]["Value"] = _factor_healing(a, t, effect)
		elif typeof(value) == Variant.Type.TYPE_FLOAT:
			var v = value * 100
			v = round(v)
			results[id]["Value"] = v
		else:
			results[id]["Value"] = value
	
	if results.size() > 0:
		return results
	else:
		return false


func _evaluate_clash(a, t, action):
	var results = {}
	var aData
	var tData = t.combatData
	var tAct = t.activeStats
	var skill : Dictionary
	var skillData = UnitData.skillData
	var skillId = action.Skill
	
	if !action.Skill:
		aData = a.combatData
	else:
		aData = a.get_skill_combat_stats(skillId, action.Weapon)
		skill = skillData[skillId]
	
	if skillId:
		results["TrueHit"] = skill.TrueHit
	else: results["TrueHit"] = false
	results["Hit"] = aData.Hit - tData.Avoid
	results.Hit = clampi(results.Hit, 0, 1000)
		
	if skillId and !skill.Dmg and skill.Dmg != 0:
		results["Dmg"] = false
	else:
		var d := 0
		match aData.Type:
			Enums.DAMAGE_TYPE.PHYS:
				d = tAct.Bar
			Enums.DAMAGE_TYPE.MAG:
				d = tAct.Mag
			Enums.DAMAGE_TYPE.TRUE:
				pass
		results["Dmg"] = aData.Dmg - d
		results.Dmg = clampi(results.Dmg, 0, 1000)
		
	if skillId and !skill.Crit and skill.Crit != 0:
		results["Crit"] = false
	else:
		results["Crit"] = aData.Crit - tData.CrtAvd
		results.Crit = clampi(results.Crit, 0, 1000)
	
	if !skillId:
		results["Graze"] = results.Dmg - tData.Graze
		results["GrzPrc"] = tData.GrzPrc
	else:
		results["Graze"] = false
		results["GrzPrc"] = false
		
		
	if _speed_check(a, t) and !skillId:
		results["FUP"] = true
	else:
		results["FUP"] = false
	return results


func _get_remaining_life(unit, dmg, swings = false):
	var rLife
	if swings:
		dmg = dmg * (1 + swings)
	rLife = unit.activeStats.CurLife - dmg
	rLife = clampi(rLife, 0, 1000)
	return rLife


func _reach_check(unit, target) -> bool:
	var itemData = UnitData.itemData
	var tWep = target.get_equipped_weapon()
	var minR = itemData[tWep.ID].MinRange
	var maxR = itemData[tWep.ID].MaxRange
	var hexStar = get_parent().get_hex_star()
	var distance = hexStar.compute_cost(unit.cell, target.cell, false, unit.unitData.MoveType)
	if distance >= minR and distance <= maxR:
		return true
	return false

#COMBAT FUNCTIONS
func start_the_justice(attacker : Unit, defender : Unit, attackerAction: Dictionary) -> Dictionary:
	var maxRounds : int = 1
	var initiator : Unit
	var initiate : Unit
	var initiatorAct
	var initiateAct
	var actionType := _get_action_type(attacker, defender, attackerAction)
	var vantage = false
	var deathMatch = false
	var wepAction := {"Weapon": true, "Skill": false}
	var combatResults : Dictionary = {}
	print("That really sick Thracia defense combat music")
	##check type, no need for deathMatch or vantage with friendly skills, or an opponent that can't even reach
	if actionType != ACTION_TYPE.FRIENDLY_SKILL and _reach_check(defender, attacker) and attacker.can_act():
		deathMatch = _get_death_match(attacker, attackerAction)
		#vantage = defender.has_vantage() #add a passive effect check function to Unit
	
	if deathMatch:
		maxRounds = deathMatch
	
	if vantage:
		initiator = defender
		initiate = attacker
		initiatorAct = wepAction
		initiateAct = attackerAction
	else:
		initiator = attacker
		initiate = defender
		initiatorAct = attackerAction
		initiateAct = wepAction
		
	#check for friendly response skill from initiate?
	
	combatResults["CombatType"] = actionType
	combatResults["DeathMatch"] = deathMatch
	combatResults["Vantage"] = vantage
	combatResults["StartingCondition"] = {initiator:initiator.get_condition()}
	combatResults["StartingCondition"] = {initiate:initiate.get_condition()}
	##Begin combat rounds
	for r in range(0, maxRounds):
		var lastAct
		var cmbRnd = ("Round" + str(r))
		initiator.update_stats()
		initiate.update_stats()
		##Initiator Acts
		combatResults[cmbRnd] = {}
		print("Round" + str(r))
		if r > 0:
			initiatorAct = wepAction
			
		if initiator.can_act():
			combatResults[cmbRnd][("Action" + str(1))] = _run_action(initiator, initiate, initiatorAct, actionType, true).duplicate(true)
			lastAct = combatResults[cmbRnd][("Action" + str(1))][initiator]
			print(str(initiator) + ": " + ("Action" + str(1) + ": ") + str(combatResults[cmbRnd][("Action" + str(1))]))
		else:
			break
			
		if _validate_response(initiate, initiator, lastAct, deathMatch, actionType) and _reach_check(initiate, initiator):
			combatResults[cmbRnd][("Action" + str(2))]  = _run_action(initiate, initiator, initiateAct, actionType, false).duplicate(true)
			lastAct = combatResults[cmbRnd][("Action" + str(2))][initiate]
			print(str(initiator) + ": " + ("Action" + str(2) + ": ") + str(combatResults[cmbRnd][("Action" + str(2))]))
		else: continue
			
		if _validate_response(initiator, initiate, lastAct, false, actionType) and _speed_check(initiator, initiate) and initiatorAct.Weapon:
			combatResults[cmbRnd][("Action" + str(3))]  = _run_action(initiator, initiate, initiatorAct, actionType, true).duplicate(true)
			print(str(initiator) + ": " + ("Action" + str(3) + ": ") + str(combatResults[cmbRnd][("Action" + str(3))]))
	return combatResults

func _get_action_type(unit1:Unit, unit2:Unit, action: Dictionary) -> int:
	if action.Weapon:
		return ACTION_TYPE.WEAPON
	elif unit1.FACTION_ID == Enums.FACTION_ID.ENEMY and unit2.FACTION_ID == Enums.FACTION_ID.ENEMY:
		return ACTION_TYPE.FRIENDLY_SKILL
	elif unit1.FACTION_ID != Enums.FACTION_ID.ENEMY and unit2.FACTION_ID != Enums.FACTION_ID.ENEMY:
		return ACTION_TYPE.FRIENDLY_SKILL
	else:
		return ACTION_TYPE.HOSTILE_SKILL

func _get_death_match(unit : Unit, action: Dictionary):
	var skillData = UnitData.skillData
	var effectData = UnitData.effectData
	var deathMatch = unit.get_multi_round()
	if !action.Skill or deathMatch:
		return deathMatch
	for effect in skillData[action.Skill].Effects:
		if effectData[effect].Type == Enums.EFFECT_TYPE.MULTI_ROUND:
			deathMatch = effectData[effect].Value
	return deathMatch
	

func _validate_response(actor, target, lastAct, deathMatch, actionType) -> bool:
	print("Validating response....")
	for swing in lastAct:
		print("Checking ", swing, "....")
		if !actor.can_act():
			print("Failed. Can't Act")
			return false
		elif actor == target:
			print("Failed. Targeting Self")
			return false
		elif actionType == ACTION_TYPE.FRIENDLY_SKILL:
			#Insert check for "friendly responses" here later
			print("Failed. Friendly Action")
			return false
		#elif !lastAct[swing].Hit:
			#print("Success. Enemy missed")
			#return true
		elif lastAct[swing].Dmg and lastAct[swing].Dmg > 0 and !deathMatch:
			print("Failed. Dmg taken while not in Death Match")
			return false
		elif lastAct[swing].Effects:
			for effect in lastAct[swing].Effects:
				if !effect.Resisted and !deathMatch:
					print("Failed. Effect not Resisted: ", str(lastAct[swing].Effects[effect]))
					return false
	print("Success, all checks passed.")
	return true


func _speed_check(unit1, unit2) -> bool:
	
	var unit1Spd = unit1.activeStats.Cele
	var unit2Spd = unit2.activeStats.Cele
	print("Checking speed... ","Unit1 Spd: ", unit1Spd, " Required Spd: ", str(unit2Spd+Global.spdGap))
	if unit1Spd >= (unit2Spd + Global.spdGap):
		print("Passed, follow-up allowed")
		return true
	print("Failed")
	return false

func _run_action(unit:Unit, target:Unit, action:Dictionary, actionType, isInitiator:bool) -> Dictionary: ##Augment functionality and passiveProcs not implemented yet
	var unitCd : Dictionary 
	var targetCd : Dictionary = target.combatData
	#var augment : Dictionary
	var def : int
	var critDmg : int = 0
	var grzDef : int = 0
	var weapon : Dictionary
	var unitEffects
	var multiSwing = false
	var swings = 1
	var outcome : Dictionary = {}
	var swingIndx
	var unitCompCost := 0
	var targetCompCost := 0
	var triggers = Enums.COMP_TRIGGERS
	var fate = unit.search_passive_id(Enums.PASSIVE_TYPE.FATED)
	var pData = UnitData.passiveData
	#target.apply_heal(healPower)
	
	print("Running Action....")
	if action.Skill:
		unitCompCost += _factor_combat_composure(unit, unit, UnitData.skillData[action.Skill].Cost)
		print("Skill Cost comp loss added: ",unit.unitName, " ", unitCompCost)
		multiSwing = _get_skill_swing_count(action.Skill)
	else:
		multiSwing = unit.get_multi_swing()
	
	if multiSwing:
		swings = multiSwing
	print("Swing Count: ", swings)
	for swing in swings:
		if !action.Skill:
			unitCompCost += _factor_combat_composure(unit, unit, triggers.ATTACK)
			print("Basic attack comp loss added: ",unit.unitName, " ", unitCompCost)
		swingIndx = ("Swing" + str(swing))
		print(str(swingIndx))
		outcome[unit] = {swingIndx:{"Hit" : false, "CompLoss": 0, "Dmg" : false, "Crit" : false, "SkillId" : action.Skill, "PassiveProc" : false, "Effects" : [], "Break" : false}}
		outcome[target] = {swingIndx:{"Graze" : false, "CompLoss": 0, "PassiveProc" : false, "Effects" : false, "Dead" : false,}}
		
		if action.Skill and action.Weapon:
			unitCd = unit.get_skill_combat_stats(action.Skill, true)
			weapon = unit.get_equipped_weapon()
			#augment = skillData[action.Skill]
		elif action.Skill:
			unitCd = unit.get_skill_combat_stats(action.Skill)
		elif action.Weapon:
			unitCd = unit.combatData
			weapon = unit.get_equipped_weapon()
			
		unitEffects = _get_action_effects(unit, action)
		
		for effId in unitEffects.Instant:
			print("Checking Instant Effects....")
			outcome[unit][swingIndx].Effects = outcome[unit][swingIndx].Effects + _run_effect(unit, target, effId, actionType)
		unitCompCost += _get_composure_total(unit, outcome[unit][swingIndx].Effects)
		targetCompCost += _get_composure_total(target, outcome[unit][swingIndx].Effects)
		print("Harvesting Effect Comp Loss.... ", unit.unitName, ": ", unitCompCost, " ", target.unitName, ": ", targetCompCost)
		#check units passive procs
		
		#determine def used
		def = targetCd.Def[unitCd.Type]

		
		
		
		#check accuracy
		print("Rolling for Hit. Chance: ", str(unitCd.Hit - targetCd.Avoid))
		if unitCd.TrueHit:
			outcome[unit][swingIndx].Hit = true
			print("Was True Hit")
		elif get_roll() <= unitCd.Hit - targetCd.Avoid:
			outcome[unit][swingIndx].Hit = true
			print("Hit Success")
		elif fate and get_roll() <= pData[fate].Value:
			outcome[unit][swingIndx].Hit = true
			outcome[unit][swingIndx].PassiveProc = fate
			print("Fated Hit!")
		else:
			print("Missed")
			unitCompCost += _factor_combat_composure(unit, unit, triggers.MISS)
			print("Attack Miss comp loss added: ",unit.unitName, " ", unitCompCost)
			targetCompCost += _factor_combat_composure(unit, target, triggers.DODGE)
			print("Attack Dodge comp loss added: ",target.unitName, " ", targetCompCost)
			
		
		if !outcome[unit][swingIndx].Hit:
			for effId in unitEffects.Always:
				outcome[unit][swingIndx].Effects = outcome[unit][swingIndx].Effects + _run_effect(unit, target, effId, actionType)
			unitCompCost += _get_composure_total(unit, outcome[unit][swingIndx].Effects)
			targetCompCost += _get_composure_total(target, outcome[unit][swingIndx].Effects)
			print("Harvesting Effect Comp Loss.... ", unit.unitName, ": ", unitCompCost, " ", target.unitName, ": ", targetCompCost)
			if outcome[unit][swingIndx].Effects and outcome[unit][swingIndx].Effects.size() <= 0:
				outcome[unit][swingIndx].Effects = false
			return outcome
			
		#check for Graze
		print("Rolling for Graze. Chance: ", str(targetCd.GrzPrc))
		if get_roll() <= targetCd.GrzPrc:
			grzDef = targetCd.Graze
			outcome[target][swingIndx].Graze = true
			print("Grazed. Graze Reduction: ", grzDef)
		else:
			print("Graze Failed")
		
		#check for crit
		if unitCd.Crit:
			print("Rolling for Crit. Chance: ", str(unitCd.Crit - targetCd.CrtAvd))
		if unitCd.Crit and get_roll() <= unitCd.Crit - targetCd.CrtAvd:
			critDmg = _get_crit_damage(unit)
			outcome[unit][swingIndx].Crit = true
			print("Crit Success. Crit Dmg: ", critDmg)
			unitCompCost += _factor_combat_composure(unit, unit, triggers.CRIT)
			print("Critically Hitting Comp Gain added: ", unit.unitName, " ", unitCompCost)
		else: print("Crit Failed")
			
		#determine damage outcome
		if outcome[unit][swingIndx].Hit:
			print("Target HP: ", str(target.activeStats.CurLife))
			
			var finalDmg := 0
			if unitCd.Dmg > 0:
				print("Applying Damage")
				finalDmg = ((unitCd.Dmg + critDmg) - (def + grzDef))
				outcome[unit][swingIndx].Dmg = finalDmg
				target.apply_dmg(finalDmg)
				print("Dmg: ", finalDmg, " Target HP: ", str(target.activeStats.CurLife))
			else:
				print("No Damage: ", unitCd.Dmg)
			targetCompCost += _factor_combat_composure(unit, target, triggers.WAS_HIT, finalDmg)
			print("Was Hit Comp Loss added: ", target.unitName, " ", targetCompCost)
			for effId in unitEffects.OnHit:
				print("Checking On Hit Effects....")
				outcome[unit][swingIndx].Effects.append(_run_effect(unit, target, effId, actionType, finalDmg))
				unitCompCost += _get_composure_total(unit, outcome[unit][swingIndx].Effects)
				targetCompCost += _get_composure_total(target, outcome[unit][swingIndx].Effects)
				print("Harvesting Effect Comp Loss.... ", unit.unitName, ": ", unitCompCost, " ", target.unitName, ": ", targetCompCost)
			for effId in unitEffects.Always:
				print("Checking Always Effects....")
				outcome[unit][swingIndx].Effects.append(_run_effect(unit, target, effId, actionType, finalDmg))
				unitCompCost += _get_composure_total(unit, outcome[unit][swingIndx].Effects)
				targetCompCost += _get_composure_total(target, outcome[unit][swingIndx].Effects)
				print("Harvesting Effect Comp Loss.... ", unit.unitName, ": ", unitCompCost, " ", target.unitName, ": ", targetCompCost)
		
		if target.activeStats.CurLife <= 0:
			print("Shit dude, it says here ", target.unitName, " is dead.")
			outcome[target][swingIndx].Dead = true
			unitCompCost += _factor_combat_composure(unit, unit, triggers.KILL)
			print("Kill Composure Gain added:", unit.unitName, " ", unitCompCost)
			
		if action.Weapon:
			unit.reduce_durability(weapon)
			
		if action.Weapon and weapon.DUR == 0:
			outcome[unit][swingIndx].Break = true
			unitCompCost += _factor_combat_composure(unit, unit, triggers.BREAK)
			print("Break Composure Loss added: ", unit.unitName, " ", unitCompCost)
			
		if outcome[unit][swingIndx].Effects and outcome[unit][swingIndx].Effects.size() <= 0:
				outcome[unit][swingIndx].Effects = false
				
		outcome[unit][swingIndx].CompLoss = unitCompCost
		unit.apply_composure(unitCompCost)
		if outcome[target][swingIndx].Dead:
			break
		else:
			outcome[target][swingIndx].CompLoss = targetCompCost
			target.apply_composure(targetCompCost)
			
		
	return outcome

func _get_crit_damage(unit) -> int: #GOTCHA BITCH. THERE IS ANOTHER CRIT FUNCTION HERE
	var weapon = unit.get_equipped_weapon()
	var iCat = unit.get_icat(weapon)
	var critDmg : int = 0
	var dmgRange := Global.critRange
	var critMulti : float = 1
	var critEffects = unit.get_crit_dmg_effects()
	
	print("Initial crit range: ", str(dmgRange))
	if iCat.Sub and iCat.Sub == "KNIVES":
		print("It's a knife crit, wew lad")
		dmgRange = Global.knifeCrit
		
	if critEffects.CritDmg:
		print("Applying Crit Effects....")
		dmgRange[0] += critEffects.CritDmg[0]
		dmgRange[1] += critEffects.CritDmg[1]
	
	if critEffects.CritMulti:
		print("Applying multi")
		critMulti = critEffects.CritMulti
	print("Final crit range: ", str(dmgRange))
	critDmg = rng.randi_range(dmgRange[0], dmgRange[1])
	critDmg *= critMulti
	return critDmg
	
	
func get_roll():
	randomize()
	var roll = rng.randi_range(1, 100)
	print("Roll: ", roll)
	return roll

func _get_effects(id) -> Array:
	var effects := []
	var seen := []
	for effId in id.Effects:
		var effect = UnitData.effectData[effId]
		if effect.Target != Enums.EFFECT_TARGET.EQUIPPED and !seen.has(effId):
			effects.append(effId)
		seen.append(effId)
	return effects

func _get_action_effects(unit, action) -> Dictionary:
	var weapon
	var augment
	var skillData = UnitData.skillData
	var itemData = UnitData.itemData
	var unitEffects
	if action.Skill and action.Weapon:
		weapon = itemData[unit.get_equipped_weapon().ID]
		augment = skillData[action.Skill]
		unitEffects = _get_effects(augment)
		unitEffects = unitEffects + _get_effects(weapon)
	elif action.Skill:
		augment = skillData[action.Skill]
		unitEffects = _get_effects(augment)
	elif action.Weapon:
		weapon = itemData[unit.get_equipped_weapon().ID]
		unitEffects = _get_effects(weapon)
	unitEffects = _sort_instant(unitEffects)
	return unitEffects

func _sort_instant(effectArray) -> Dictionary:
	var effects := {"Instant":[], "OnHit":[], "Always":[]}
	for effId in effectArray:
		var effect = UnitData.effectData[effId]
		if effect.Instant:
			effects.Instant.append(effId)
		elif effect.OnHit:
			effects.OnHit.append(effId)
		elif !effect.OnHit:
			effects.Always.append(effId)
	return effects
	
#func _get_swing_count(unit, action) -> int:
	#var swings := 1
	#var unitSwings = unit.get_multi_swing()
	#var unitWeapon = UnitData.itemData[unit.get_equipped_weapon().ID]
	#var weaponSwings := 0
	#if unitWeapon.Effects:
		#for effId in unitWeapon.Effects:
			#if UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.MULTI_SWING and UnitData.effectData[effId].Value > weaponSwings:
				#weaponSwings = UnitData.effectData[effId].Value
	#if unitSwings and unitSwings > weaponSwings and unitSwings > swings:
		#swings = unitSwings
	#elif weaponSwings > swings:
		#swings = weaponSwings
	#return swings
	
func _get_skill_swing_count(skillId):
	var swings := 1
	var skillSwings := 0
	for effId in UnitData.skillData[skillId].Effects:
		if UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.MULTI_SWING and UnitData.effectData[effId].Value > skillSwings:
				skillSwings = UnitData.effectData[effId].Value
	if skillSwings > swings:
		swings = skillSwings
	return swings

#func _get_weapon_swing_count()
	

func _run_effect(actor, target, effId, actionType, dmg = 0):
	var targetCd = target.combatData
	var actorCd = actor.combatData
	var focus : Unit
	#var proc : bool = false
	var result = {"Target": false,"EffectId": effId, "Resisted": false, "Dmg": false, "Heal": false, "Comp": false}
	var effect = UnitData.effectData[effId]
	var chance := 0 
	var type = Enums.EFFECT_TYPE
	
	match effect.Target:
		Enums.EFFECT_TARGET.TARGET: 
			focus = target
			chance = effect.Proc + actorCd.EffHit - targetCd.Resist
		Enums.EFFECT_TARGET.SELF, Enums.EFFECT_TARGET.GLOBAL: 
			focus = actor
			chance = effect.Proc + actorCd.EffHit
	result.Target = focus
	if actionType == ACTION_TYPE.FRIENDLY_SKILL:
		chance = effect.Proc + actorCd.EffHit
			
	if _roll_proc(effect, chance):
		match effect.Type:
			#Need to go through and enable each effect one at a time
			type.TIME: 
				emit_signal("time_factor_changed", " EffectId: ", effId)
			type.BUFF:
				focus.set_buff(effId, effect)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Buffed ", str(effect.SubType), " by +", effect.Value, " for ", effect.Duration, " rounds.")
			type.DEBUFF: 
				#"Debuffs" are resistable, possibly different general FXs, too. Remember this. need resist code.
				focus.set_buff(effId, effect)
				result.Comp = _factor_effect_composure(actor, focus, effId)
				focus.apply_composure(result.Comp)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Buffed ", str(effect.SubType), " by +", effect.Value, " for ", effect.Duration, " rounds.")
			type.STATUS: 
				focus.set_status(effect)
				result.Comp = _factor_effect_composure(actor, focus, effId)
				focus.apply_composure(result.Comp)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Applied Status: ", str(effect.SubType), " for ", effect.Duration, " rounds.")
			type.DAMAGE:
				result.Dmg = _factor_dmg(focus, effect)
				target.apply_dmg(result.Dmg)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Inflicted Damage: ", effect.Value, " HP: ", target.activeStats.CurLife)
			type.HEAL:
				result.Heal = _factor_healing(actor, focus, effect)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				target.apply_heal(result.Heal)
				target.apply_composure(result.Comp)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Healed For: ", result.Heal, " HP: ", target.activeStats.CurLife)
			type.CURE: 
				target.cure_status(effect.SubType)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				target.apply_composure(result.Comp)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Cured Status: ", str(effect.SubType))
			type.RELOC:
				start_relocation(actor, target, effect)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), "Relocation Requested")
			type.LIFE_STEAL:
				result.Heal = _factor_life_steal(focus, effect, dmg)
				result.Comp = _factor_effect_composure(actor, focus, effect, result.Heal)
				focus.apply_heal(result.Heal)
				focus.apply_composure(result.Comp)
				print("Actor: ", actor.unitName, "Target: ", focus.unitName, " EffectId: ",  str(effId), " Life Steal: ", result.Heal, " HP: ", target.activeStats.CurLife)
			#type.ADD_SKILL: pass
			#type.ADD_PASSIVE: pass
			#type.MULTI_SWING: pass
			#type.MULTI_ROUND: pass
			#type.CRIT_BUFF: pass
			#type.SLAYER: pass
	else:
			result.Resisted = true
			print("Actor: ", actor.unitName, "Target: ", focus.unitName, " Resisted: " + str(effId))
	return result

func _roll_proc(effect, chance) -> bool:
	if effect.Proc == -1:
		return true
	elif get_roll() <= chance:
		return true
	return false
	

func start_relocation(actor, target, effect): #determines method of relocation, then passes to the correct type
	var pivotHex
	var matchHex
	var type = effect.SubType
	var reach = effect.Value
	match type:
		type.WARP: emit_signal("warp_selected", actor, target, reach)
		type.SHOVE: 
			pivotHex = target.cell
			matchHex = actor.cell
			shove_or_toss_unit(actor, target, reach, pivotHex, matchHex)
		type.TOSS: 
			pivotHex = actor.cell
			matchHex = target.cell
			shove_or_toss_unit(actor, target, reach, pivotHex, matchHex)
		type.DASH: pass

func shove_or_toss_unit(actor, target, reach, pivotHex, matchHex):
	#Toss: Grab Actor's Cell and Target's Cell. Look through Actor's Neighbors for a match with Target's cell. Adjust position in array to the opposite directional hex and move Target there.
	#Shove: The same principle, except you are searching the Target's neighbors for the Actor's Cell and moving them to the opposite cell of that.

	var neighbors = aHex.get_BFS_nhbr(pivotHex, false, true)
	var shoveResult = aHex.resolve_shove(matchHex, target.cell, neighbors, reach)
	var slamDmg = Global.slamage + actor.activeStats.Pwr + (shoveResult.Travel * 2)
	
	if shoveResult.Slam and !shoveResult.UniColl:
		target.apply_dmg(slamDmg)
		target.relocate_unit(shoveResult.Hex)
	elif shoveResult.Slam:
		target.apply_dmg(slamDmg)
		shoveResult.UniColl.apply_dmg(slamDmg)
		target.relocate_unit(shoveResult.Hex)
	else:
		target.relocate_unit(shoveResult.Hex)
	print("Actor: ", actor.unitName, "Target: ", target.unitName, " Relocated to: ", str(shoveResult.Hex), "Slam? ", str(shoveResult.Slam), " Unit Collision? ", shoveResult.UniColl, " Slamage: ", slamDmg)
		
func warp_to(target, cell):
	target.relocate_unit(cell)

func _factor_dmg(target, effect) -> int:
	var targetCd = target.combatData
	var dmg
	dmg = effect.Value - targetCd.Def[effect.SubType]
	return dmg

func _factor_healing(actor, target, effect) -> int:
	var bonusEff := 0
	#Add checks for bonus effects here
	var statBonus : int
	var healPower : int
	if effect.FromItem:
		statBonus = 0
	else:
		statBonus = actor.activeStats.Mag
	healPower = effect.Value + statBonus + bonusEff
	print("Target Life: ", target.activeStats.CurLife, " Heal:", healPower, " New Life Total: ", target.activeStats.CurLife)
	return healPower


func _factor_life_steal(target, effect, dmg) -> int:
	var bonusEff := 0
	var healPower : int
	healPower = (dmg * effect.Value) + bonusEff
	print("Target Life: ", target.activeStats.CurLife, " Life Steal:", healPower, " New Life Total: ", target.activeStats.CurLife)
	return healPower


func _factor_effect_composure(actor, target, effect, lifeStolen: int = 0) -> int:
	var compLoss := 0
	var targetRes = 1 - (target.combatData.CompRes / 100)
	var actorBonus = 1
	if actor != target:
		actorBonus = 1 + (actor.combatData.CompBonus / 100)
	match effect.Type:
		Enums.EFFECT_TYPE.HEAL:
			compLoss += Global.compCosts.Healed + (effect.Heal / 4)
		Enums.EFFECT_TYPE.CURE:
			compLoss += Global.compCosts.Healed
		Enums.EFFECT_TYPE.DAMAGE:
			compLoss += Global.compCosts.NegEff + (effect.Dmg / 4)
		Enums.EFFECT_TYPE.STATUS:
			if effect.SubType == Enums.SUB_TYPE.SLEEP:
				compLoss -= 1
			else: compLoss += Global.compCosts.NegEff
		Enums.EFFECT_TYPE.LIFE_STEAL:
			compLoss += Global.compCosts.Healed + (lifeStolen / 4)
		_:
			compLoss += Global.compCosts.NegEff
	compLoss = round((compLoss * actorBonus) * targetRes)
	return compLoss

func _factor_combat_composure(actor, target, type, dmg := 0) -> int: ##Pass Skill Cost through dmg
	var compLoss := 0
	var targetRes = 1 - (target.combatData.CompRes / 100)
	var actorBonus = 1
	if actor != target:
		actorBonus = 1 + (actor.combatData.CompBonus / 100)
	match type:
		Enums.COMP_TRIGGERS.ATTACK:
			compLoss += Global.compCosts.Attack
		Enums.COMP_TRIGGERS.WAS_HIT:
			compLoss += Global.compCosts.WasHit + (dmg / 4)
		Enums.COMP_TRIGGERS.MISS:
			compLoss += Global.compCosts.Miss
		Enums.COMP_TRIGGERS.DODGE:
			compLoss += Global.compCosts.Dodge
		Enums.COMP_TRIGGERS.SKILL:
			compLoss += dmg
		Enums.COMP_TRIGGERS.CRIT:
			compLoss += Global.compCosts.Crit
		Enums.COMP_TRIGGERS.KILL:
			compLoss += Global.compCosts.Kill
		Enums.COMP_TRIGGERS.BREAK:
			compLoss += Global.compCosts.Break
	compLoss = round((compLoss * actorBonus) * targetRes)
	return compLoss
	
func _get_composure_total(unit, results):
	var compLoss := 0
	for result in results:
		if result.Target == unit and result.Comp:
			compLoss += result.Comp
	return compLoss
	
func use_item(unit, target, invItem):
	var itemData = UnitData.itemData
	var actionType = ACTION_TYPE.FRIENDLY_SKILL
	var item = itemData[invItem.ID]
	var results = []
	var compChange = 0
	for effId in item.Effects:
		var effect = UnitData.effectData[effId]
		results = results +  _run_effect(unit, target, effect, actionType)
	compChange += _get_composure_total(unit, results)
	print("Harvesting Effects Comp Loss.... ", unit.unitName, ": ", compChange)
	unit.apply_composure(compChange)
	unit.reduce_durability(item)




