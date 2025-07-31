@tool
extends SlotWrapper
class_name Feature

@export var feature_id : String: ##this overwrites parent var 'id'. just call that for consistency
	set(value):
		feature_id = value
		id = value
@export_category("Rules")
var sub_rule
@export var rule_type : Enums.RULE_TYPE: ##Determins requirements for equipping. Specifically Species and Role
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
