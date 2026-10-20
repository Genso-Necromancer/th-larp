@tool
extends SlotWrapper
class_name Feature

## Stable skill/passive ID used for saves, names, and icons. Also sets the inherited ID.
@export var feature_id : String:
	set(value):
		feature_id = value
		id = value
@export_category("Rules")
## Time of day or species required by Rule Type; ignored when Rule Type is NONE.
var sub_rule
## Optional condition for this feature. TIME checks time of day; SELF_SPEC checks the owner; TARGET_SPEC checks the target.
@export var rule_type : Enums.RULE_TYPE:
	set(value):
		rule_type = value
		if value == Enums.RULE_TYPE.NONE: sub_rule = 0
		notify_property_list_changed()



func _get_property_list():
	var properties = []
	
	match rule_type:
		Enums.RULE_TYPE.TIME: 
			properties.append({
				"name" : "sub_rule",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.TIME)
			})
		Enums.RULE_TYPE.SELF_SPEC, Enums.RULE_TYPE.TARGET_SPEC:
			properties.append({
				"name" : "sub_rule",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.SPEC_ID)
			})
		
	return properties


func _enum_to_string(e, seperator = ",") -> String:
	var string = ""
	var arr = e.keys()
	for i in arr:
		string += str(i)+seperator
	return string

func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["Class"] = "Feature"
	return values
