extends Label

##Like a stat value label, but specifically for terrain
class_name TerrainValueLabel

var defaultText : String = get_text()


##Name of node must match it's desired keyword
func update_yourself_now(type1: StringName, type2: StringName) -> void:
	var tData : Dictionary = UnitData.terrainData
	var value : int = 0
	var key : StringName = name
	
	if key == "WallType" and type2:
		_update_wall_value(type2)
		return
	elif key == "WallType":
		_set_parent_visible()
		return
	
	if !tData[type1]:
		print("TerrainValueLabel: update_yourself_now: Invalid type1 or missing Terrain Data")
		_set_parent_visible()
		return
	elif type2 and !tData[type2]:
		print("TerrainValueLabel: update_yourself_now: Invalid type2, or missing Terrain Data")
		_set_parent_visible()
		return
		
	if type2: value += tData[type2][key]
	if type2 != "Bridge": value += tData[type1][key]
	
	
	_set_parent_visible(value)
	set_text(defaultText % [value])
	

func _set_parent_visible(value: int = 0):
	var hBox = get_parent()
	if value > 0 or value < 0: hBox.visible = true
	else:
		match name:
			"GrzBonus": hBox.visible = true
			"DefBonus": hBox.visible = true
			_: hBox.visible = false


func _update_wall_value(wallType : StringName) -> void:
	var stringPath : String = "terrain_label_%s" % [wallType.to_snake_case()]
	
	if wallType != "Wall" and wallType != "WallShoot" and wallType != "WallFly": 
		_set_parent_visible()
		return
		
	set_text(StringGetter.get_string(stringPath))
	_set_parent_visible(1)
