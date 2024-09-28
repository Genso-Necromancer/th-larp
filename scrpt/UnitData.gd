@tool
extends Node

const pStats = preload("res://character_data/pStats.gd")

@export var supplyMax = 180

var unitData : = {}
var skillData : = {}
var effectData := {}
var timeModData := {}
var itemData := {}
var passiveData := {}
var auraData := {}
var rosterData := []

var supply = {}
var npcInv = {}
var terrainCosts = {}
var rosterOnce := false
const unarmed := {"ID": "NONE", "Equip": true, "DUR": -1, "Broken": false}



func _ready():
	var index = 0
	
	_load_unique_units()
	_load_items()
	terrainCosts = pStats.get_terrain_costs()
	_load_skills()
	_load_effects()
	_load_time_mods()
	_load_passive_data()
	_load_aura_data()
	#print(timeModData)
	init_roster()
	init_supply()

func _load_unique_units():
	unitData = pStats.get_named_unit_data()
	
func _load_items():
	var rawData = pStats.get_items()
	var keys = rawData.keys()
	
	for key in keys:
		itemData[key] = {
		"Name":"None",
		"Icon":load(("res://sprites/gungnir.png")),
		"Type":"None",
		"Dmg":0,
		"Hit":0,
		"Crit":0,
		"Graze":0,
		"MinRange":0,
		"MaxRange":0,
		"Category":"ITEM",
		"MaxDur":1,
		"SubGroup":false,
		"USE":false,
		"Equip":false,
		"Expendable": true,
		"Effect":{},
		}
		var innerKeys = rawData[key].keys()
		for iKey in innerKeys:
			itemData[key][iKey] = rawData[key][iKey]

func _load_skills():
	var rawData = pStats.get_skills()
	var keys = rawData.keys()
	
	for key in keys:
		skillData[key] = {
		"SkillId": key,
		"SkillName": "no_name",
		"Icon": load(("res://sprites/gungnir.png")),
		"Augment": false, #Set true if weapon stats should be used.
		"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)
		"TrueHit": false, #default true
		##Only if Augment
		"WepCat": Enums.WEAPON_CATEGORY.ANY, #Set to required weapon category, or sub type, for skill use.
		"BonusMinRange": 0,
		"BonusMaxRange": 0,
		##If !augment, these are the parameters used as if it was a weapon. If Augment, these values are added as bonus/penalty if altered.
		"Hit": 0, #Int only. negative values acceptable for Hit penalties to the skill
		"Dmg": false, #set an int value for damage, set false to prevent dealing damage
		"Crit": false, #set an int value for crit bonus, set false to prevent crits
		"Type": Enums.DAMAGE_TYPE.PHYS, #use enum types. Set False if augment should use weapon's type.
		##Used regardless of Augment
		"RangeMin": 0, #if 0, ignored by Augment. Set value to require specific weapon range.
		"RangeMax": 0,
		"Cost": 0,
		"Effect": [], #any attacking effects for an augment skill must be set to instant.
		"RuleType": false,
		"Rule": false,
		}
		var innerKeys = rawData[key].keys()
		for iKey in innerKeys:
			skillData[key][iKey] = rawData[key][iKey]
			
func _load_effects():
	var rawData = pStats.get_effects()
	var keys = rawData.keys()
	
	for key in keys:
			effectData[key] = {
				"Type": Enums.EFFECT_TYPE,
				"SubType": false, #Use Enums.SUB_TYPE. For Damage, use Damage Enums. Just how it's gotta be.
				"Target": Enums.EFFECT_TARGET.TARGET, #Self, Target, Global, Equipped
				"Instant": false, #only set for effects that should occur before an augment skill is rolled.
				"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
				"Proc": -1, #Set to -1 to have gaurenteed proc chance
				"Duration": 0, #Unit turns the effect lasts, -1 causes the effect to be permanent. Duration is ignored entirely for on-equip effects of items.
				"DurationType": false,
				"Stack": false, #True for infinite stacking, soft limit by duration Not necessary for permanent effects. Ignored for on-equip effects.
				"Value": 0, #use 0-2 float for time speed up/slow down.
				#Effect STATUS/BUFF/DEBUFF
				"Curable": true, #For buffs/debuffs. Dictates if effects can remove them.
				#Effect: HEAL
				"FromItem": false, #true disallows stat bonus to healing
				#effect: Reloc
				"Hostile": false, #If movement should be treated as "hostile"
				"Skill": "", #Not used yet. Temporarily adds skills via on-equip effects
				#Effect: ADD_PASSIVE
				"Passive": "",
				#Effect: ADD_PASSIVE/ADD_SKILL
				"Permanent": false,
				#Effect: MULTI_SWING
				#"MultiSwing": 0, #set int for # of extra swings per attack
				##Effect: MULTI_ROUND
				#"MultiRound": 0, #set int for # of combat rounds
				#Effect: CRIT_BUFF
				"CritDmg": false, # use and array of a min-value and max-value. Can be negative or positive.
				"CritMulti": false, #use 1.x floats
				"CritRate": false,
				#RULE TYPES. YET TO BE IMPLEMENTED!!!!
}
			var innerKeys = rawData[key].keys()
			for iKey in innerKeys:
				effectData[key][iKey] = rawData[key][iKey]

func _load_time_mods():
	var rawData = pStats.get_time_mods()
	
	for key in rawData:
			timeModData[key] = {
						Enums.TIME.DAY:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
							"MagDef": 0,
							"PhysDef": 0,
							"MoveType": false,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
							"MagDef": 0,
							"PhysDef": 0,
							"MoveType": false,
						}
					
}
			var innerKeys = rawData[key][Enums.TIME.DAY].keys()
			for iKey in innerKeys:
				timeModData[key][Enums.TIME.DAY][iKey] = rawData[key][Enums.TIME.DAY][iKey]
				timeModData[key][Enums.TIME.NIGHT][iKey] = rawData[key][Enums.TIME.NIGHT][iKey]

func _load_aura_data():
	var rawData = pStats.get_auras()
	
	for key in rawData:
			auraData[key] = {
						"Range": 0,
						"IsSelf": false,
						"IsFriendly": true,
						"Effects":[]
}
			var innerKeys = rawData[key].keys()
			for iKey in innerKeys:
				auraData[key][iKey] = rawData[key][iKey]
				
func _load_passive_data():
	var rawData = pStats.get_passives()
	
	for key in rawData:
			passiveData[key] = {
			"Type": Enums.PASSIVE_TYPE,
			"Icon": load(("res://sprites/gungnir.png")),
			"Value": 0,
			"IsTimeSens": false,
			"Aura": false,
			Enums.TIME.DAY: false,
			Enums.TIME.NIGHT: false,
		}
			var innerKeys = rawData[key].keys()
			for iKey in innerKeys:
				passiveData[key][iKey] = rawData[key][iKey]

func get_generated_sprite(species, job):
	var s = pStats.load_generated_sprite(species, job)
	return s


func stat_gen(job :int, tag : String, spec : int):
	#Need overhaul1!!!!

	var groupedStats = {}
	#var jData = jobData[job].duplicate(true)
	var sData = pStats.get_spec(spec)
	var jData = pStats.get_job(job)
	var groups = sData.StatGroups.keys()
	var stats = sData.StatGroups.Stats.keys()
	var specKeys = Enums.SPEC_ID.keys()
	
	groupedStats.clear()
	for group in groups:
		var totalStats = {}
		for stat in stats:
			totalStats[stat] = sData.StatGroups[group][stat] + jData.StatGroups[group][stat]
		groupedStats[group] = totalStats
	var genname = "%s %s" % [specKeys[sData["Spec"]], jData["Role"]]
	var combinePassives = sData["Passives"] + jData["Passives"]
	#combinePassives.merge(jData["Passives"])
	unitData[tag] = groupedStats
	unitData[tag]["Profile"] = {"UnitName" : genname}
	unitData[tag]["Profile"].merge({"Role" : jData["Role"]})
	unitData[tag]["Profile"].merge({"Species" : sData["Spec"]})

	unitData[tag]["Profile"].merge(pStats.get_art(unitData[tag].Profile.UnitName))
	unitData[tag]["Profile"].merge({"Level": 1})
	#unitData[tag]["CurLife"] = unitData[tag]["Bases"]["Life"]
	unitData[tag]["MaxInv"] = 6
	unitData[tag]["Inv"] = []
	unitData[tag]["Passives"] = combinePassives
	unitData[tag]["Weapons"] = jData.Weapons
	unitData[tag]["MoveType"] = sData["MoveType"]
	
#func get_experience(action, totalExp, targLvl, unitStats, growths, caps):
#	var gainExp = 0
#	match action:
#		"attack":  
#				gainExp  = (21 + targLvl - unitStats[0]) / 2
#				gainExp = clampi(gainExp, 1, 100)
#
#		"defeat": 
#			gainExp = ((21 + targLvl - unitStats[0]) / 2) + (targLvl - unitStats[0])
#			gainExp = clampi(gainExp, 1, 100)
#		"pacifist": 
#			gainExp = (21 + unitStats[0])
#			gainExp = clampi(gainExp, 1, 100)
#
#	totalExp = totalExp + gainExp
#	while totalExp >= 100:
#		totalExp -= 100
#		totalExp = clampi(totalExp, 0, 10000)
#		unitStats = level_up(unitStats, growths, caps)
#	return [totalExp, unitStats]
	
func level_up(uData, loops): #consider range bands for stat normalization. Growth rates are a spook tho.
	var rng = RandomNumberGenerator.new()
	randomize()
	var growth_check
	var i = 0
	var results = {}
	var firstLoop = true
	var stats = uData.Stats.keys()
	results["LVL"] = 0
	while loops > 0:
		uData.Profile.Level += 1
		results["LVL"] += 1
		while i < stats.size():
			growth_check = rng.randf_range(0.00, 1.0)
			if growth_check <= uData.Growths[stats[i]] and uData.Stats[stats[i]] < uData.Caps[stats[i]]:
				uData.Stats[stats[i]] += 1
				if firstLoop: results[stats[i]] = 1
				else: results[stats[i]] += 1
			growth_check = rng.randf_range(0.00, 1.0)
			if uData.Growths[stats[i]] >= 1.0 and growth_check <= (uData.Growths[stats[i]] - 1.0) and uData.Stats[stats[i]] < uData.Caps[stats[i]]:
				uData.Stats[stats[i]] += 1
				results[stats[i]] += 1
			i += 1
		loops -= 1
		firstLoop = false
	return results
	
func init_roster():
	if !rosterOnce:
		rosterData.append("Remilia")
		rosterData.append("Sakuya")
		rosterData.append("Patchouli")
		rosterData.append("Meiling")
		rosterOnce = true
	return

func init_supply():
	supply = {
		"BLADE":[{"ID":"SLVKNF", "DUR":40, }],
		"BLUNT":[{"ID":"CLB", "DUR":40, }],
		"STICK":[],
		"GOHEI":[],
		"BOOK":[],
		"FAN":[],
		"BOW":[],
		"GUN":[],
		"Hit":[],
		"ITEM":[]
		}
	


