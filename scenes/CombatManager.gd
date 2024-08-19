extends Node
class_name CombatManager
signal combat_resolved
signal time_factor_changed
signal warp_selected
signal jobs_done_cmbtmnger
#var fData : Dictionary
#var cbtUD : Array
#var cbtCL : Array
#var cbtAW : Array
var rng = Global.rng
var fData = {}
#var aWep
#var tWep
var fateChance = 15

@onready var skillData = UnitData.skillData
@onready var effectData = UnitData.effectData
@onready var itemData = UnitData.itemData
#var canReach = false
var gameBoard
var aHex

func init_manager():
	#link up dependancies
	gameBoard = get_parent()
	aHex = gameBoard.hexStar

func _ready():
	var parent = get_parent()
	self.jobs_done_cmbtmnger.connect(parent._on_jobs_done)
	emit_signal("jobs_done_cmbtmnger", "CmbtMngr", self)


	
func get_forecast(a: Unit, t: Unit, distance, skill = null): #Skill not reimplimented yet
	var itemData = UnitData.itemData
	var aWep = a.get_equipped_weapon()
	var tWep = t.get_equipped_weapon()
	var minR = itemData[tWep.DATA].MINRANGE
	var maxR = itemData[tWep.DATA].MAXRANGE
	if skill != null:
		pass
	fData = {a:{},t: {}}
	fData[a] = _evaluate_clash(a, t)
	fData[t] = _evaluate_clash(t, a)
	fData[t]["reach"] = _distance_check(minR, maxR, distance)
	return fData

func _distance_check(minR, maxR, distance):
	var canReach = false
	if distance >= minR and distance <= maxR: #Not Checked yet
		canReach = true
	return canReach
	
func _evaluate_clash(a, t):
	var results = {}
	var aData = a.combatData
	var tData = t.combatData
	var aAct = a.activeStats
	var tAct = t.activeStats
	results["ACC"] = aData.ACC - tData.AVOID
	results.ACC = clampi(results.ACC, 0, 1000)
	if aData.TYPE == "Physical":
		results["DMG"] = aData.DMG - tAct.BAR
		
	else:
		results["DMG"] = aData.DMG - tAct.MAG
	results.DMG = clampi(results.DMG, 0, 1000)
	results["GRAZE"] = results.DMG - tData.GRAZE
	results["GRZPRC"] = tData.GRZPRC
	results["CRIT"] = aData.CRIT - tData.CRTAVD
	results.CRIT = clampi(results.CRIT, 0, 1000)
	if aAct.CELE > tAct.CELE + 4:
		results["FUP"] = true
	else:
		results["FUP"] = false
	results["RLIFE"] = _get_remaining_life(a, results.DMG)
	return results
	
func _get_remaining_life(a, dmg):
	var rLife
	rLife = a.activeStats.CLIFE - dmg
	rLife = clampi(rLife, 0, 1000)
	return rLife
	
func start_the_justice(a: Unit, t: Unit):
	var aActive = a.activeStats
	var tActive = t.activeStats
	var aLife = a.activeStats.CLIFE
	var tLife = t.activeStats.CLIFE
	
	var aWep = a.get_equipped_weapon()
	var tWep = t.get_equipped_weapon()
	
	var canReach = fData[t].reach
	
	var hurt = false
	var dmg = 0
	var r1 = false
	var r2 = false
	var r3 = false
#	var r4 = false
	var deathFlag = false
	var canRetaliate = true
	
	#round 1
	#check for accuracy
	#if it's a hit, get the damage
	#if the damage was 0 or the attack failed, start round 2
	#check for accuracy
	#if it's a hit, get the damage
	#check the accuracy and DMG of r2
	#if it failed, or did 0 dmg. check both units for FUP true
	#start round 3 for whoever had FUP true, if any
	#conclude combat
	
	
	
	if t.activeStatus.Sleep.Active or tWep.DATA == "NONE" or !canReach:
		canRetaliate = false
	
	
	#first round
	print("Girl's are fighting")
	print("Round 1 begins: ", a.unitName, " is attacking ", t.unitName)
	r1 = get_attack(a, t)
	if r1 and check_uses(aWep) and !deathFlag: 
		dmg = combat_round(a, t) #redo forecast dictionary to use unit as keys so dmg can be applied to the unit and unit can be put here instead of these keys
		_reduce_durability(a, aWep)
		if dmg != 0:
			t.apply_dmg(dmg)
			hurt = true
		if t.activeStats.CLIFE <= 0:
			deathFlag = true
		#if deathFlag and t.faction == "Player":
			#t.killXP = true
			
			
	if !hurt and !deathFlag and canRetaliate and check_uses(tWep):
		print("Round 2 begins: ", t.unitName, " is attacking ", a.unitName)
		r2 = get_attack(t,a)
	if r2:
		dmg = combat_round(t, a)
		_reduce_durability(t, tWep)
		if dmg != 0:
			t.apply_dmg(dmg)
			hurt = true
		if t.activeStats.CLIFE <= 0:
			deathFlag = true
		#if deathFlag and t.faction == "Player":
			#t.killXP = true
	#if retaliation failed, or did 0 dmg, check if attacker can make a second attempt.
	if !hurt and !deathFlag and fData[a].FUP and check_uses(aWep): 
		print("Round 3 begins: ", a.unitName, " is attacking ", t.unitName)
		r3 = get_attack(a,t)
	if r3:
		hurt = combat_round(a, t)
		_reduce_durability(a, aWep)
		if dmg != 0:
			t.apply_dmg(dmg)
	print("Combat has resolved.")
	emit_signal("combat_resolved")
	
	


	
	
#call to roll crit and damage after hit, returns true if any damage was actually done
func combat_round(a, t):
	var crt = _get_crit(a)
	var dmg = _get_dmg(a, t, crt)
	return dmg
	
func _get_crit(a):
	#test variable
	var critRoll
	var critDmg
	critRoll = get_roll()
	#print(cbtFC[a].NAME, "'s crit check was ", critRoll, " / ", cbtFC[a].CRIT,)
	if fData[a].CRIT >= critRoll:
		print("Girl's are criting")
		critDmg = rng.randi_range(10, 20)
	else:
		print("Critical Failure!")
		critDmg = 0
	return critDmg
	

func _get_dmg(a, t, crt):
	var roll = get_roll()
	var graze = 0
	var dmg = 0
	if roll <= fData[t].GRZPRC:
		graze = fData[t].GRAZE
		#print(cbtFC[t].NAME, " Grazed! [-", cbtFC[t].GRAZE, "]")
	#print(cbtFC[t].NAME, "'s LIFE was reduced from ", cbtCL[t])
	dmg = ((fData[a].DMG + crt) - graze)
	#cbtCL[t] = units[t].apply_dmg(dmg)
	##print(" to ", cbtCL[t], " of which ", crt, " was critical damage!")
	#
	#if cbtCL[t] <= 0:
		#deathFlag = true
	return dmg
	
func get_roll():
	randomize()
	return rng.randi_range(0, 99)

func get_attack(a, t):
	#test variable
	var hit = false
	var roll = get_roll()
	#print(cbtFC[a].NAME, "'s ACC check: ", roll, "/", cbtFC[a].ACC, "
		#", cbtFC[t].NAME,"'s Avoid: ", cbtFC[t].AVOID)
	if fData[a].ACC >= roll:
		print("This was a hit")
		hit = true
	else:
		print("She missed!")
		hit = false
#	if hit == false and cbtCL[a]["Passive"].has("Fate"):
#		var fate = get_roll()
#		print("Fate!: ", fate)
#		if  fate < fateChance:
#			print("Fate Success")
#			hit = true
			
	return hit
	
func check_uses(weapon): # split durability drop from check
	if weapon.DUR != 0:
		return true
	elif weapon.DUR == 0:
		#print("out of uses!")
		return false

func use_item(unit, item):
	run_effects(unit, unit, itemData[item.DATA], true, true)
	_reduce_durability(unit, item)
	if item.DUR <= 0:
		_delete_item(unit, item)
	
func _reduce_durability(unit, item):
	var reduc = -1
	if item.DUR == -1:
		return
	item.DUR -= reduc
	clampi(item.DUR, 0, 99)
	if item.DUR == 0:
		_delete_item(unit, item)
		
func _delete_item(unit, item):
	var inv = unit.unitData.Inv
	var eqp = unit.get_equipped_weapon()
	var i = inv.find(item)
	if eqp == item:
		unit.unequip()
	inv.remove_at(i)

#Skills handled here and below#
func run_skill(actor, target, activeSkill):
	var skillResult = {}
	var deathFlag = false
	match activeSkill.Target:
		"Enemy":
			skill_combat(actor, target, activeSkill)
		"Self", "Ally":
			run_effects(actor, target, activeSkill)
	# actor.add_composure(skill.Cost) #not an existing function yet
	return skillResult
	
func run_effects(actor, target, activeSkill, hit = true, isItem = false):
	var proc
	var canCrit = false
	var isSkill = true
	#Add a check for if the Actor has a passive that enables criticals with skills
	for effId in activeSkill.EFFECT:
		var effect = effectData[effId]
		proc = false
		if effect.OnHit and !hit:
			continue
		if effect.Proc == -1:
			proc = true
		elif get_roll() < effect.Proc:
			proc = true
		if proc:
			for attribute in effect:
				if typeof(effect[attribute]) == TYPE_BOOL and effect[attribute] == true:
					var selfTarget = false
					match attribute:
						#Need to go through and enable each effect one at a time
						"Time": 
							emit_signal("time_factor_changed", effId, effect.TimeFactor, effect.Duration, attribute)
						"Buff": 
							
#							if actor == target:
#								selfTarget = true
#							print("Self Targeting: ")
							match effect.Target:
								"Target": 
									target.apply_buff(attribute, effId, effect.BuffStat, effect.BuffValue, effect.Duration, effect.Curable)
									print("Actor: ", actor.unitName, "Target: ", target.unitName, " Buffed ", effect.BuffStat, " by +", effect.BuffValue, " for ", effect.Duration, " rounds.")
								"Self":  
									actor.apply_buff(attribute, effId, effect.BuffStat, effect.BuffValue, effect.Duration, effect.Curable)
									print("Actor: ", actor.unitName, " Buffed ", effect.BuffStat, " by +", effect.BuffValue, " for ", effect.Duration, " rounds.")
						"Debuff": 
							match effect.Target:
								"Target": 
									target.apply_buff(attribute, effId, effect.BuffStat, effect.BuffValue, effect.Duration, effect.Curable)
									print("Actor: ", actor.unitName, "Target: ", target.unitName, " Buffed ", effect.BuffStat, " by +", effect.BuffValue, " for ", effect.Duration, " rounds.")
								"Self":  
									actor.apply_buff(attribute, effId, effect.BuffStat, effect.BuffValue, effect.Duration, effect.Curable)
									print("Actor: ", actor.unitName, " Buffed ", effect.BuffStat, " by +", effect.BuffValue, " for ", effect.Duration, " rounds.")
						"Damaging": 
							print("Target HP: ", target.activeStats.CLIFE)
							factor_dmg(actor, target, effect, canCrit, isSkill)
						"Cure": target.cure_status(effect.CureType)
						"Healing": 
							factor_healing(actor, target, effect, isItem)
						"Sleep": target.set_status(attribute, effect.Duration, effect.Curable)
						"Relocate": start_relocation(actor, target, effect.MoveType, effect.RelocRange)
	
func skill_combat(actor, target, skill):
	var canCounter = false #placeholder, implement passive in future that can enable skill countering
	var result = {}
	var hit = false
	var attacker = Global.attacker
	var defender = Global.defender
	var check = get_roll()
	var r1
	var canReach = fData[target].reach
	var defWep = defender.get_equipped_weapon()
	var deathFlag = false
	print(actor.unitName, " skill: ", skill.SkillId, " ACC: ", attacker.ACC, " check: ", check, "/", defender.AVOID)
	if check < (attacker.ACC - defender.AVOID):
		hit = true
		print("It's a hit")
	if !skill.CanMiss:
		hit = true
	run_effects(actor, target, skill, hit)
	if !hit and canCounter and canReach and check_uses(defWep) and !deathFlag:
		r1 = get_attack(1, 0)
	if r1:
		combat_round(1, 0)
	
func factor_dmg(actor, target, attack, canCrit = false, isSkill = false):
	var aMag = actor.activeStats.MAG
	var aPwr = actor.activeStats.PWR
	var aBar = actor.activeStats.BAR
	var tMag = target.activeStats.MAG
	var tPwr = target.activeStats.PWR
	var tBar = target.activeStats.BAR
	var tReduc = 0
	var aTotalDmg = 0
	var critDmg = 0
	var deathFlag = false
#	if canCrit:
#		critDmg = roll_crit(actor, target, attack)
	if isSkill:
		var type = attack.Type
		match type:
			"Magic":
				tReduc = tMag
				aTotalDmg = aMag + attack.Damage + critDmg
			"Physical":
				tReduc = tBar
				aTotalDmg = aPwr + attack.Damage + critDmg
	else:
		pass
	print(aTotalDmg)
	var dmgResult = aTotalDmg - tReduc
	var tCLife = target.apply_dmg(dmgResult)
	print(actor.unitName, "Dealt ", dmgResult, "Target's HP: ", target.activeStats.CLIFE)
	if target.activeStats.CLIFE <= 0:
		deathFlag = true
		target.killXP = true
	return dmgResult

func factor_healing(actor, target, effect, isItem):
	var bonusEff = 0
	#Add checks for bonus effects here
	var statBonus
	var healPower
	if isItem:
		statBonus = 0
	else:
		statBonus = actor.activeStats.MAG
	healPower = effect.Heal + statBonus + bonusEff
	print("Target Life: ", target.activeStats.CLIFE, " Heal:", healPower)
	target.apply_heal(healPower)
	print(target.activeStats.CLIFE)

func roll_crit(a, _t, attack): #Rework the combat manager, it's a fucking mess and not as modular as I hoped. It also can't update mid combat reliably due to the distance check.
	#test variable
	var critRoll
	var critDmg
	critRoll = get_roll()
	#print(a.unitName, "'s crit check was ", critRoll, " / ", cbtFC[a].CRIT)
	if fData[a].clash.CRIT >= critRoll:
		print("Girl's are criting")
		critDmg = rng.randi_range(10, 20)
	else:
		print("Critical Failure!")
		critDmg = 0
	return critDmg
	pass

func start_relocation(actor, target, type, range): #determines method of relocation, then passes to the correct type
	var pivotHex
	var matchHex
	match type:
		"Warp": emit_signal("warp_selected", actor, target, range)
		"Shove": 
			pivotHex = target.cell
			matchHex = actor.cell
			shove_or_toss_unit(actor, target, range, pivotHex, matchHex)
		"Toss": 
			pivotHex = actor.cell
			matchHex = target.cell
			shove_or_toss_unit(actor, target, range, pivotHex, matchHex)

func shove_or_toss_unit(actor, target, range, pivotHex, matchHex):
	#Toss: Grab Actor's Cell and Target's Cell. Look through Actor's Neighbors for a match with Target's cell. Adjust position in array to the opposite directional hex and move Target there.
	#Shove: The same principle, except you are searching the Target's neighbors for the Actor's Cell and moving them to the opposite cell of that.

	var neighbors = aHex.get_BFS_nhbr(pivotHex, false, true)
	var shoveResult = aHex.resolve_shove(matchHex, target.cell, neighbors, range)
	var slamDmg = Global.slamage + actor.activeStats.PWR + (shoveResult.Travel * 2)
	
	if shoveResult.Slam and !shoveResult.UniColl:
		target.apply_dmg(slamDmg)
		target.relocate_unit(shoveResult.Hex)
	elif shoveResult.Slam:
		target.apply_dmg(slamDmg)
		shoveResult.UniColl.apply_dmg(slamDmg)
		target.relocate_unit(shoveResult.Hex)
	else:
		target.relocate_unit(shoveResult.Hex)
		
func warp_to(target, cell):
	target.relocate_unit(cell)

func _on_gui_manager_start_the_justice():
	pass # Replace with function body.


#func combat_forecast(a: Unit, t: Unit, distance, isSkill = false, skill = null):
	#cbtUD.clear()
	#cbtCL.clear()
	#cbtAW.clear()
	#fData.clear()
	#aWep = a.unitData.EQUIP
	#tWep = t.unitData.EQUIP
	#var aId = aWep.DATA
	#var tId = tWep.DATA
	#canReach = false
	#var itemData = UnitData.itemData
	#
	#
	#cbtCL = [a.activeStats.CLIFE, t.activeStats.CLIFE]
	#cbtUD = [a.unitData.Stats, t.unitData.Stats]
	#cbtAW = [itemData[aId], itemData[tId]]
	#var i = 0
	#var revI = 1
	#var atkr = 0
	#var trgt = 1
	#var wAcc = [cbtAW[0].ACC, cbtAW[1].ACC]
	#var wDmg = [cbtAW[0].DMG, cbtAW[1].DMG]
	#var wCrt = [cbtAW[0].CRIT, cbtAW[1].CRIT]
	#var wGrz = [cbtAW[0].GRAZE, cbtAW[1].GRAZE]
##	var wLimit = [cbtAW[0].LIMIT, cbtAW[1].LIMIT]
	#var wType = [cbtAW[0].TYPE, cbtAW[1].TYPE]
	#var minR = cbtAW[1].MINRANGE
	#var maxR = cbtAW[1].MAXRANGE
	#
	#if isSkill: #Not evaluated yet
		#if skill.CanMiss:
			#wAcc[0] = skill.ACC
		#for effect in skill.Effect:
			#if  effectData[effect].has("Damaging") and effectData[effect].Damaging == true:
				#wCrt[0] = 0
				#wType[0] = effectData[effect].Type
				#match  effectData[effect].Type: 
					#"Physical": 
						#wDmg[0] += effectData[effect].Damage
					#"Magical": 
						#wDmg[0] += effectData[effect].Damage
				#
	#canReach = _distance_check(minR, maxR, distance)
		#
	#fData[a] = _evaluate_clash(a, t)
	#fData[t] = _evaluate_clash(t, a)
	#fData.t["RLIFE"] = _get_remaining_life(t, fData.a)
	#fData.a["RLIFE"] = _get_remaining_life(a, fData.t)
