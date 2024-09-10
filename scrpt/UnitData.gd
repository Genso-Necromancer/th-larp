@tool
extends Node

const pStats = preload("res://character_data/pStats.gd")

@export var supplyMax = 180
var unitData : Dictionary = {}

var itemData = {}
var supply = {}
var npcInv = {}
var terrainCosts = {}
var skillData : Dictionary = {}
var effectData : Dictionary = {}
var rosterData : Array = []
var rosterOnce : bool = false
const unarmed : Dictionary = {"ID": "NONE", "EQUIP": true, "DUR": -1}



func _ready():
	var index = 0
	
	while index < pStats.UNIT_ID.size():
		unitData.merge(pStats.get_named_unit_data(index))
		index += 1
	index = 0
	
	_load_items()
	terrainCosts = pStats.get_terrain_costs()
	_load_skills()
	effectData = pStats.get_skill_effects()
	init_roster()
	init_supply()
	
	
func _load_items():
	var rawData = pStats.get_items()
	var keys = rawData.keys()
	
	for key in keys:
		itemData[key] = {
		"Name":"None",
		"Icon":load(("res://sprites/gungnir.png")),
		"Type":"None",
		"Dmg":0,
		"ACC":0,
		"Crit":0,
		"GRAZE":0,
		"MINRANGE":0,
		"MAXRANGE":0,
		"CATEGORY":"ITEM",
		"MAXDUR":1,
		"SUBGROUP":false,
		"USE":false,
		"EQUIP":false,
		"Effect":{}
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
		"SkillName": "noName",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)
		"CanMiss": true, #default true
		"ACC": 0, #Int only. negative values acceptable for ACC penalties to the skill
		"Dmg": false, #set an int value for damage
		"Crit": false, #set an int value for crit bonus
		"Type": Enums.DAMAGE_TYPE.PHYS, #use enum types
		"RangeMin": 0,
		"RangeMax": 0,
		"Cost": 0,
		"Effect": []
		}
		var innerKeys = rawData[key].keys()
		for iKey in innerKeys:
			skillData[key][iKey] = rawData[key][iKey]
			
func _load_effects():
	var rawData = pStats.get_skill_effects()
	var keys = rawData.keys()
	
	for key in keys:
			skillData[key] = {
				"Type": Enums.EFFECT_TYPE,
				"Target": Enums.EFFECT_TARGET.SELF, #Self, Target, Global
				"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
				"Proc": -1, #Set to -1 to have gaurenteed proc chance
				"Duration": 0, #Unit turns the effect lasts, -1 causes the effect to be permanent. Duration is ignored entirely for on-equip effects of items.
				"Stack": false, #True for infinite stacking, soft limit by duration Not necessary for permanent effects. Ignored for on-equip effects.
				#Effect specific Parameters
				#Effect: Time
				"TimeFactor": 0,
				#Effect: Buff/Debuff
				"BuffStat": Enums.CORE_STAT, #Any core Stat
				"BuffValue": 0,
				#Effect: Status
				"Status": Enums.STATUS_EFFECT, #Assign with string of valid Status conditions, Refer to Unit class for list.
				#Effect STATUS/BUFF/DEBUFF
				"Curable": true, #For buffs/debuffs. Dictates if effects can remove them.
				#Effect: DAMAGE
				"Dmg": 0, #set an int damage value
				"DmgType": Enums.DAMAGE_TYPE.PHYS, #use enum types
				#Effect: HEAL
				"Heal": 0, #set an int heal value
				#Effect: CURE
				"CureType": Enums.STATUS_EFFECT, #Sleep, or All. This is because Sleep is the only status atm. As new status are added, this parameter does not need to be updated.
				#effect: TOSS/SHOVE/WARP/DASH
				"RelocRange": 0, #Distance Shoved, or range of valid tiles to warp to. Set to 0 for Toss.
				"Hostile": false, #If movement should be treated as "hostile"
				#Effect: ADD_SKILL
				"Skill": "", #Not used yet. Temporarily adds skills via on-equip effects
				#Effect: ADD_PASSIVE
				"Passive": "",
				#Effect: ADD_PASSIVE/ADD_SKILL
				"Permanent": false,
				#RULE TYPES. YET TO BE IMPLEMENTED!!!!
}
			var innerKeys = rawData[key].keys()
			for iKey in innerKeys:
				skillData[key][iKey] = rawData[key][iKey]


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
	
	groupedStats.clear()
	for group in groups:
		var totalStats = {}
		for stat in stats:
			totalStats[stat] = sData.StatGroups[group][stat] + jData.StatGroups[group][stat]
		groupedStats[group] = totalStats
	var genname = "%s %s" % [sData["Spec"], jData["Role"]]
	var combinePassives = sData["Passive"]
	combinePassives.merge(jData["Passive"])
	unitData[tag] = groupedStats
	unitData[tag]["Profile"] = {"UnitName" : genname}
	unitData[tag]["Profile"].merge({"Class" : jData["Role"]})
	unitData[tag]["Profile"].merge(pStats.get_art(unitData[tag].Profile.UnitName))
	unitData[tag]["Profile"].merge({"Level": 1})
	#unitData[tag]["CLIFE"] = unitData[tag]["Bases"]["LIFE"]
	unitData[tag]["MaxInv"] = 6
	unitData[tag]["Inv"] = []
	unitData[tag]["Passive"] = combinePassives
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
		"BLADE":[{"ID":"SLVKNF", "DUR":40}],
		"BLUNT":[{"ID":"CLB", "DUR":40}],
		"STICK":[],
		"GOHEI":[],
		"BOOK":[],
		"FAN":[],
		"BOW":[],
		"GUN":[],
		"ACC":[],
		"ITEM":[]
		}
	
