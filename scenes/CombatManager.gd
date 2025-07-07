extends Node
class_name CombatManager
#signal combat_resolved
signal time_factor_changed
signal warp_selected

var ACTION_TYPE = Enums.ACTION_TYPE
var rng = Global.rng
var fcData : Dictionary
var fateChance = 15

#var canReach = false
var gameBoard

func init_manager():
	#link up dependancies
	gameBoard = get_parent()

#FORECAST FUNCTIONS
	##fcData Heirarchy
	##fcData
	##	[Unit]
	##		skill
	##		Initiator
	##		combat
	##			CanMiss
	##			CanDmg
	##			CanCrit
	##			Hit
	##			DMG
	##			Barrier
	##			BarrierPRC
	##			CRIT
	##			FUP
	##			RLife
	##		effects
	##			ID
	##				PROC
	##		Swings
	##		Counter
	##		Reach
func get_forecast(a: Unit, t: Unit, action:Dictionary) -> Dictionary: #HERE Augments not implemented!!!
	var op : Unit
	var isSelf := false
	fcData = {a:{},t:{}}

	
	fcData[a]["Skill"] = action.Skill
	fcData[a]["Item"] = action.Item
	fcData[a]["Initiator"] = true
	if a == t:
		isSelf = true
	else:
		fcData[t]["Skill"] = null
		fcData[t]["Item"] = null
		fcData[t]["Initiator"] = false
	
	for unit : Unit in fcData:
		match fcData[unit].Initiator:
			true: 
				op = t
				fcData[unit]["Counter"] = true
				fcData[unit]["Reach"] = true
			false: 
				op = a
				if _get_action_type(unit,op,action) == ACTION_TYPE.FRIENDLY_SKILL: fcData[unit]["Counter"] = false
				##need check for friendly 'retaliate' passives here
				else: fcData[unit]["Counter"] = unit.can_act()
				fcData[unit]["Reach"] = _reach_check(a, t)
		
		fcData[unit]["Combat"] = _evaluate_clash(unit, op, action)
		var special : SlotWrapper
		if fcData[unit].Item: special = fcData[unit].Item
		else: special = fcData[unit].Skill
		fcData[unit]["Effects"] = _evaluate_effects(unit, op,special)
		
		if fcData[unit].Skill:
			fcData[unit]["Swings"] = _get_skill_swing_count(action.Skill)
		else:
			fcData[unit]["Swings"] = unit.get_multi_swing()
			
		if fcData[unit].Effects:
			for effect in fcData[unit].Effects:
				if fcData[unit].Effects[effect].Slayer:
					fcData[unit].Combat.Dmg *= Global.slayerMulti
					break
			
		if isSelf:
			break
		
			
	for unit in fcData:
		var swings = false
		match fcData[unit].Initiator:
			true: op = t
			false: op = a
		if fcData[unit].Swings:
			swings = fcData[unit].Swings
		if fcData[unit].Combat.CanDmg and fcData[unit].Reach and fcData[unit].Counter:
			fcData[op].Combat["Rlife"] = _get_remaining_life(op, fcData[unit].Combat.Dmg, swings)
		if isSelf:
			break
	SignalTower.emit_signal("forecast_predicted", fcData)
	return fcData


func _evaluate_effects(a: Unit, t: Unit, skill :SlotWrapper= null): ##returns proc chances of each effect on a skill or weapon. Returns false if there are none.
	#HERE
	#Only considers effects with Target: "Target", some "Self" effects may be relevant.
	#Does not consider "effect" damage, "Skill" damage is handled in _evaluate_clash()
	
	#need updating after effect handling is finished. Also lacks "action" compatability
	var attack :SlotWrapper
	var chance : int = a.combatData.EffHit
	var resist : int = t.combatData.Resist
	var results : Dictionary = {}
	
	if skill:
		attack = skill
	else:
		attack = a.get_equipped_weapon()
	if attack.effects.size() < 0: return false
	
	for effect in attack.effects:
		var value = effect.value
		results[effect] = {}
			
		if effect.target != Enums.EFFECT_TARGET.TARGET:
			results[effect]["Self"] = true
		else: results[effect]["Self"] = false
		
		if effect.proc == -1:
			results[effect]["Proc"] = false
		elif results[effect].Self:
			results[effect]["Proc"] = chance + effect.proc
			results[effect].Proc = clampi(results[effect].Proc, 0, 100)
		else:
			results[effect]["Proc"] = (chance + effect.proc) - resist
			results[effect].Proc = clampi(results[effect].Proc, 0, 100)
			
		if value and effect.type == Enums.EFFECT_TYPE.DAMAGE:
			results[effect]["Value"] = _factor_dmg(t, effect)
		elif value and effect.type == Enums.EFFECT_TYPE.HEAL:
			results[effect]["Value"] = _factor_healing(a, t, effect)
		elif typeof(value) == Variant.Type.TYPE_FLOAT:
			var v = value * 100
			v = round(v)
			results[effect]["Value"] = v
		else:
			results[effect]["Value"] = value
			
		if effect.type == Enums.EFFECT_TYPE.SLAYER and effect.sub_rule == t.SPEC_ID:
			results[effect]["Slayer"] = true
		else: results[effect]["Slayer"] = false
			
	
	if results.size() > 0:
		return results
	else:
		return false


func _evaluate_clash(a:Unit, t:Unit, action:Dictionary) -> Dictionary:
	var results := {}
	var aData
	var tData := t.combatData
	var tAct := t.active_stats
	var special : SlotWrapper
	
	if action.Item: 
		special = action.Item
		aData = a.get_skill_combat_stats(special, action.Weapon)
	elif !action.Skill:
		aData = a.combatData
	else:
		special = action.Skill
		aData = a.get_skill_combat_stats(special, action.Weapon)
		
	
	if special:
		results["CanMiss"] = special.can_miss
	else: results["CanMiss"] = true
	results["Hit"] = aData.Hit - tData.Graze
	results.Hit = clampi(results.Hit, 0, 1000)
	
	if special and !special.can_dmg:
		results["CanDmg"] = false
	else:
		var d := 0
		results["CanDmg"] = true
		match aData.Type:
			Enums.DAMAGE_TYPE.PHYS:
				d = tAct.Def
			Enums.DAMAGE_TYPE.MAG:
				d = tAct.Mag
			Enums.DAMAGE_TYPE.TRUE:
				pass
		results["Dmg"] = aData.Dmg - d
		results.Dmg = clampi(results.Dmg, 0, 1000)
		
	if special and !special.can_crit:
		results["CanCrit"] = false
	else:
		results["CanCrit"] = true
		results["Crit"] = aData.Crit - tData.Luck
		results.Crit = clampi(results.Crit, 0, 1000)
	
	if !special:
		results["Barrier"] = clampi(results.Dmg - tData.Barrier,0,1000)
		results["BarPrc"] = tData.BarPrc
	else:
		results["Barrier"] = false
		results["BarPrc"] = false
		
		
	if _speed_check(a, t) and !special:
		results["FUP"] = true
	else:
		results["FUP"] = false
	return results


func _get_remaining_life(unit, dmg, swings = false):
	var rLife
	if swings:
		dmg = dmg * (1 + swings)
	rLife = unit.active_stats.CurLife - dmg
	rLife = clampi(rLife, 0, 1000)
	return rLife


func _reach_check(unit, target) -> bool:
	var tWep = target.get_equipped_weapon()
	var minR = tWep.min_reach
	var maxR = tWep.max_reach
	var hexStar = AHexGrid2D.new(Global.flags.CurrentMap)
	var distance = hexStar.find_distance(unit.cell, target.cell)
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
	var actionType
	var vantage = false
	var deathMatch = false
	var wepAction := {"Weapon": true, "Skill": false}
	var combatResults : Dictionary = {}
	print("That really sick Thracia defense combat music")
	##check type, no need for deathMatch or vantage with friendly skills, or an opponent that can't even reach
	if _get_action_type(attacker, defender, attackerAction) != ACTION_TYPE.FRIENDLY_SKILL and _reach_check(defender, attacker) and attacker.can_act():
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
	actionType = _get_action_type(initiator, initiate, initiatorAct)
	#check for friendly response skill from initiate?
	
	combatResults["CombatType"] = actionType
	combatResults["DeathMatch"] = deathMatch
	combatResults["Vantage"] = vantage
	combatResults["StartingCondition"] = {initiator:initiator.get_condition()}
	combatResults["StartingCondition"] = {initiate:initiate.get_condition()}
	combatResults["Rounds"] = {}
	##Begin combat rounds
	for r in range(0, maxRounds):
		var lastAct
		initiator.update_stats()
		initiate.update_stats()
		##Initiator Acts
		combatResults.Rounds[r] = {}
		
		if r > 0:
			initiatorAct = wepAction
			
		if initiator.can_act():
			actionType = _get_action_type(initiator, initiate, initiatorAct)
			combatResults.Rounds[r][0] = _run_action(initiator, initiate, initiatorAct, actionType, true).duplicate(true)
			lastAct = combatResults.Rounds[r][0][initiator]
			print(str(initiator) + ": " + ("Action" + str(0) + ": ") + str(combatResults.Rounds[r][0]))
		else:
			break
			
		if _validate_response(initiate, initiator, lastAct, deathMatch, actionType) and _reach_check(initiate, initiator):
			actionType = _get_action_type(initiate, initiator, initiateAct)
			combatResults.Rounds[r][1]  = _run_action(initiate, initiator, initiateAct, actionType, false).duplicate(true)
			lastAct = combatResults.Rounds[r][1][initiate]
			print(str(initiator) + ": " + ("Action" + str(1) + ": ") + str(combatResults.Rounds[r][1]))
		else: continue
			
		if _validate_response(initiator, initiate, lastAct, false, actionType) and _speed_check(initiator, initiate) and initiatorAct.Weapon:
			actionType = _get_action_type(initiator, initiate, initiatorAct)
			combatResults.Rounds[r][2]  = _run_action(initiator, initiate, initiatorAct, actionType, true).duplicate(true)
			print(str(initiator) + ": " + ("Action" + str(2) + ": ") + str(combatResults.Rounds[r][2]))
			
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
	var deathMatch = unit.get_multi_round()
	if !action.Skill or deathMatch:
		return deathMatch
	for effect in action.Skill.effects:
		if effect.type == Enums.EFFECT_TYPE.MULTI_ROUND:
			deathMatch = effect.value
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
			for effResult in lastAct[swing].Effects:
				if !effResult.Resisted and !deathMatch:
					print("Failed. Effect not Resisted: ", str(effResult.id))
					return false
	print("Success, all checks passed.")
	return true


func _speed_check(unit1, unit2) -> bool:
	
	var unit1Spd = unit1.active_stats.Cele
	var unit2Spd = unit2.active_stats.Cele
	print("Checking speed... ","Unit1 Spd: ", unit1Spd, " Required Spd: ", str(unit2Spd+Global.spdGap))
	if unit1Spd >= (unit2Spd + Global.spdGap):
		print("Passed, follow-up allowed")
		return true
	print("Failed")
	return false

func _run_action(unit:Unit, target:Unit, action:Dictionary, actionType, _isInitiator:bool) -> Dictionary: ##Augment functionality and passiveProcs not implemented yet
	var unitCd : Dictionary 
	var targetCd : Dictionary = target.combatData
	#var augment : Dictionary
	var DRes : int
	var critDmg : int = 0
	var grzDef : int = 0
	var slayerMulti := 1
	var weapon : Weapon
	var unitEffects : Dictionary[String,Array]
	var multiSwing = false
	var swings = 1
	var outcome : Dictionary = {}
	var swingIndx : String
	var unitCompCost := 0
	var targetCompCost := 0
	var triggers = Enums.COMP_TRIGGERS
	var fate = unit.search_passive_id(Enums.PASSIVE_TYPE.FATED)
	var special : SlotWrapper
	
	print("Running Action....")
	if action.Skill:
		special = action.Skill
		unitCompCost += _factor_combat_composure(unit, unit, triggers.SKILL, special.cost)
		print("skill Cost comp loss added: ",unit.unit_name, " ", unitCompCost)
		multiSwing = _get_skill_swing_count(special)
	elif action.Item:
		special = action.Item
		unitCompCost += _factor_combat_composure(unit, unit, triggers.SKILL, special.cost) # this isn't being used correctly
		print("ofuda Cost comp loss added: ",unit.unit_name, " ", unitCompCost)
		#multiSwing = _get_skill_swing_count(special)
	else:
		multiSwing = unit.get_multi_swing()
	
	if multiSwing:
		swings = multiSwing
	print("Swing Count: ", swings)
	for swing in swings:
		if !special:
			unitCompCost += _factor_combat_composure(unit, unit, triggers.ATTACK)
			print("Basic attack comp loss added: ",unit.unit_name, " ", unitCompCost)
		swingIndx = ("Swing" + str(swing))
		print(str(swingIndx))
		outcome[unit] = {swingIndx:{"ActionType": actionType, "Hit" : false, "CompLoss": 0, "Dmg" : 0, "Crit" : 0, "Skill" : special, "PassiveProc" : [], "Instant" : [], "Effects" : [], "Break" : false, "Slayer" : 0}}
		outcome[target] = {swingIndx:{"Barrier" : 0, "CompLoss": 0, "PassiveProc" : [], "Effects" : [], "Dead" : false,}}
		
		if special and action.Weapon:
			unitCd = unit.get_skill_combat_stats(special, true)
			weapon = unit.get_equipped_weapon()
		elif special: unitCd = unit.get_skill_combat_stats(special)
		elif action.Weapon:
			unitCd = unit.combatData
			weapon = unit.get_equipped_weapon()
			
		unitEffects = _get_action_effects(unit, action)
		
		for effect in unitEffects.Instant:
			print("Checking Instant Effects....")
			var effectResult = [_run_effect(unit, target, effect, actionType)]
			outcome[unit][swingIndx].instant = outcome[unit][swingIndx].instant + effectResult
			#outcome[unit][swingIndx].PassiveProc.append(effect)
			if effectResult[0].Slayer:
				slayerMulti = Global.slayerMulti
		#check units passive procs
		
		#determine DRes used
		DRes = targetCd.DRes[unitCd.Type]

		
		
		
		#check accuracy
		print("Rolling for Hit. Chance: ", str(unitCd.Hit - targetCd.Graze))
		if special and !special.can_miss:
			outcome[unit][swingIndx].Hit = true
			print("Was True Hit")
		elif get_roll() <= unitCd.Hit - targetCd.Graze:
			outcome[unit][swingIndx].Hit = true
			print("Hit Success")
		elif fate and get_roll() <= fate.value:
			outcome[unit][swingIndx].Hit = true
			outcome[unit][swingIndx].PassiveProc.append(fate)
			print("Fated Hit!")
		else:
			print("Missed")
			unitCompCost += _factor_combat_composure(unit, unit, triggers.MISS)
			print("Attack Miss comp loss added: ",unit.unit_name, " ", unitCompCost)
			targetCompCost += _factor_combat_composure(unit, target, triggers.DODGE)
			print("Attack Dodge comp loss added: ",target.unit_name, " ", targetCompCost)
			
		
		if !outcome[unit][swingIndx].Hit:
			for effect in unitEffects.Always:
				outcome[unit][swingIndx].Effects = outcome[unit][swingIndx].Effects + _run_effect(unit, target, effect, actionType)
			#if outcome[unit][swingIndx].Effects and outcome[unit][swingIndx].Effects.size() <= 0:
				#outcome[unit][swingIndx].Effects = false
			if outcome[unit][swingIndx].Effects:
				unitCompCost += _get_composure_total(unit, outcome[unit][swingIndx].Effects)
				targetCompCost += _get_composure_total(target, outcome[unit][swingIndx].Effects)
			return outcome
			
		#check for Barrier
		print("Rolling for Barrier. Chance: ", str(targetCd.BarPrc))
		if actionType != ACTION_TYPE.FRIENDLY_SKILL and get_roll() <= targetCd.BarPrc:
			grzDef = targetCd.Barrier
			
			print("Barrierd. Barrier Reduction: ", grzDef)
		else:
			print("Barrier Failed")
		
		#check for crit
		
		if special and !special.can_crit:
			pass
		elif  get_roll() <= unitCd.Crit - targetCd.Luck:
			print("Rolling for Crit. Chance: ", str(unitCd.Crit - targetCd.Luck))
			critDmg = _get_crit_damage(unit)
			print("Crit Success. Crit Dmg: ", critDmg)
			unitCompCost += _factor_combat_composure(unit, unit, triggers.CRIT)
			print("Critically Hitting Comp Gain added: ", unit.unit_name, " ", unitCompCost)
		else: print("Crit Failed")
			
		#determine damage outcome
		if outcome[unit][swingIndx].Hit:
			print("Target HP: ", str(target.active_stats.CurLife))
			
			var finalDmg := 0
			unitCd.Dmg = clampi(unitCd.Dmg, 0, 9999)
			if special and !special.can_dmg:
				print("No Damage: ", unitCd.Dmg)
			else:
				print("Applying Damage")
				var finalBarrier = grzDef + roundi(critDmg/2)
				if slayerMulti > 1:
					outcome[unit][swingIndx].Slayer = slayerMulti
				if critDmg and grzDef:
					outcome[target][swingIndx].Barrier = finalBarrier
					outcome[unit][swingIndx].Crit = critDmg
				elif grzDef:
					outcome[target][swingIndx].Barrier = grzDef
				elif critDmg:
					outcome[unit][swingIndx].Crit = critDmg
					
				finalDmg = (((unitCd.Dmg + critDmg) - (DRes + finalBarrier)) * slayerMulti)
				finalDmg = clampi(finalDmg, 0, 9999)
				outcome[unit][swingIndx].Dmg = finalDmg
				target.apply_dmg(finalDmg, unit)
				print("Dmg: ", finalDmg, " Target HP: ", str(target.active_stats.CurLife))
			
			if actionType != ACTION_TYPE.FRIENDLY_SKILL:
				targetCompCost += _factor_combat_composure(unit, target, triggers.WAS_HIT, finalDmg)
				print("Was Hit Comp Loss added: ", target.unit_name, " ", targetCompCost)
			for effect in unitEffects.OnHit:
				print("Checking On Hit Effects....")
				outcome[unit][swingIndx].Effects.append(_run_effect(unit, target, effect, actionType, finalDmg))
				
			for effect in unitEffects.Always:
				print("Checking Always Effects....")
				outcome[unit][swingIndx].Effects.append(_run_effect(unit, target, effect, actionType, finalDmg))
			if outcome[unit][swingIndx].Effects:
				unitCompCost += _get_composure_total(unit, outcome[unit][swingIndx].Effects)
				targetCompCost += _get_composure_total(target, outcome[unit][swingIndx].Effects)
				print("Harvesting Effect Comp Loss.... ", unit.unit_name, ": ", unitCompCost, " ", target.unit_name, ": ", targetCompCost)
		
		if target.active_stats.CurLife <= 0:
			print("Shit dude, it says here ", target.unit_name, " is dead.")
			outcome[target][swingIndx].Dead = true
			unitCompCost += _factor_combat_composure(unit, unit, triggers.KILL)
			print("Kill Composure Gain added:", unit.unit_name, " ", unitCompCost)
			
		if action.Weapon:
			unit.reduce_durability(weapon)
			
		if action.Weapon and weapon.dur == 0:
			outcome[unit][swingIndx].Break = true
			unitCompCost += _factor_combat_composure(unit, unit, triggers.BREAK)
			print("Break Composure Loss added: ", unit.unit_name, " ", unitCompCost)
			
				
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
	
	print("Initial crit reach: ", str(dmgRange))
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
	print("Final crit reach: ", str(dmgRange))
	critDmg = rng.randi_range(dmgRange[0], dmgRange[1])
	critDmg *= critMulti
	return critDmg
	
	
func get_roll():
	randomize()
	var roll = rng.randi_range(1, 100)
	print("Roll: ", roll)
	return roll

func _get_effects(res:SlotWrapper) -> Array[Effect]:
	var effects :Array[Effect]= []
	var seen :Array[Effect]= []
	for effect in res.effects:
		if effect.target != Enums.EFFECT_TARGET.EQUIPPED and !seen.has(effect):
			effects.append(effect)
		seen.append(effect)
	return effects

func _get_action_effects(unit:Unit, action:Dictionary) -> Dictionary[String,Array]:
	var weapon
	var augment
	var unitEffects : Array[Effect]
	if action.Skill and action.Weapon:
		weapon = unit.get_equipped_weapon()
		augment = action.Skill
		unitEffects = _get_effects(augment)
		unitEffects += _get_effects(weapon)
	elif action.Skill: unitEffects = _get_effects(action.Skill)
	elif action.Item: unitEffects = _get_effects(action.Item)
	elif action.Weapon: unitEffects = _get_effects(unit.get_equipped_weapon())
	return _sort_instant(unitEffects)

func _sort_instant(effectArray:Array[Effect]) -> Dictionary[String,Array]:
	var effects :Dictionary[String,Array]= {"Instant":[], "OnHit":[], "Always":[]}
	for effect:Effect in effectArray:
		if effect.instant:
			effects.Instant.append(effect)
		elif effect.on_hit:
			effects.OnHit.append(effect)
		elif !effect.on_hit:
			effects.Always.append(effect)
	return effects


func _get_skill_swing_count(skill):
	var swings := 1
	var skillSwings := 0
	for effect in skill.effects:
		if effect.type == Enums.EFFECT_TYPE.MULTI_SWING and effect.value > skillSwings:
				skillSwings = effect.value
	if skillSwings > swings:
		swings = skillSwings
	return swings

#func _get_weapon_swing_count()
	

func _run_effect(actor:Unit, target:Unit, effect:Effect, actionType:Enums.ACTION_TYPE, dmg := 0):
	var targetCd = target.combatData
	var actorCd = actor.combatData
	var focus : Unit
	#var proc : bool = false
	var result = {"Actor":false,"Type":false, "Target": false,"EffectId": effect, "Resisted": false, "Dmg": dmg, "Heal": false, "Comp": false, "Slayer": false}
	var chance := 0 
	var type = Enums.EFFECT_TYPE
	
	
	match effect.target:
		Enums.EFFECT_TARGET.TARGET: 
			focus = target
			chance = effect.proc + actorCd.EffHit - targetCd.Resist
		Enums.EFFECT_TARGET.SELF, Enums.EFFECT_TARGET.GLOBAL: 
			focus = actor
			chance = effect.proc + actorCd.EffHit
	result.Target = focus
	result.Actor = actor
	result.Type = effect.type
	if actionType == ACTION_TYPE.FRIENDLY_SKILL:
		chance = effect.proc + actorCd.EffHit
			
	if _roll_proc(effect, chance) or effect.proc == -1:
		match effect.type:
			
			type.TIME:
				emit_signal("time_factor_changed", " EffectId: ", effect)
			type.BUFF:
				focus.set_buff(effect)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Buffed ", str(effect.sub_type), " by +", effect.value, " for ", effect.duration, " rounds.")
			type.DEBUFF: 
				#"Debuffs" are resistable, possibly different general FXs, too. Remember this. need resist code.
				focus.set_buff(effect)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				focus.apply_composure(result.Comp)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Buffed ", str(effect.sub_type), " by +", effect.value, " for ", effect.duration, " rounds.")
			type.STATUS: 
				focus.set_status(effect)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				focus.apply_composure(result.Comp)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Applied Status: ", str(effect.sub_type), " for ", effect.duration, " rounds.")
			type.DAMAGE:
				result.Dmg += _factor_dmg(focus, effect)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				target.apply_dmg(result.Dmg, actor)
				target.apply_composure(result.Comp)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Inflicted Damage: ", effect.value, " HP: ", target.active_stats.CurLife)
			type.HEAL:
				result.Heal = _factor_healing(actor, focus, effect)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				target.apply_heal(result.Heal)
				target.apply_composure(result.Comp)
				
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Healed For: ", result.Heal, " HP: ", target.active_stats.CurLife)
			type.CURE:
				target.cure_status(effect.sub_type)
				result.Comp = _factor_effect_composure(actor, focus, effect)
				target.apply_composure(result.Comp)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Cured Status: ", str(effect.sub_type))
			type.RELOC:
				#start_relocation(actor, focus, effect)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), "Relocation Requested")
			type.LIFE_STEAL:
				result.Heal = _factor_life_steal(focus, effect, dmg)
				result.Comp = _factor_effect_composure(actor, focus, effect, result.Heal)
				focus.apply_heal(result.Heal)
				focus.apply_composure(result.Comp)
				print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " EffectId: ",  str(effect), " Life Steal: ", result.Heal, " HP: ", target.active_stats.CurLife)
			#type.ADD_SKILL: pass
			#type.ADD_PASSIVE: pass
			#type.MULTI_SWING: pass
			#type.MULTI_ROUND: pass
			#type.CRIT_BUFF: pass
			type.SLAYER: 
				result.Slayer = _validate_slayer(focus, effect)
				result.Resisted = !result.Slayer
		gameBoard.add_post_queue(result.duplicate())
	else:
			result.Resisted = true
			print("Actor: ", actor.unit_name, "Target: ", focus.unit_name, " Resisted: " + str(effect))
	return result

func _roll_proc(effect, chance) -> bool:
	if effect.proc == -1:
		return true
	elif get_roll() <= chance:
		return true
	return false
	

func start_relocation(actor, target, effect): #determines method of relocation, then passes to the correct type
	var pivotHex
	var matchHex
	var type = Enums.SUB_TYPE
	var reach = effect.value
	match effect.sub_type:
		type.WARP: emit_signal("warp_selected", actor, target, reach)
		type.SHOVE: 
			pivotHex = target.cell
			matchHex = actor.cell
			shove_or_toss_unit(actor, target, reach, pivotHex, matchHex)
		type.TOSS: 
			pivotHex = actor.cell
			matchHex = target.cell
			shove_or_toss_unit(actor, target, reach, pivotHex, matchHex, 1)
		type.DASH: pass

func shove_or_toss_unit(actor, target, reach, pivotHex, matchHex, mode = 0):
	#Toss:[1] Grab Actor's Cell and Target's Cell. Look through Actor's Neighbors for a match with Target's cell. Adjust position in array to the opposite directional hex and move Target there.
	#Shove:[0] The same principle, except you are searching the Target's neighbors for the Actor's Cell and moving them to the opposite cell of that.
	var aHex = AHexGrid2D.new(gameBoard.currMap)
	var neighbors = aHex.get_BFS_nhbr(pivotHex, true)
	var shoveResult = aHex.resolve_shove(matchHex, target.cell, neighbors, reach)
	var slamDmg = Global.slamage + actor.active_stats.Pwr + (shoveResult.Travel * 2)
	
	
	if shoveResult.Slam and !shoveResult.UniColl:
		target.apply_dmg(slamDmg, actor)
	elif shoveResult.Slam:
		target.apply_dmg(slamDmg, actor)
		shoveResult.UniColl.apply_dmg(slamDmg, actor)
	
	match mode:
		0: target.shove_unit(shoveResult.Hex)
		1: target.toss_unit(shoveResult.Hex)
	
	print("Actor: ", actor.unit_name, "Target: ", target.unit_name, " Relocated to: ", str(shoveResult.Hex), "Slam? ", str(shoveResult.Slam), " Unit Collision? ", shoveResult.UniColl, " Slamage: ", slamDmg)
		
func warp_to(target, cell):
	target.relocate_unit(cell)

func _factor_dmg(target, effect) -> int:
	var targetCd = target.combatData
	var dmg
	dmg = effect.value - targetCd.DRes[effect.sub_type]
	return dmg

func _factor_healing(actor, target, effect) -> int:
	var bonusEff := 0
	#Add checks for bonus effects here
	var statBonus : int
	var healPower : int
	if effect.from_item:
		statBonus = 0
	else:
		statBonus = actor.active_stats.Mag
	healPower = effect.value + statBonus + bonusEff
	print("Target Life: ", target.active_stats.CurLife, " Heal:", healPower, " New Life Total: ", target.active_stats.CurLife)
	return healPower


func _factor_life_steal(target, effect, dmg) -> int:
	var bonusEff := 0
	var healPower : int
	healPower = (dmg * effect.value) + bonusEff
	print("Target Life: ", target.active_stats.CurLife, " Life Steal:", healPower, " New Life Total: ", target.active_stats.CurLife)
	return healPower


func _factor_effect_composure(actor, target, effect, lifeStolen: int = 0) -> int:
	var compLoss := 0
	var targetRes = 1 - (target.combatData.CompRes / 100)
	var actorBonus = 1
	if actor != target:
		actorBonus = 1 + (actor.combatData.CompBonus / 100)
	match effect.type:
		Enums.EFFECT_TYPE.HEAL:
			compLoss += Global.compCosts.Healed + (effect.value / 4)
		Enums.EFFECT_TYPE.CURE:
			compLoss += Global.compCosts.Healed
		Enums.EFFECT_TYPE.DAMAGE:
			compLoss += Global.compCosts.NegEff + (effect.value / 4)
		Enums.EFFECT_TYPE.STATUS:
			if effect.sub_type == Enums.SUB_TYPE.SLEEP:
				compLoss -= 1
			else: compLoss += Global.compCosts.NegEff
		Enums.EFFECT_TYPE.LIFE_STEAL:
			compLoss += Global.compCosts.Healed + roundi(lifeStolen / 4)
		_:
			compLoss += Global.compCosts.NegEff
	compLoss = round((compLoss * actorBonus) * targetRes)
	return compLoss

func _factor_combat_composure(actor, target, type, dmg := 0) -> int: ##Pass skill Cost through dmg
	var compLoss := 0
	var targetRes = 1 - (target.combatData.CompRes / 100)
	var actorBonus = 1
	if actor != target:
		actorBonus = 1 + (actor.combatData.CompBonus / 100)
	match type:
		Enums.COMP_TRIGGERS.ATTACK:
			compLoss += Global.compCosts.Attack
		Enums.COMP_TRIGGERS.WAS_HIT:
			compLoss += Global.compCosts.WasHit + roundi(dmg / 4)
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
	
func use_item(unit:Unit, target:Unit, item:Item) -> Array: #not exactly finished. Missing support for user feed back on all item types.
	var actionType = _get_action_type(unit, target, {"Weapon": false, "Skill": false})
	var results = []
	var compChange = 0
	
	for effect in item.effects:
		results.append(_run_effect(unit, target, effect, actionType))
	compChange += _get_composure_total(unit, results)
	print("Harvesting Effects Comp Loss.... ", unit.unit_name, ": ", compChange)
	unit.apply_composure(compChange)
	unit.reduce_durability(item)
	return results

func _validate_slayer(target, effect):
	var rule = effect.sub_rule
	var species = target.SPEC_ID
	#HERE effective immunity check goes here later
	if rule == species:
		return true
	return false
