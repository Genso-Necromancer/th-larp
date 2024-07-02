extends Node

const pStats = preload("res://character_data/pStats.gd")

@export var supplyMax = 180
var unitData : Dictionary = {}
#var groupKeys = ["ProfKeys", "StatKeys", "StatKeys", "StatKeys"]
var groups = ["Profile", "Stats", "Growths", "Caps"]
#"CLIFE",
var stats = ["MOVE", "LIFE", "COMP", "PWR", "MAG", "ELEG", "CELE", "BAR", "CHA"]
var jobData = {}
var specData = {}
var itemData = {}
var supply = {}
var npcInv = {}
var terrainCosts = {}
var skillData : Dictionary = {}
var effectData : Dictionary = {}
var rosterData : Array = []
var rosterOnce : bool = false

func _ready():
	var index = 0
	#Get format UnitData.unitData["NameString"]["GroupString"]["Stat"]
	while index < pStats.UNIT_ID.size():
		unitData.merge(pStats.get_named_unit_data(index))
		index += 1
	index = 0
	while index < pStats.JOB_ID.size():
		jobData.merge(pStats.get_job(index))
		index += 1
	index = 0
	while index < pStats.SPEC_ID.size():
		specData.merge(pStats.get_spec(index))
		index += 1
	index = 0
	_load_items()
	terrainCosts = pStats.get_terrain_costs()
	skillData = pStats.get_skills()
	effectData = pStats.get_skill_effects()
	init_roster()
	init_supply()
	
	
func _load_items():
	var rawData = pStats.get_items()
	var keys = rawData.keys()
	

	for key in keys:
		itemData[key] = {
		"NAME":"None",
		"ICON":load(("res://sprites/gungnir.png")),
		"TYPE":"None",
		"DMG":0,
		"ACC":0,
		"CRIT":0,
		"GRAZE":0,
		"MINRANGE":0,
		"MAXRANGE":0,
		"CATEGORY":"ITEM",
		"MAXDUR":1,
		"SUBGROUP":false,
		"USE":false,
		"EFFECTS":{}
		}

		var innerKeys = rawData[key].keys()
		for iKey in innerKeys:
			itemData[key][iKey] = rawData[key][iKey]

func stat_gen(tag : String = "Null", level : int = 1, spec : String = "Null", job : String = "Null"):
	#Need overhaul1!!!!
	if tag == "Null" or job  == "Null" or spec == "Null":
		print("oopsie, whoopsie, no tag, job or spec!")
		return 
	var groupedStats = {}
	var statId = 0
	var groupId = 1
	var jData = jobData[job].duplicate(true)
	var sData = specData[spec].duplicate(true)
	
	groupedStats.clear()
	while groupId < groups.size():
		var totalStats = {}
		while statId < stats.size():
			totalStats[stats[statId]] = sData[groups[groupId]][stats[statId]] + jData[groups[groupId]][stats[statId]]
			statId += 1
		groupedStats[groups[groupId]] = totalStats
		groupId += 1
	var genname = "%s %s" % [sData["Spec"], jData["Role"]]
	var combinePassives = sData["Passive"]
	combinePassives.merge(jData["Passive"])
	unitData[tag] = groupedStats
	unitData[tag]["Profile"] = {"UnitName" : genname}
	unitData[tag]["Profile"].merge({"Class" : jData["Role"]})
	unitData[tag]["Profile"].merge(pStats.get_art(unitData[tag].Profile.UnitName))
	unitData[tag]["Profile"].merge({"Level": level})
	unitData[tag]["CLIFE"] = unitData[tag]["Stats"]["LIFE"]
	unitData[tag]["MaxInv"] = 6
	unitData[tag]["Inv"] = []
	unitData[tag]["EQUIP"] = null
	unitData[tag]["Passive"] = combinePassives
	unitData[tag]["Weapons"] = jData.Weapons
#	scale_unit(tag, level)
	
func scale_unit(tag: String, level: int):
	pass
	
#func add_weapon(unitId, weapon): #marked for deletion: Old
#	if unitData[unitId].Inv.size() <= 4:
#		unitData[unitId].Inv.merge({weapon : itemData[weapon]})
#		unitData[unitId].merge({"EQUIP" : itemData[weapon].NAME})
#	else:
#		print("Invetory Full")
		

#func add_inv(itemID, isPlayer, getId = false): #marked for deletion: Old
#	#clunky
#	#a third party owner of items, a storage, must be created
#	var uniqueID
#	var ID = 0
#	var inv
#	match isPlayer:
#		true:
#			inv = plrInv
#		false: 
#			inv = npcInv
#	uniqueID = itemID + str(ID)
#	while inv.has(uniqueID):
#		ID += 1
#		uniqueID = itemID + str(ID)
#		if ID >= 99:
#			print("Could not generate unique ID")
#			return
#	inv[uniqueID] = itemData[itemID].duplicate(true)
#	if itemData[itemID].LIMIT:
#		inv[uniqueID]["DUR"] = itemData[itemID].MAXDUR
#	if getId:
#		return uniqueID


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
	
func level_up(unit, loops):
	var rng = RandomNumberGenerator.new()
	randomize()
	var growth_check
	var i = 0
	var results = {}
	var firstLoop = true
	results["LVL"] = 0
	while loops > 0:
		unit.Profile.Level += 1
		results["LVL"] += 1
		while i < stats.size():
			growth_check = rng.randf_range(0.00, 1.0)
			if growth_check <= unit.Growths[stats[i]] and unit.Stats[stats[i]] < unit.Caps[stats[i]]:
				unit.Stats[stats[i]] += 1
				if firstLoop: results[stats[i]] = 1
				else: results[stats[i]] += 1
			growth_check = rng.randf_range(0.00, 1.0)
			if unit.Growths[stats[i]] >= 1.0 and growth_check <= (unit.Growths[stats[i]] - 1.0) and unit.Stats[stats[i]] < unit.Caps[stats[i]]:
				unit.Stats[stats[i]] += 1
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
		"BLADE":[{"Data":"SLVKNF", "DUR":40}],
		"BLUNT":[{"Data":"CLB", "DUR":40}],
		"STICK":[],
		"GOHEI":[],
		"BOOK":[],
		"FAN":[],
		"BOW":[],
		"GUN":[],
		"ACC":[],
		"ITEM":[]
		}
	
