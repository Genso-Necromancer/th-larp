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
var effectData := {}
var timeModData := {}
var itemData := {}
var terrainData := {}

var passiveData := {}
var auraData := {}
var rosterData := []

var supply = {}
var npcInv = {}

var rosterOnce := false





func _ready():
	#var index = 0
	unitData = {}
	skillData = {}
	effectData = {}
	timeModData = {}
	itemData = {}
	_load_unique_units()
	_load_items()
	_load_terrain_data()
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
	#for unit in unitData:
		#unitData[unit]["DataType"] = Enums.DATA_TYPE.UNIT
	
func _load_items():
	var rawData = pStats.get_items()
	var keys = rawData.keys()
	
	for key in keys:
		itemData[key] = {
			"Name":"None",
			"Icon":load(("res://sprites/gungnir.png")),
			"Level": 1,
			"Type":"",
			"Target": 0,
			"Dmg":0,
			"Hit":0,
			"Crit":0,
			"Barrier":0,
			"MinRange":0,
			"MaxRange":0,
			"Category":"ITEM",
			"MaxDur":-1,
			"SubGroup":false,
			"Use":false,
			"Equip":false,
			"Expendable": true,
			"Trade": true,
			"Personal": false,
			"Effects":[],
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
			"Category": Enums.CATEGORY.NONE,
			"Augment": false, #Set true if weapon stats should be used.
			"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)
			"CanMiss": true, #default true
			"CanCrit": true,
			"CanDmg": true,
			##Only if Augment
			"WepCat": Enums.WEAPON_CATEGORY.ANY, #Set to required weapon category, or sub type, for skill use.
			"BonusMinRange": 0,
			"BonusMaxRange": 0,
			##If !augment, these are the parameters used as if it was a weapon. If Augment, these values are added as bonus/penalty if altered.
			"Hit": 0, #Int only. negative values acceptable for Hit penalties to the skill
			"Dmg": 0, #set an int value for damage, set false to prevent dealing damage
			"Crit": 0, #set an int value for crit bonus, set false to prevent crits
			"Type": Enums.DAMAGE_TYPE.PHYS, #use enum types. Set False if augment should use weapon's type.
			##Used regardless of Augment
			"MinRange": 1, #if 0, ignored by Augment. Set value to require specific weapon reach.
			"MaxRange": 1,
			"Cost": 0,
			"Effects": [], #any attacking effects for an augment skill must be set to instant.
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
				"Type": Enums.EFFECT_TYPE.NONE,
				"SubType": false, #Use Enums.SUB_TYPE. For Damage, use Damage Enums. Just how it's gotta be.
				"Target": Enums.EFFECT_TARGET.TARGET, #Self, Target, Global, Equipped
				"Instant": false, #only set for effects that should occur before an augment skill is rolled.
				"OnHit": true, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
				"Proc": -1, #Set to -1 to have gaurenteed proc chance
				"Duration": 0, #Unit turns the effect lasts, -1 causes the effect to be permanent. Duration is ignored entirely for on-equip effects of items.
				"DurationType": false,
				"Stack": false, #True for infinite stacking, soft limit by duration Not necessary for permanent effects. Ignored for on-equip effects.
				"Value": 0, #use 0-2 float for time speed up/slow down. #USE NEGATIVE VALUES FOR DEBUFFS, OR YOU BUFF THEM
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
				"RuleType": false,
				"Rule": false,
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

func _load_aura_data():
	var rawData = pStats.get_auras()
	
	for key in rawData:
			auraData[key] = {
						"Range": 0,
						"IsSelf": false,
						"TargetTeam": Enums.TARGET_TEAM.ALLY,
						"Target": Enums.EFFECT_TARGET.TARGET,
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
				"SubType": false,
				"Icon": load(("res://sprites/gungnir.png")),
				"Value": 0,
				"String": false,
				"IsTimeSens": false,
				"Aura": false,
				"Day": false,
				"Night": false,
				"RuleType": Enums.RULE_TYPE.NONE,
				"Rule": 0,
		}
			var innerKeys = rawData[key].keys()
			for iKey in innerKeys:
				passiveData[key][iKey] = rawData[key][iKey]


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
		rosterData.append("Meiling")
		rosterData.append("Patchouli")
		rosterData.append("Reimu")
		
		
		rosterOnce = true
	return

func init_supply():
	supply = {
		"BLADE":[{"ID":"SLVKNF", "Equip":false, "Dur":40, "UniqueId": 21451,},],
		"BLUNT":[],
		"STICK":[],
		"GOHEI":[],
		"BOOK":[],
		"FAN":[],
		"BOW":[],
		"GUN":[],
		"ACC":[],
		"ITEM":[{"ID":"PWRELIX", "Equip":false, "Dur":1,"UniqueId": 22521,}],
		}
	
func spawn_item(id:String, durability = itemData[id].MaxDur, isDropable = false) -> Dictionary:
	var template = {"ID":"id", "Equip":false, "Dur":durability, "Drop": isDropable}
	return template

func get_item_keys():
	var itemKeys : Array = pStats.get_items().keys()
	return itemKeys
