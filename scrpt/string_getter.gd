extends Node


func get_string(category, id) -> String:
	var p = XMLParser.new()
	var s : String
	var k : Array = Enums.LANGUAGE.keys()
	var l : String = k[Global.language]
	var pos : int = 0
	var er : String = "[color=#00FFFF]%s[/color]" % [str(id)]
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
	var base = get_string("tools", "effect_chance")
	var efName = get_string("tools", "name_sleep")
	var chance = 100
	var varArray : Array
	varArray.append(efName)
	varArray.append(chance)
	var s : String = mash_string(base, varArray)
	print(s)
		
		
func mash_string(base: String, variables: Array) -> String:
	var s : String
	s = base % variables
	return s
#HERE String Masher function needed. Pass the p.get_node_type() to a junk checker and it'll actually work.
