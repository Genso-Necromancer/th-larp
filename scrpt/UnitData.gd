extends Node

const pStats = preload("res://character_data/pStats.gd")

var unitData : Dictionary = {}
#var groupKeys = ["ProfKeys", "StatKeys", "StatKeys", "StatKeys"]
var groups = ["Profile", "Stats", "Growths", "Caps"]
#"CLIFE",
var stats = ["MOVE", "LIFE", "COMP", "PWR", "MAG", "ELEG", "CELE", "BAR", "CHA"]
var jobData = {}
var specData = {}
var wepData = {}
var plrInv = {}
var npcInv = {}
var terrainCosts = {}
var skillData : Dictionary = {}
var effectData: Dictionary = {}

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
	wepData = pStats.get_wep()
	terrainCosts = pStats.get_terrain_costs()
	skillData = pStats.get_skills()
	effectData = pStats.get_skill_effects()

func stat_gen(tag : String = "Null", level : int = 1, spec : String = "Null", job : String = "Null"):
	if tag == "Null" or job  == "Null" or spec == "Null":
		return 
	var groupedStats = {}
	var statId = 0
	var groupId = 1
	
	groupedStats.clear()
	while groupId < groups.size():
		var totalStats = {}
		while statId < stats.size():
			totalStats[stats[statId]] = specData[spec][groups[groupId]][stats[statId]] + jobData[job][groups[groupId]][stats[statId]]
			statId += 1
		groupedStats[groups[groupId]] = totalStats
		groupId += 1
	var genname = "%s %s" % [specData[spec]["Spec"], jobData[job]["Role"]]
	var combinePassives = specData[spec]["Passive"]
	combinePassives.merge(jobData[job]["Passive"])
	unitData[tag] = groupedStats
	unitData[tag]["Profile"] = {"UnitName" : genname}
	unitData[tag]["Profile"].merge({"Class" : jobData[job]["Role"]})
	unitData[tag]["Profile"].merge(pStats.get_art(unitData[tag].Profile.UnitName))
	unitData[tag]["Profile"].merge({"Level": level})
	unitData[tag]["CLIFE"] = unitData[tag]["Stats"]["LIFE"]
	unitData[tag]["Inv"] = []
	unitData[tag]["Passive"] = combinePassives
#	scale_unit(tag, level)
	
func scale_unit(tag: String, level: int):
	pass
	
func add_weapon(unitId, weapon):
	if unitData[unitId].Inv.size() <= 4:
		unitData[unitId].Inv.merge({weapon : wepData[weapon]})
		unitData[unitId].merge({"EQUIP" : wepData[weapon].NAME})
	else:
		print("Invetory Full")
		

func add_inv(itemID, isPlayer, getId = false):
	var breakOut = 0
	var uniqueID
	var ID = 0
	var inv
	match isPlayer:
		true:
			inv = plrInv
		false: 
			inv = npcInv
	uniqueID = itemID + str(ID)
	while inv.has(uniqueID):
		ID += 1
		uniqueID = itemID + str(ID)
		breakOut += 1
		if breakOut >= 100:
			print("Could not generate unique ID")
			return
	inv[uniqueID] = wepData[itemID].duplicate(true)
	if wepData[itemID].LIMIT:
		inv[uniqueID]["DUR"] = wepData[itemID].MAXDUR
	if getId:
		return uniqueID


func get_experience(action, totalExp, targLvl, unitStats, growths, caps):
	var gainExp = 0
	match action:
		"attack":  
				gainExp  = (21 + targLvl - unitStats[0]) / 2
				gainExp = clampi(gainExp, 1, 100)
				
		"defeat": 
			gainExp = ((21 + targLvl - unitStats[0]) / 2) + (targLvl - unitStats[0])
			gainExp = clampi(gainExp, 1, 100)
		"pacifist": 
			gainExp = (21 + unitStats[0])
			gainExp = clampi(gainExp, 1, 100)
			
	totalExp = totalExp + gainExp
	while totalExp >= 100:
		totalExp -= 100
		totalExp = clampi(totalExp, 0, 10000)
		unitStats = level_up(unitStats, growths, caps)
	return [totalExp, unitStats]
	
func level_up(unitStats, growths, caps):
	var rng = RandomNumberGenerator.new()
	randomize()
	var growth_check
	var arrayInd = 0
	unitStats[0] += 1
	arrayInd += 1
	while arrayInd < unitStats.size():
		growth_check = rng.randf_range(0.01, 1.0)
		if growth_check <= growths[arrayInd]:
			unitStats[arrayInd] += 1
			if growths[arrayInd] >= 1.0 and growth_check <= growths[arrayInd] - 1.0:
				unitStats[arrayInd] += 1
			clampi(unitStats[arrayInd], 0, caps[arrayInd])
			arrayInd += 1
		else:
			arrayInd += 1
	rng.queue_free()
	return unitStats
	
