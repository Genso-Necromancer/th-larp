extends Label

class_name TerrainName


##constructs a string names on given terrain Ids and set it's text
func get_and_set_name(id1:StringName, id2:StringName) -> void:
	var adjectivePath : String = "terrain_adjective_%s"
	var basePath : String = "terrain_name_%s"
	var finalString : String
	if !id1 and !id2: 
		print("TerrainName: get_and_set_name: Terrain Ids missing!")
		return
	
	#if id2 == "Bridge":
		#basePath = basePath % [id2.to_lower()]
		#finalString = StringGetter.get_string(basePath)
	#el
	if id2:
		adjectivePath = adjectivePath % [id1.to_lower()]
		basePath = basePath % [id2.to_lower()]
		finalString = "%s %s" % [StringGetter.get_string(adjectivePath), StringGetter.get_string(basePath)]
	else: 
		basePath = basePath % [id1.to_lower()]
		finalString = StringGetter.get_string(basePath)
	
	set_text(finalString)
