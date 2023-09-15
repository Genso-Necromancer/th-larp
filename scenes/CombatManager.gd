extends Node
class_name CombatManager
signal combat_resolved
var cbtFC : Array
var cbtUD : Array
var cbtCL : Array
var cbtAW : Array
var rng = Global.rng
var aWep
var tWep
var fateChance = 15
var deathFlag = false
var units
@onready var skillData = UnitData.skillData
@onready var effectData = UnitData.effectData
var canReach = false

func combat_forecast(a: Unit, t: Unit, distance, isSkill = false, skill = null):
	cbtFC.clear()
	cbtUD.clear()
	cbtCL.clear()
	cbtAW.clear()
	aWep = a.unitData.EQUIP
	tWep = t.unitData.EQUIP
	canReach = false
	var AtkInv
	var TarInv
	match a.faction:
		"Player": 
			AtkInv = UnitData.plrInv
		"Enemy":
			AtkInv = UnitData.npcInv
	match t.faction:
		"Player": 
			TarInv = UnitData.plrInv
		"Enemy":
			TarInv = UnitData.npcInv
	units = [a, t]
	cbtFC = [Global.attacker, Global.defender]
	cbtCL = [a.activeStats.CLIFE, t.activeStats.CLIFE]
	cbtUD = [a.unitData.Stats, t.unitData.Stats]
	cbtAW = [AtkInv[aWep], TarInv[tWep]]
	var i = 0
	var revI = 1
	var atkr = 0
	var trgt = 1
	var wAcc = [cbtAW[0].ACC, cbtAW[1].ACC]
	var wDmg = [cbtAW[0].DMG, cbtAW[1].DMG]
	var wCrt = [cbtAW[0].CRIT, cbtAW[1].CRIT]
	var wGrz = [cbtAW[0].GRAZE, cbtAW[1].GRAZE]
#	var wLimit = [cbtAW[0].LIMIT, cbtAW[1].LIMIT]
	var wType = [cbtAW[0].TYPE, cbtAW[1].TYPE]
	var wMinReach = [cbtAW[0].MINRANGE, cbtAW[1].MINRANGE]
	var wMaxReach = [cbtAW[0].MAXRANGE, cbtAW[1].MAXRANGE]
	if isSkill:
		if skill.CanMiss:
			wAcc[0] = skill.ACC
		for effect in skill.Effect:
			if  effectData[effect].has("Damaging") and effectData[effect].Damaging == true:
				wCrt[0] = 0
				wType[0] = effectData[effect].Type
				match  effectData[effect].Type: 
					"Physical": 
						wDmg[0] += skill.Damage
					"Magical": 
						wDmg[0] += skill.Damage
				
	if distance in range(wMinReach[1], wMaxReach[1]):
		canReach = true
		
	
	
	
	cbtFC[0].NAME = a.unitData.Profile.UnitName
	cbtFC[0].Prt = a.unitData.Profile.Prt
	cbtFC[1].NAME = t.unitData.Profile.UnitName
	cbtFC[1].Prt = t.unitData.Profile.Prt
	#factor each unit's solo combat stats based on specific factors
	while i < cbtFC.size():
		cbtFC[i].ACC = cbtUD[i].ELEG * 2 + wAcc[i] + (cbtUD[i].CHA)
		match wType[i]: 
			"Physical":
				cbtFC[i].DMG = cbtUD[i].PWR + wDmg[i]
			"Magical": 
				cbtFC[i].DMG = cbtUD[i].MAG + wDmg[i]
		
		cbtFC[i].AVOID = (cbtUD[i].CELE * 2) + (cbtUD[i].CHA)
		match wType[revI]:
			"Physical":
				cbtFC[i].DEF = cbtUD[i].BAR
			"Magical":
				cbtFC[i].DEF = cbtUD[i].MAG
		cbtFC[i].CRIT = cbtUD[i].ELEG + wCrt[i]
		cbtFC[i].CAVOID = (cbtUD[i].CHA)
		cbtFC[i].LIFE = cbtUD[i].LIFE
		cbtFC[i].CLIFE = cbtCL[i]
		cbtFC[i].GRAZE = wGrz[i]
		cbtFC[i].GRZPRC = cbtUD[i].ELEG + cbtUD[i].BAR
		i += 1
		revI -= 1
	i = 0
	#Formulate the results of the two units fighting
	while i < cbtFC.size():
		cbtFC[atkr].ACC = cbtFC[atkr].ACC - cbtFC[trgt].AVOID
		cbtFC[atkr].ACC = clampi(cbtFC[atkr].ACC, 0, 1000)
		cbtFC[atkr].DMG = cbtFC[atkr].DMG - cbtFC[trgt].DEF
		cbtFC[atkr].DMG = clampi(cbtFC[atkr].DMG, 0, 1000)
		cbtFC[atkr].CRIT = cbtFC[atkr].CRIT - cbtFC[trgt].CAVOID
		cbtFC[atkr].CRIT = clampi(cbtFC[atkr].CRIT, 0, 1000)
		if cbtUD[atkr].CELE > cbtUD[trgt].CELE + 4:
			cbtFC[atkr]["FUP"] = true
		else:
			cbtFC[atkr]["FUP"] = false
		atkr = 1
		trgt = 0
		i += 1
	atkr = 0
	trgt = 1
	cbtFC[atkr].RLIFE = cbtFC[atkr].CLIFE - cbtFC[trgt].DMG
	cbtFC[atkr].RLIFE = clampi(cbtFC[atkr].RLIFE, 0, 1000)
	cbtFC[trgt].RLIFE = cbtFC[trgt].CLIFE - cbtFC[atkr].DMG
	cbtFC[trgt].RLIFE = clampi(cbtFC[trgt].RLIFE, 0, 1000)
	
func start_the_justice(a: Unit, t: Unit):
	cbtUD = [a.activeStats, t.activeStats]
	cbtCL = [a.activeStats.CLIFE, t.activeStats.CLIFE]
	var hurt = false
#	var roll
	var r1 = false
	var r2 = false
	var r3 = false
#	var r4 = false
	deathFlag = false
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
	
	
	
	#TAKING 0 DAMAGE DOESNT ALLOW FOR A FOLLOW UP. FIX IT.
	#first round
	print("Girl's are fighting")
	print("Round 1 begins: ", cbtFC[0].NAME, " is attacking ", cbtFC[1].NAME)
	r1 = get_attack(0, 1)
	if r1 and check_uses(cbtAW[0]) and !deathFlag: 
			hurt = combat_round(0, 1)
			
	if !hurt and check_uses(cbtAW[1]) and !deathFlag and canReach:
			print("Round 2 begins: ", cbtFC[1].NAME, " is attacking ", cbtFC[0].NAME)
			r2 = get_attack(1,0)
	if r2:
		hurt = combat_round(1, 0)
	#if it failed, or did 0 dmg. check both units for FUP true
	if !hurt and !deathFlag: 
		if cbtFC[0].FUP and check_uses(cbtAW[0]):
			print("Round 3 begins: ", cbtFC[0].NAME, " is attacking ", cbtFC[1].NAME)
			r3 = get_attack(0,1)
		if r3:
			hurt = combat_round(0, 1)
		if cbtFC[1].FUP and check_uses(cbtAW[1]) and canReach:
			print("Round 3 begins: ", cbtFC[1].NAME, " is attacking ", cbtFC[0].NAME)
			r3 = get_attack(1,0)
		if r3:
			hurt = combat_round(1, 0)
			
	print("Combat has resolved.")
	emit_signal("combat_resolved")
	
	


	
	
#call to roll crit and damage after hit, returns true if any damage was actually done
func combat_round(a, t):
	var crt = get_crit(a,t)
	var dmg = get_dmg(a, t, crt)
	var hurt = false
	if dmg != 0:
			hurt = true
	return hurt
	
func get_crit(a, _t):
	#test variable
	var critRoll
	var critDmg
	critRoll = get_roll()
	print(cbtFC[a].NAME, "'s crit check was ", critRoll, " / ", cbtFC[a].CRIT,)
	if cbtFC[a].CRIT >= critRoll:
		print("Girl's are criting")
		critDmg = rng.randi_range(10, 20)
	else:
		print("Critical Failure!")
		critDmg = 0
	return critDmg
	

func get_dmg(a, t, crt):
	var roll = get_roll()
	var graze = 0
	var dmg = 0
	if roll <= cbtFC[t].GRZPRC:
		graze = cbtFC[t].GRAZE
		print(cbtFC[t].NAME, " Grazed! [-", cbtFC[t].GRAZE, "]")
	print(cbtFC[t].NAME, "'s LIFE was reduced from ", cbtCL[t])
	dmg = ((cbtFC[a].DMG + crt) - graze)
	cbtCL[t] = units[t].apply_dmg(dmg)
	print(" to ", cbtCL[t], " of which ", crt, " was critical damage!")
	
	if cbtCL[t] <= 0:
		deathFlag = true
	return dmg
	
func get_roll():
	randomize()
	return rng.randi_range(0, 99)

func get_attack(a, t):
	#test variable
	var hit = false
	var roll = get_roll()
	print(cbtFC[a].NAME, "'s ACC check: ", roll, "/", cbtFC[a].ACC, "
		", cbtFC[t].NAME,"'s Avoid: ", cbtFC[t].AVOID)
	if cbtFC[a].ACC >= roll:
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
	
func check_uses(weapon):
	if weapon.LIMIT and weapon.DUR != 0:
		weapon.DUR -= 1
		print(weapon.NAME, " uses: ", weapon.DUR,"/",weapon.MAXDUR)
		return true
	elif weapon.LIMIT and weapon.DUR == 0:
		print(weapon, " is out of uses!")
		return false
	else:
		return true
		

#Skills handled here and below#
func run_skill(actor, target, activeSkill):
	var skillResult = {}
	
	match activeSkill.Target:
		"Enemy":
			pass #skillResult = skill_combat(actor, target, skill)
		"Self", "Ally":
			run_effects(actor, target, activeSkill, true)
	# actor.add_composure(skill.Cost) #not an existing function yet
	return skillResult
	
func run_effects(actor, target, activeSkill, hit):
	var proc
	for effID in activeSkill.Effect:
		var effect = effectData[effID]
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
						"Time": print("Time")
						"Buff": 
							
#							if actor == target:
#								selfTarget = true
#							print("Self Targeting: ")
							match effect.Target:
								"Target": 
									target.apply_buff(activeSkill, effect.BuffStat, effect.BuffValue, effect.Duration)
									print("Actor: ", actor.unitName, "Target: ", target.unitName, " Buffed ", effect.BuffStat, " by +", effect.BuffValue, " for ", effect.Duration, " rounds.")
								"Self":  
									actor.apply_buff(activeSkill, effect.BuffStat, effect.BuffValue, effect.Duration)
									print("Actor: ", actor.unitName, " Buffed ", effect.BuffStat, " by +", effect.BuffValue, " for ", effect.Duration, " rounds.")
						"Debuff": print("Debuff")
						"Damaging": print("Damaging")
						"Cure": print("Cure")
						"Healing": print("Healing")
						"Sleeping": print("Sleeping")
						"Relocate": print("Relocate")
	
func skill_combat():
	var canCounter = false #placeholder, implement passive in future that can enable skill countering
	var result = {}
	var hit = false
	var attacker = Global.attacker
	var defender = Global.defender
	var check = get_roll()
	var r1
	if check + attacker.ACC < defender.AVOID:
		hit = true
	if hit:
		pass #check_effects
	if !hit and canCounter and canReach and check_uses(cbtAW[1]):
		r1 = get_attack(1, 0)
	if r1:
		combat_round(1, 0)
	

