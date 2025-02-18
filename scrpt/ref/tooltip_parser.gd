extends RefCounted

class_name ToolTipParser

var buffColor : Color = Color(0.392, 0.584, 0.929)
var debuffColor : Color = Color(0.357, 0.141, 0.549)


func get_passive(data: Dictionary) -> String:
	var converted : Dictionary = data.duplicate()
	var enumKeys : Array = Enums.PASSIVE_TYPE.keys()
	var finished : String
	var working : String = ""
	working = StringGetter.get_string("lore_" + Enums.PASSIVE_TYPE.keys()[data.Type].to_snake_case())

	match data.Type:
		Enums.PASSIVE_TYPE.AURA: 
			var aura : String
			var morph : String
			var reverseTime : String
			var timeRule : String
			var restrict : String
			match Global.timeOfDay:
					Enums.TIME.NIGHT:
						aura = str(data.get("Night", ""))
						morph = str(data.get("Day", ""))
						restrict = "night"
						reverseTime = "day"
					Enums.TIME.DAY:
						aura = str(data.get("Day", ""))
						morph = str(data.get("Night", ""))
						restrict = "day"
						reverseTime = "night"
			if data.Night and data.Day:
				timeRule = StringGetter.get_string("lore_morph_" + reverseTime)
				timeRule = timeRule.format({"Morph":"[color=#FFD700]"+StringGetter.get_string("passive_name_"+morph.to_snake_case())+"[/color]"})
			elif data.IsTimeSens:
				timeRule = StringGetter.get_string("lore_restrict_" + restrict)
			else: aura = data.Aura
			
			var auraData = UnitData.auraData[aura]
			
			if auraData.Range > 1:
				converted["Range"] = StringGetter.get_string("lore_range")
			else: converted["Range"] = StringGetter.get_string("lore_range_adjacent")
			converted.Range = converted.Range.format(auraData)
			converted["TargetTeam"] = StringGetter.get_string("lore_" + Enums.TARGET_TEAM.keys()[auraData.TargetTeam].to_snake_case())
			
			var first := true
			converted["Effects"] = ""
			
			for eff in auraData.Effects:
				if !first:
					first = false
					converted.Effects += " & "
				converted.Effects += StringGetter.get_effect_string(eff)
			
			converted["Target"] = StringGetter.get_string("lore_aura_" + Enums.EFFECT_TARGET.keys()[auraData.Target].to_snake_case())
			converted.Aura = converted.Target.format(converted)
			
			if timeRule: 
				converted.Aura += "\n" + timeRule
				
		Enums.PASSIVE_TYPE.VANTAGE: pass
		Enums.PASSIVE_TYPE.NIGHT_PROT: pass
		Enums.PASSIVE_TYPE.DAY_PROT: pass
		Enums.PASSIVE_TYPE.STAT_CHANGE: pass
		Enums.PASSIVE_TYPE.RESPONSE: pass
		Enums.PASSIVE_TYPE.FATED: pass
		Enums.PASSIVE_TYPE.SUB_WEAPON:  converted.SubType = StringGetter.get_string("lore_" + Enums.WEAPON_CATEGORY.keys()[data.SubType].to_snake_case())
	
	converted.RuleType = StringGetter.get_string("lore_" + Enums.RULE_TYPE.keys()[data.get("RuleType",0)].to_snake_case())
	
	match data.get("RuleType",0):
		Enums.RULE_TYPE.SELF_SPEC: enumKeys = Enums.SPEC_ID.keys()
		Enums.RULE_TYPE.TIME: enumKeys = Enums.TIME.keys()
		Enums.RULE_TYPE.TARGET_SPEC: enumKeys = Enums.SPEC_ID.keys()

	converted.Rule = StringGetter.get_string("lore_" + enumKeys[data.get("Rule",0)].to_snake_case())
	converted.RuleType = converted.RuleType.format(converted)
	finished = working.format(converted)
	
	return finished


func get_skill(data:Dictionary) -> String:
	var finished : String
	var effectString := ""
	var ruleString := ""
	var working := ""
	var converted := {}
	for key in data:
		if !data[key]:
			continue
		elif key == "Rule":
				continue
		elif key == "RuleType":
			var value
			var ruleKey = Enums.RULE_TYPE.keys()[data.RuleType].to_snake_case()
			match data[key]:
				Enums.RULE_TYPE.TIME: value = "time_" + Enums.TIME.keys()[data.Rule].to_snake_case()
				Enums.RULE_TYPE.TARGET_SPEC: value = "species_name_" + Enums.SPEC_ID.keys()[data.Rule].to_snake_case()
				Enums.RULE_TYPE.SELF_SPEC: value = "species_name_" + Enums.SPEC_ID.keys()[data.Rule].to_snake_case()
				Enums.RULE_TYPE.MORPH: value = "time_" + Enums.TIME.keys()[Global.timeOfDay].to_snake_case()
			converted["Rule"] = StringGetter.get_string(str(value))
			#converted["Rule"] = StringGetter.get_string("lore_" + ruleKey + "_" + str(value))
			ruleString = "{RuleType}"
		elif key == "Effects":
			var first := true
			var effString := ""
			var effStringSelf := ""
			var effStringTarget := ""
			var effStringGlobal := ""
			var effStringEquip := ""
			
			for eff in data[key]:
				var effData = UnitData.effectData[eff]
				var string := ""
				if first: 
					effectString = "{Effects}"
					first = false
				else: string += "\n"
				string += StringGetter.get_effect_string(eff)
				match effData.Target:
					Enums.EFFECT_TARGET.SELF: effStringSelf += string
					Enums.EFFECT_TARGET.TARGET: effStringTarget += string
					Enums.EFFECT_TARGET.GLOBAL:  effStringGlobal += string
					Enums.EFFECT_TARGET.EQUIPPED: effStringEquip += string
				
			if effStringSelf: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.SELF].to_snake_case()) + "\n"
				effString += effStringSelf
			if effStringTarget: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.TARGET].to_snake_case()) + "\n"
				effString += effStringTarget
			if effStringGlobal: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.GLOBAL].to_snake_case()) + "\n"
				effString += effStringGlobal
			if effStringEquip: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.EQUIPPED].to_snake_case()) + "\n"
				effString += effStringEquip
			
			converted[key] = effString
		
		if key != "Effects": converted[key] = StringGetter.get_string(str(key+"_"+str(data[key])).to_snake_case())
	
	if ruleString and effectString:
		working = ruleString + "\n" + effectString
	elif ruleString:
		working += ruleString
	elif effectString:
		working += effectString
	
	finished = _mash_together(working, converted)
	return finished
	
	
func get_lore(data: Dictionary, key:String) -> String:
	var string : String
	var finished : String
	
	var stringPath:= "lore_"
	
	key.to_pascal_case()
	
	match key:
		"UnitName": 
			var title : String = StringGetter.get_string("lore_title_" + data[key].to_snake_case())
			var uName : String = StringGetter.get_string("unit_name_" + data[key].to_snake_case())
			var titleString = "%s - %s" % [uName, title]
			stringPath = str(stringPath,uName).to_snake_case()
			string = titleString + "\n" + StringGetter.get_string(stringPath)
		"Role", "Species": 
			stringPath = str(stringPath,key,"_",data[key]).to_snake_case()
			string = StringGetter.get_string(stringPath)
		"Level", "EXP": 
			stringPath = str(stringPath,key).to_snake_case()
			string = StringGetter.get_string(stringPath)
			
	
	finished = string
	
	return finished


func get_active(unit:Unit, keyStat:String) -> String:
	var keyBase : String = "baseStats"
	var keyTotal : String = "activeStats"
	var string = _generate_stat_tt(unit, keyBase, keyTotal,keyStat,)
	return string
	
	
func get_combat(unit:Unit, keyStat:String) -> String:
	var keyBase : String = "baseCombat"
	var keyTotal : String = "combatData"
	var string = _generate_stat_tt(unit, keyBase, keyTotal, keyStat,)
	return string


func _generate_stat_tt(unit:Unit, keyBase:String, keyTotal:String, keyStat: String) -> String:
	var string : String
	var fString : String = ""
	var finished : String
	var stringPath:= "lore_"
	#var dataPath = unit[keyTotal][keyStat]
	#var wep = UnitData.itemData[unit.get_equipped_weapon().ID]
	
	if keyStat != "MoveType": 
		fString = str(keyStat,": ",unit[keyBase][keyStat]," %s") % _generate_formula([(unit[keyTotal][keyStat] - unit[keyBase][keyStat])])
		string = StringGetter.get_string((stringPath+keyStat.to_snake_case()))
	
	
	match keyStat:
		"Barrier":
			var barprc: String = StringGetter.get_string(stringPath+"barprc")
			string = str(string, "\n", barprc)
			var bPFormula: String = _generate_formula([(unit[keyTotal]["BarPrc"] - unit[keyBase]["BarPrc"])])
			fString = fString + str("\n","Barrier Chance: ",unit[keyTotal].BarPrc,"%% %s") % bPFormula
		"Dmg": pass
		"Hit": pass
		"Graze": pass
		"Crit": pass
		"Luck": pass
		"Resist" : pass
		"EffHit": pass
		"DRes": pass
		"MoveType": 
			var moveCosts :Dictionary = UnitData.terrainCosts[unit[keyTotal][keyStat]]
			var count := 0
			fString += StringGetter.get_string("move_cost_title") + "\n"
			for terrain in moveCosts:
				fString += StringGetter.get_string("terrain_"+terrain.to_snake_case()) + str(moveCosts[terrain])
				count += 1
				if count < moveCosts.size():
					fString += "\n"
			string = StringGetter.get_string((stringPath+keyStat.to_snake_case()+"_"+Enums.MOVE_TYPE.keys()[unit[keyTotal][keyStat]].to_snake_case()))
		
		
	finished = fString + "\n" + string
	
	return finished


func _generate_formula(params:Array):
	var string: String = "(%s)"
	var formula: String = ""
	for p in params:
		var color: String = "[color=%s]"
		var value :String = "%+-d" % p
		if p == 0:
			continue
		elif value.begins_with("+"): 
			color = color % buffColor.to_html(true)
		else: 
			color = color % debuffColor.to_html(true)
		value = color+value+"[/color]"
		formula += value
	if formula != "": 
		string = string % formula
		
	else: 
		string = string % "+0"
	
	return string


func get_status(unit:Unit, status:String) -> String:
	var sParams = unit.sParam
	var parts := {}
	var working : String
	var finished : String
	working += "{Status}"
	parts["Status"] = StringGetter.get_string("status_"+status.to_snake_case())
	if sParams.get(status,false):
		working += "\n" + StringGetter.get_string("remaining_label")
		parts["Duration"] = str(sParams[status].get("Duration", ""))
		var durationType = Enums.DURATION_TYPE.keys()[sParams[status].DurationType]
		parts["DurationType"] = StringGetter.get_string("duration_"+durationType.to_snake_case())
	
	finished = _mash_together(working, parts)
	return finished


func _mash_together(string: String, stringDick : Dictionary) -> String:
	var catch := 0
	while "{" in string:
		string = string.format(stringDick)
		catch += 1
		if catch >10:
			break
	return string
