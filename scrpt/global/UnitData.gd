@tool
extends Node

const pStats = preload("res://character_data/pStats.gd")

var supplyMax = 180
var supplyStats :Dictionary = {"Max": 180, "Count": 0}
var playerMon : int = 100

var unitData : = {}:
	get:
		return unitData
	set(value):
		if not Engine.is_editor_hint():
			unitData = value
			
var skillData : = {}

var timeModData := {}

var terrainData := {}


var rosterData := []

var supply : Dictionary[String,Array] = {}
var npcInv = {}

var rosterOnce := false





func _ready():
	#var index = 0
	unitData = {}
	skillData = {}

	timeModData = {}
	
	_load_unique_units()
	_load_terrain_data()
	_load_time_mods()
	#print(timeModData)
	init_roster()
	init_supply()

func _load_unique_units():
	unitData = pStats.get_named_unit_data()
	#for unit in unitData:
		#unitData[unit]["DataType"] = Enums.DATA_TYPE.UNIT


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
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Graze": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
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
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Graze": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
							"MagDef": 0,
							"PhysDef": 0,
							"MoveType": false,
						}
					
}
			var innerKeys = rawData[key][Enums.TIME.DAY].keys()
			for iKey in innerKeys:
				timeModData[key][Enums.TIME.DAY][iKey] = rawData[key][Enums.TIME.DAY][iKey]
				timeModData[key][Enums.TIME.NIGHT][iKey] = rawData[key][Enums.TIME.NIGHT][iKey]



func _load_terrain_data():
	var rawData = pStats.get_terrain_data()
	
	for key in rawData:
			terrainData[key] = {
				"GrzBonus": 0,
				"DefBonus": 0,
				"PwrBonus": 0,
				"MagBonus": 0,
				"HitBonus": 0,
				"Special": 0,
				"HpRegen": 0,
				"CompRegen": 0,
				"Price": 0,
				Enums.MOVE_TYPE.FOOT: 0,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER:0,
			}
			var innerKeys = rawData[key].keys()
			for iKey in innerKeys:
				terrainData[key][iKey] = rawData[key][iKey]


func get_generated_sprite(species, job):
	var s = pStats.load_generated_sprite(species, job)
	return s


func stat_gen(job :int, spec : int):
	#Need overhaul1!!!!
	
	var groupedStats = {}
	#var jData = jobData[job].duplicate(true)
	var sData = pStats.get_spec(spec)
	var jData = pStats.get_job(job)
	var groups = sData.StatGroups.keys()
	var stats = sData.StatGroups.Stats.keys()
	var specKeys = Enums.SPEC_ID.keys()
	var genData := {}
	groupedStats.clear()
	for group in groups:
		var totalStats = {}
		for stat in stats:
			totalStats[stat] = sData.StatGroups[group][stat] + jData.StatGroups[group][stat]
		groupedStats[group] = totalStats
	var genname = "%s %s" % [specKeys[sData["Spec"]].to_pascal_case(), jData["Role"]]
	var combinePassives = sData["Passives"] + jData["Passives"]
	var combineSkills = sData["Skills"] + jData["Skills"]
	#combinePassives.merge(jData["Passives"])
	genData = groupedStats
	genData["Profile"] = {"UnitName" : genname}
	genData["Profile"].merge({"Role" : jData["Role"]})
	genData["Profile"].merge({"Species" : sData["Spec"]})
	var art :Dictionary = _validate_art(pStats.get_art(genData.Profile.UnitName))
	genData["Profile"].merge(art)
	genData["Profile"].merge({"Level": 1})
	genData["Profile"].merge({"Exp": 00})
	#genData["CurLife"] = genData["Bases"]["Life"]
	genData["MaxInv"] = 6
	genData["Inv"] = []
	genData["Passives"] = combinePassives
	genData["Skills"] = combineSkills
	genData["Weapons"] = jData.Weapons
	genData["MoveType"] = sData["MoveType"]
	return genData

func add_to_unitdata(data, id):
	unitData[id] = data
	print_rich("[color=green]Added to UnitData[/color]:", id)

func generate_id():
	var u := false
	var c := 0
	var unitId : String
	if not Engine.is_editor_hint():
		while !u:
			unitId = "yk" + str(c)
			if unitData.has(unitId):
				c += 1
				#print_rich("[color=red]IT'S HAPPENING[/color]:",c)
			else:
				u = true
		#print("GENERATED ID:",unitId)
		#if c > 5:
			#print_rich("[color=red]UnitData[/color]:", UnitData.unitData.keys())
		return unitId


func _validate_art(art:Dictionary) -> Dictionary:
	var valid := {"Prt": "res://sprites/Fairy TroublemakerPrt.png", "FullPrt": "res://sprites/character/cirno/portrait_full.png"}
	if ResourceLoader.exists(art.Prt):
		valid.Prt = art.Prt
	if ResourceLoader.exists(art.FullPrt):
		valid.FullPrt = art.FullPrt
	return valid

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
	
func level_up(uData, loops): #consider reach bands for stat normalization. Growth rates are a spook tho.
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
		rosterData.append("Reimu")
		rosterData.append("Patchouli")
		rosterData.append("Meiling")
		
		rosterOnce = true
	return


func init_supply():
	supply = {
		"BLADE":[],
		"BLUNT":["res://unit_resources/items/weapons/club.tres"],
		"STICK":[],
		"GOHEI":[],
		"BOOK":[],
		"OFUDA":[],
		"BOW":[],
		"GUN":[],
		"ACC":[],
		"ITEM":[],
		}
