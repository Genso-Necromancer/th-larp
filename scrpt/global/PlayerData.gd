@tool
extends Node

const pStats = preload("res://character_data/pStats.gd")

#region persistant variables
var supplyMax = 180
var supplyStats :Dictionary:
	set(value):
		supply.supply_stats = value
	get:
		return supply.supply_stats
var playerMon : int:
	set(value):
		supply.player_mon = value
	get():
		return supply.player_mon
var unitData : = {"PLAYER":{},"ENEMY":{},"NPC":{}}:
	get:
		return unitData
	set(value):
		if not Engine.is_editor_hint():
			unitData = value
var supply : PlayerSupply
var completed_chapters:Array[String] = []
var current_chapter:String
var chapter_title:String
var chapter_number: int
var _id_tag:int = 0
#endregion
var timeModData := {}
var terrainData := {}
var rosterData := {}
var roster_order:Dictionary[Enums.DEPLOYMENT,Array]={Enums.DEPLOYMENT.FORCED:[],Enums.DEPLOYMENT.DEPLOYED:[],Enums.DEPLOYMENT.UNDEPLOYED:[],Enums.DEPLOYMENT.GRAVEYARD:[]}
#var lock_order:=true
#region player action flags
var traded:bool = false
var item_used:bool = false
#endregion

func _ready():
	timeModData = {}
	_load_terrain_data()
	_load_time_mods()
	init_roster()
	init_supply()


func save()->Dictionary:
	save_unit_data()
	var saveData : Dictionary = {
		"DataType": "PlayerData",
		"RosterData": rosterData,
		"roster_order":roster_order,
		"_id_tag": _id_tag,
		"Supply":supply.get_supply_as_save_data(),
		"PlayerMon":playerMon,
		"SupplyStats":supplyStats,
		"UnitData":unitData,
		"current_chapter": current_chapter,
		"chapter_title":chapter_title,
		"chapter_number":chapter_number,
		"completed_chapters":completed_chapters
		}
	return saveData


func load_persistant(data:Dictionary):
	rosterData = data.RosterData
	_restore_roster_order(data.roster_order)
	
	#roster_order = Dictionary(data.roster_order.duplicate(),roster_order.get_typed_key_builtin(),"",null,roster_order.get_typed_value_builtin(),"",null)
	#roster_order.assign(data.roster_order)
	supply.load_supply(data.Supply)
	playerMon = data.PlayerMon
	supplyStats = data.SupplyStats
	unitData = data.UnitData
	_id_tag = data._id_tag
	for chapter in data.completed_chapters:
		completed_chapters.append(chapter)


func _restore_roster_order(saved_order:Dictionary):
	var depTypes:= Enums.DEPLOYMENT
	for key in depTypes:
		var type :int= depTypes[key]
		var wokeDot:String = "%d" % [type]
		if type == depTypes.NONE: continue
		roster_order[type] = saved_order[wokeDot]


func save_unit_data(heal_unit:bool = false)->Dictionary:
	var units:Array = get_tree().get_nodes_in_group("Unit")
	var unitParams: Dictionary = {"PLAYER":{},"ENEMY":{},"NPC":{}}
	if units.is_empty(): return unitData
	for unit:Unit in units:
		if !unit.is_inside_tree():
			continue
		#var group: String
		var faction: String = Enums.FACTION_ID.keys()[unit.FACTION_ID]
		if heal_unit: unit.apply_heal(999999)
		unitParams[faction][unit.unit_id] = unit.call("save_parameters")
	unitData = unitParams.duplicate()
	return unitData


func purge_npc_data():
	unitData.ENEMY = {}
	unitData.NPC = {}


func reset_values():
	init_roster()
	await init_supply()
	playerMon = supply.player_mon
	supplyStats = {"Max": 180, "Count": 0}
	unitData = {"PLAYER":{},"ENEMY":{},"NPC":{}}


func generate_yk_id()->StringName:
	var ykId : StringName
	ykId = "yk" + str(_id_tag)
	_id_tag += 1
	print(ykId)
	return ykId

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





#region unit stat generation
func get_unit_stats(spec:int, role:int)->Dictionary:
	var stats:Dictionary = {"Stats":{},"Growths":{},"Caps":{}, "WeaponProf":{}}
	var sData :Dictionary= pStats.get_spec(spec)
	var jData :Dictionary= pStats.get_job(role)
	for group in sData.StatGroups.keys():
		#print(group)
		for stat in sData.StatGroups[group]:
			#print(stat)
			stats[group][stat] = sData.StatGroups[group][stat] + jData.StatGroups[group][stat]
			#if group == "Stats":
				#print(stats.Stats[stat])
	stats["Passives"] = sData.Passives + jData.Passives
	#print(stats.Passives)
	stats["Skills"] = sData.Skills + jData.Skills
	#print(stats.Skills)
	if sData.get("MoveType"): stats["MoveType"] = maxi(sData.MoveType, jData.MoveType)
	else: stats["MoveType"] = jData.MoveType
	#print(stats.MoveType)
	if sData.get("MaxInv") and jData.get("MaxInv"): stats["MaxInv"] = maxi(sData.MaxInv, jData.MaxInv)
	else: stats["MaxInv"] = jData.MaxInv
	#print(stats.MaxInv)
	for wep in jData.Weapons:
		var nextProf : bool = false
		if jData.get("Weapons") and jData.Weapons[wep]: nextProf = jData.Weapons[wep]
		elif sData.get("Weapons") and sData.Weapons[wep]: nextProf = sData.Weapons[wep]
		stats.WeaponProf[wep] = nextProf
	#print(stats.WeaponProf)
	return stats
#endregion


func level_up(unit:Unit, levelups:int): #consider reach bands for stat normalization. Growth rates are a spook tho.
	var rng:= RngTool.new()
	var growth_check : float
	var results = _get_blank_results()
	var leveled_features :Dictionary = {"Skills":unit.leveled_skills, "Passives":unit.leveled_passives}
	#print("Level Up Sequence[%s], Cycles:%d" % [unit.unit_id, levelups])
	for level in levelups:
		if unit.unit_level >= 20: break
		unit.unit_level += 1
		results["LVL"] += 1
		#print("Cycle %d" % [results["LVL"]])
		for req in leveled_features.Skills:
			if unit.unit_level >= req and !unit.skills.has(leveled_features.Skills[req]):
				results.NewSkills.append(leveled_features.Skills[req])
		for req in leveled_features.Passives:
			if unit.unit_level >= req and !unit.passives.has(leveled_features.Passives[req]):
				results.NewPassives.append(leveled_features.Passives[req])
		for stat in unit.base_stats:
			var increase:=rng.growth_check(unit.total_growth[stat])
			increase = clampi(increase,0,(unit.total_caps[stat] - unit.total_stats[stat]))
			results.StatGains[stat] += increase
			unit.level_stats[stat] += increase
		#print("Loops left: %d" % [(levelups-results["LVL"])])
	#print("Final Results")
	#print("unit.level_stats: %s" % [unit.level_stats])
	#print("Results.StatGains %s" % [results.StatGains])
	return results


func _get_blank_results()->Dictionary:
	var results:Dictionary = {}
	var statKeys = Enums.CORE_STAT.keys()
	results["LVL"] = 0
	results["NewSkills"] = []
	results["NewPassives"] = []
	results["StatGains"] = {}
	for key in statKeys:
		results.StatGains[key.to_pascal_case()] = 0
	return results


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
	var art :Dictionary = _validate_art(pStats.get_art(genData.Profile.unit_name))
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
	print_rich("[color=green]Added to PlayerData[/color]:", id)


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
	
#func level_up(uData, loops): #consider reach bands for stat normalization. Growth rates are a spook tho.
	#var rng = RandomNumberGenerator.new()
	#randomize()
	#var growth_check
	#var i = 0
	#var results = {}
	#var firstLoop = true
	#var stats = uData.Stats.keys()
	#results["LVL"] = 0
	#while loops > 0:
		#uData.Profile.Level += 1
		#results["LVL"] += 1
		#while i < stats.size():
			#growth_check = rng.randf_range(0.00, 1.0)
			#if growth_check <= uData.Growths[stats[i]] and uData.Stats[stats[i]] < uData.Caps[stats[i]]:
				#uData.Stats[stats[i]] += 1
				#if firstLoop: results[stats[i]] = 1
				#else: results[stats[i]] += 1
			#growth_check = rng.randf_range(0.00, 1.0)
			#if uData.Growths[stats[i]] >= 1.0 and growth_check <= (uData.Growths[stats[i]] - 1.0) and uData.Stats[stats[i]] < uData.Caps[stats[i]]:
				#uData.Stats[stats[i]] += 1
				#results[stats[i]] += 1
			#i += 1
		#loops -= 1
		#firstLoop = false
	#return results
#region Roster
func init_roster():
	rosterData.clear()
	roster_order = {Enums.DEPLOYMENT.FORCED:[],Enums.DEPLOYMENT.DEPLOYED:[],Enums.DEPLOYMENT.UNDEPLOYED:[],Enums.DEPLOYMENT.GRAVEYARD:[]}
	add_to_roster("remilia")
	add_to_roster("sakuya")
	add_to_roster("patchouli")
	add_to_roster("meiling")
	add_to_roster("reimu")


func add_to_roster(unit_id:String):
	var resourcePath := "res://scenes/units/player_units/%s.tscn" % [unit_id]
	var rosterDataEntry : Dictionary = {"Path": resourcePath, "deployment":Enums.DEPLOYMENT.NONE, "hidden":false,}
	rosterData[unit_id] = rosterDataEntry
	roster_order[Enums.DEPLOYMENT.UNDEPLOYED].append(unit_id)


func order_in_roster(unit_id:String, new_roster_status:Enums.DEPLOYMENT, old_roster_status:Enums.DEPLOYMENT = Enums.DEPLOYMENT.NONE)->void:
	var depo := Enums.DEPLOYMENT
	#if lock_order: return
	if old_roster_status:
		roster_order[old_roster_status].erase(unit_id)
	else:
		_find_remove_unit_in_order(unit_id)
	
	match  new_roster_status:
		depo.FORCED,depo.DEPLOYED,depo.GRAVEYARD: 
			roster_order[new_roster_status].append(unit_id)
		depo.UNDEPLOYED:
			roster_order[new_roster_status].push_front(unit_id)


func _find_remove_unit_in_order(unit_id:String) -> void:
	for group in roster_order:
		if roster_order[group].has(unit_id): roster_order[group].erase(unit_id)
#endregion


func init_supply():
	if supply: supply.reset_state()
	else: supply = load("res://scrpt/resources/PlayerSupply.tres")
