extends RefCounted

class_name ToolTipParser

var buffColor : Color = Color(0.392, 0.584, 0.929)
var debuffColor : Color = Color(0.357, 0.141, 0.549)


func get_passive(passive:Passive) -> String:
	var enumKeys : Array = Enums.PASSIVE_TYPE.keys()
	var properties := passive.get_property_names()
	var converted:Dictionary
	var finished : String
	var working : String = ""
	working = StringGetter.get_string("lore_" + Enums.PASSIVE_TYPE.keys()[passive.type].to_snake_case())
	for key in properties:
		converted[key] = ""
	match passive.type:
		Enums.PASSIVE_TYPE.AURA: 
			var aura : Aura
			var morph : Aura
			var reverseTime : String
			var timeRule : String
			var restrict : String
			var auraData := {}
			
			match Global.timeOfDay:
					Enums.TIME.NIGHT:
						aura = passive.night
						morph = passive.day
						restrict = "night"
						reverseTime = "day"
					Enums.TIME.DAY:
						aura = passive.day
						morph = passive.night
						restrict = "day"
						reverseTime = "night"
			if passive.night and passive.day:
				timeRule = StringGetter.get_string("lore_morph_" + reverseTime)
				timeRule = timeRule.format({"Morph":"[color=#FFD700]"+StringGetter.get_string("passive_name_"+str(morph.id).to_snake_case())+"[/color]"})
			elif passive.is_time_sens:
				timeRule = StringGetter.get_string("lore_restrict_" + restrict)
			else: aura = passive.aura
			properties = aura.get_property_names()
			for prop in properties:
				auraData[prop] = aura[prop]
				
			
			
			if aura.range > 1:
				converted["range"] = StringGetter.get_string("lore_range")
			else: converted["range"] = StringGetter.get_string("lore_range_adjacent")
			converted.range = converted.range.format(auraData)
			converted["target_team"] = StringGetter.get_string("lore_" + Enums.TARGET_TEAM.keys()[auraData.target_team].to_snake_case())
			
			var first := true
			converted["effects"] = ""
			
			for eff in auraData.effects:
				if !first:
					first = false
					converted.effects += " & "
				converted.effects += StringGetter.get_effect_string(eff)
			
			converted["target"] = StringGetter.get_string("lore_aura_" + Enums.EFFECT_TARGET.keys()[auraData.target].to_snake_case())
			converted.aura = converted.target.format(converted)
			
			if timeRule: 
				converted.aura += "\n" + timeRule
				
		Enums.PASSIVE_TYPE.VANTAGE: pass
		Enums.PASSIVE_TYPE.NIGHT_PROT: pass
		Enums.PASSIVE_TYPE.DAY_PROT: pass
		Enums.PASSIVE_TYPE.STAT_CHANGE: pass
		Enums.PASSIVE_TYPE.RESPONSE: pass
		Enums.PASSIVE_TYPE.FATED: pass
		Enums.PASSIVE_TYPE.SUB_WEAPON:  converted.sub_type = StringGetter.get_string("lore_" + Enums.WEAPON_CATEGORY.keys()[passive.sub_type].to_snake_case())
	
	converted.rule_type = StringGetter.get_string("lore_" + Enums.RULE_TYPE.keys()[passive.rule_type].to_snake_case())
	
	match passive.rule_type:
		Enums.RULE_TYPE.SELF_SPEC: enumKeys = Enums.SPEC_ID.keys()
		Enums.RULE_TYPE.TIME: enumKeys = Enums.TIME.keys()
		Enums.RULE_TYPE.TARGET_SPEC: enumKeys = Enums.SPEC_ID.keys()
	
	if passive.sub_rule != null:
		converted.sub_rule = StringGetter.get_string("lore_" + enumKeys[passive.sub_rule].to_snake_case())
	converted.rule_type = converted.rule_type.format(converted)
	finished = working.format(converted)
	
	return finished


func get_skill(data:SlotWrapper) -> String:
	var finished : String
	var effectString := ""
	var ruleString := ""
	var working := ""
	var converted:Dictionary
	for key in data.get_property_names():
		if !data[key]:
			continue
		elif key == "rule":
				continue
		elif key == "rule_type":
			var value
			#var ruleKey = Enums.RULE_TYPE.keys()[data.rule_type].to_snake_case()
			match data[key]:
				Enums.RULE_TYPE.TIME: value = "time_" + Enums.TIME.keys()[data.sub_rule].to_snake_case()
				Enums.RULE_TYPE.TARGET_SPEC: value = "species_name_" + Enums.SPEC_ID.keys()[data.sub_rule].to_snake_case()
				Enums.RULE_TYPE.SELF_SPEC: value = "species_name_" + Enums.SPEC_ID.keys()[data.sub_rule].to_snake_case()
				Enums.RULE_TYPE.MORPH: value = "time_" + Enums.TIME.keys()[Global.timeOfDay].to_snake_case()
			converted["sub_rule"] = StringGetter.get_string(str(value))
			#converted["Rule"] = StringGetter.get_string("lore_" + ruleKey + "_" + str(value))
			ruleString = "{rule_type}"
		elif key == "effects":
			var first := true
			var effString := ""
			var effStringSelf := ""
			var effStringtarget := ""
			var effStringGlobal := ""
			var effStringEquip := ""
			
			for effect in data.effects:
				
				var string := ""
				if first: 
					effectString = "{effects}"
					first = false
				else: string += "\n"
				string += StringGetter.get_effect_string(effect)
				match effect.target:
					Enums.EFFECT_TARGET.SELF: effStringSelf += string
					Enums.EFFECT_TARGET.TARGET: effStringtarget += string
					Enums.EFFECT_TARGET.GLOBAL:  effStringGlobal += string
					Enums.EFFECT_TARGET.EQUIPPED: effStringEquip += string
				
			if effStringSelf: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.SELF].to_snake_case()) + "\n"
				effString += effStringSelf
			if effStringtarget: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.TARGET].to_snake_case()) + "\n"
				effString += effStringtarget
			if effStringGlobal: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.GLOBAL].to_snake_case()) + "\n"
				effString += effStringGlobal
			if effStringEquip: 
				effString += StringGetter.get_string("target_" + Enums.EFFECT_TARGET.keys()[Enums.EFFECT_TARGET.EQUIPPED].to_snake_case()) + "\n"
				effString += effStringEquip
			
			converted[key] = effString
		
		if key != "effects" and key != "sub_rule": converted[key] = StringGetter.get_string(str(key+"_"+str(data[key])).to_snake_case())
	
	if ruleString and effectString:
		working =  effectString + "\n" + ruleString
	elif ruleString:
		working += ruleString
	elif effectString:
		working += effectString
	
	finished = _mash_together(working, converted)
	return finished
	
	
func get_lore(unit:Unit, key:String) -> String:
	var string : String
	var finished : String
	
	var stringPath:= "lore_%s"
	
	key.to_pascal_case()
	
	match key:
		"UnitName": 
			var title : String
			var titleString : String
			var uName : String = unit.unit_name
			if unit.unique_art: 
				title= StringGetter.get_string("lore_title_" + unit.unitId.to_snake_case())
				titleString = "%s - %s" % [uName, title]
				stringPath = str(stringPath,unit.unitId)
			else:
				var spec :String= Enums.SPEC_ID.keys()[unit.SPEC_ID].to_snake_case()
				var role :String= Enums.ROLE_ID.keys()[unit.ROLE_ID].to_snake_case()
				titleString = uName
				stringPath = stringPath + "_" + spec + "_" + role
			string = titleString + "\n" + StringGetter.get_string(stringPath)
		"Role":
			var role :String= Enums.ROLE_ID.keys()[unit.ROLE_ID].to_snake_case()
			stringPath = str(stringPath,key,"_",role).to_snake_case()
			string = StringGetter.get_string(stringPath)
		"Species": 
			var spec :String= Enums.SPEC_ID.keys()[unit.SPEC_ID].to_snake_case()
			stringPath = str(stringPath,key,"_",spec).to_snake_case()
			string = StringGetter.get_string(stringPath)
		"Level", "EXP": 
			stringPath = str(stringPath,key).to_snake_case()
			string = StringGetter.get_string(stringPath)
			
	
	finished = string
	
	return finished


func get_active(unit:Unit, keyStat:String) -> String:
	var keyBase : String = "baseStats"
	var keyTotal : String = "active_stats"
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
			var tData : Dictionary = UnitData.terrainData
			var moveCosts :Dictionary
			var count := 0
			for t in tData:
				var cost :int = tData[t][unit[keyTotal][keyStat]]
				if cost >= 99:
						moveCosts[t] = " " + StringGetter.get_string("terrain_cannot_pass")
				elif cost != 0:
					moveCosts[t] = " +" + str(cost)
				
			fString += StringGetter.get_string("move_cost_title") + "\n"
			for terrain in moveCosts:
				fString += StringGetter.get_string("terrain_"+terrain.to_snake_case()) + moveCosts[terrain]
				count += 1
				if count < moveCosts.size():
					fString += "\n"
			string = StringGetter.get_string((stringPath+keyStat.to_snake_case()+"_"+Enums.MOVE_TYPE.keys()[unit[keyTotal][keyStat]].to_snake_case()))
		
		
	finished = string + "\n" + fString
	
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
	working = "{Status}"
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
