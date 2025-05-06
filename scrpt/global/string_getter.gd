@tool
extends Node

#class_name StringGetter

func get_string(id) -> String:
	return _parse_xml("string", id)


func get_template(id) -> String:
	return _parse_xml("template", id)


func get_item_name(item:Item) -> String:
	var namePath : String = "%s_%s"
	var type : String
	if item is Weapon: type = "weapon"
	elif item is Accessory: type = "accessory"
	elif item is Ofuda: type = "ofuda"
	elif item is Consumable: type = "consumable"

	namePath = namePath % [type, item.id]
	
	return get_string(namePath)


func get_skill_name(skill:Skill) -> String:
	var namePath : String = "skill_name_%s"
	namePath = namePath % [skill.id]
	return get_string(namePath)

func _parse_xml(category, id) -> String:
	var p = XMLParser.new()
	var s : String
	var k : Array = Enums.LANGUAGE.keys()
	var l : String = k[Global.language]
	var pos : int = 0
	var er : String = "[color=#00FFFF]%s[/color]" % [id]
	p.open("xml/gui.xml")

	while p.read() == OK: #Read until correct language found or end of file
		#print(str(p.get_node_type()) + " " + str(_is_junk(p.get_node_type())))
		#print(str(XMLParser.NODE_COMMENT) + str(XMLParser.NODE_NONE) + str(XMLParser.NODE_TEXT) + str(XMLParser.NODE_UNKNOWN))
		if _is_junk(p.get_node_type()):
			continue
		if p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_node_name() == "language" and p.get_named_attribute_value_safe("id") != l:
			p.skip_section()
		elif p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_node_name() == "language" and p.get_named_attribute_value_safe("id") == l: 
			break
	
	while p.read() == OK: #If language found, searches for correct category
		#print(str(p.get_node_type()) + " " + str(_is_junk(p.get_node_type())))
		#print(str(XMLParser.NODE_COMMENT) + str(XMLParser.NODE_NONE) + str(XMLParser.NODE_TEXT) + str(XMLParser.NODE_UNKNOWN))
		if _is_junk(p.get_node_type()):
			continue
		if p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_node_name() == category:
			break
		elif p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_node_name() != category: 
			p.skip_section()

	while p.read() == OK: #If category found, searches for correct id
		#print(str(p.get_node_type()) + " " + str(_is_junk(p.get_node_type())))
		#print(str(XMLParser.NODE_COMMENT) + str(XMLParser.NODE_NONE) + str(XMLParser.NODE_TEXT) + str(XMLParser.NODE_UNKNOWN))
		if _is_junk(p.get_node_type()):
			continue
		if p.get_node_type() == XMLParser.NODE_ELEMENT and p.get_named_attribute_value_safe("id") == id:
			pos = p.get_node_offset()
			while p.get_node_type() != XMLParser.NODE_CDATA:
				p.seek(pos)
				pos += 1
			s = p.get_node_name()
			break
			
	if p.get_node_type() == XMLParser.NODE_CDATA and s != null:
		#print(s)
		return s
	else: 
		#print(er)
		return er
		
		
func _is_junk(type: int) -> bool:
	if type == XMLParser.NODE_COMMENT or type == XMLParser.NODE_NONE or type == XMLParser.NODE_TEXT or type == XMLParser.NODE_UNKNOWN:
		return true
	else:
		return false
		
		
func mash_test():
	var base = get_template("effect_chance")
	var efName = get_string("name_sleep")
	var chance = 100
	var varArray : Array = []
	varArray.append(efName)
	varArray.append(chance)
	var s : String = mash_string(base, varArray)
	print(s)
		
func get_combat_effect_string(effect:Effect) -> String: #Time to create the string XML and string getter, eh?
	#var proc = cmbData.Effects[effect].proc
	#var value = cmbData.Effects[effect].value
	var typeKeys : Array = Enums.EFFECT_TYPE.keys()
	var subKeys : Array = Enums.SUB_TYPE.keys()
	#Get Template: "Buff %s"
	var templatePath : String = "effect_template_%s" % [typeKeys[effect.type].to_lower()]
	var s : String = get_template(templatePath)
	var duration = false
	var durationType = false
	var value = effect.value
	var proc := effect.proc
	
	#Get SubType "string": "Buff Pwr"
	if effect.sub_type:
		var subTypePath := "effect_sub_type_%s" % [subKeys[effect.sub_type].to_lower()]
		var subType := get_string(subTypePath)
		s = s % [subType]
		
	#Check if Value: "Buff Power #"
	if value and value > 0:
		var v
		var path := "value_template"
		if typeof(value) == Variant.Type.TYPE_FLOAT:
			v = value * 100
			v = round(v)
			path = "percent_value_template"
		s = get_template(path) % [s, value]
	
	#Check if Proc: "Buff Power # (98%)"
	if effect.proc and effect.proc > -1:
		s = get_template("proc_template") % [s, proc]
	
	#Check if Duration and Duration Type: "string # (###%) for # dType"
	if effect.duration_type:
		durationType = effect.duration_type
	else: durationType = Enums.DURATION_TYPE.TURN
	
	if effect.duration > 0:
		var durKeys = Enums.DURATION_TYPE.keys()
		var durationPath = "duration_%s" % [durKeys[durationType].to_lower()]
		var durationString = get_string(durationPath)
		s = get_template("duration_template") % [s, effect.duration, durationString]
	
	return s
	
	
func get_effect_string(effect:Effect) -> String: #Needs reworking, see tooltip parser for help. Doesn't even include effect rule types
	#var proc = cmbData.Effects[effId].proc
	#var value = cmbData.Effects[effId].value
	var typeKeys : Array = Enums.EFFECT_TYPE.keys()
	var subKeys : Array = Enums.SUB_TYPE.keys()
	#Get Template: "Buff %s"
	var templatePath : String = "effect_template_%s" % [typeKeys[effect.type].to_lower()]
	var s : String = get_template(templatePath)
	var duration = false
	var durationType = false
	var effVal = effect.value
	
	#Get SubType "string": "Buff Pwr"
	if effect.sub_type:
		var subTypePath := "effect_sub_type_%s" % [subKeys[effect.sub_type].to_lower()]
		var subType := get_string(subTypePath)
		s = s % [subType]
	
	match effect.type:
		#get skill string if add_skill
		Enums.EFFECT_TYPE.ADD_SKILL: s = s.format({"skill":get_string("skill_name_%s" % [effect.skill.id])})
		
	#Check if Value: "Buff Power #"
	if effVal and effVal != 0:
		var v
		var path := "value_template"
		var test = typeof(effVal)
		if typeof(effVal) == Variant.Type.TYPE_FLOAT:
			v = effVal * 100
			v = round(v)
			path = "percent_value_template"
		else: v = effVal
		s = get_template(path) % [s, v]
	
	#Check if Duration and Duration Type: "string # (###%) for # dType"
	if effect.duration_type:
		durationType = effect.duration_type
	else: durationType = Enums.DURATION_TYPE.TURN
	
	if durationType == Enums.DURATION_TYPE.PERMANENT:
		var durKeys = Enums.DURATION_TYPE.keys()
		var durationPath = "duration_%s" % [durKeys[durationType].to_lower()]
		var durationString = get_string(durationPath)
		s = durationString % [s]
		
	elif effect.duration > 0:
		var durKeys = Enums.DURATION_TYPE.keys()
		var durationPath = "duration_%s" % [durKeys[durationType].to_lower()]
		var durationString = get_string(durationPath)
		s = get_template("duration_template") % [s, effect.duration, durationString]
	
	if effect.rule_type:
		var value
		var ruleKey = Enums.RULE_TYPE.keys()[effect.rule_type].to_snake_case()
		match effect.rule_type:
			Enums.RULE_TYPE.TIME: value = ("time_" + Enums.TIME.keys()[effect.sub_rule].to_snake_case())
			Enums.RULE_TYPE.TARGET_SPEC: value = ("species_name_" + Enums.SPEC_ID.keys()[effect.sub_rule].to_snake_case())
			Enums.RULE_TYPE.SELF_SPEC: value = ("species_name_" + Enums.SPEC_ID.keys()[effect.sub_rule].to_snake_case())
			Enums.RULE_TYPE.MORPH: value = ("time_" + Enums.TIME.keys()[Global.timeOfDay].to_snake_case())
		s += " " + StringGetter.get_string("effect_" + ruleKey)
		s = s.format({"rule":StringGetter.get_string(str(value))})
	
	return s

		
func mash_string(base: String, variables: Array) -> String:
	var s : String
	var dud : String = ""
	s = base % variables
	if s == dud :
		s = base
	return s
#HERE String Masher function needed. Pass the p.get_node_type() to a junk checker and it'll actually work.
