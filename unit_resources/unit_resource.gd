@tool
extends Resource
class_name UnitResource


@export var id: String = ""


@export_category("Rules")
var sub_rule
@export var rule_type : Enums.RULE_TYPE = Enums.RULE_TYPE.NONE: ##Determins requirements for equipping. Specifically Species and Role
	set(value):
		if value == Enums.EFFECT_TYPE.NONE: sub_rule = 0
		rule_type = value
		notify_property_list_changed()


#region property list shit
func _get_property_list():
	var properties = []
	
	match rule_type:
		Enums.RULE_TYPE.TIME: 
			properties.append({
				"name" : "sub_rule",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.TIME)
				#"hint_string" : _array_to_string(UnitData.get_item_keys())
			})
		Enums.RULE_TYPE.SELF_SPEC, Enums.RULE_TYPE.TARGET_SPEC:
			properties.append({
				"name" : "sub_rule",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.SPEC_ID)
				#"hint_string" : _array_to_string(UnitData.get_item_keys())
			})
		
	return properties


func _enum_to_string(e, seperator = ",") -> String:
	var string = ""
	var arr = e.keys()
	for i in arr:
		if i =="":continue
		string += str(i)+seperator
	return string
#endregion


func get_property_names() -> Array[String]:
	var propList : Array[Dictionary] = get_property_list()
	var propNames : Array[String] = []
	for prop in propList:
		if prop.name in self:
			propNames.append(prop.name)
	return propNames
