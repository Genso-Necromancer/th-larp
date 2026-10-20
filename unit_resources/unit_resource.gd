@tool
extends Resource
class_name UnitResource


## Stable resource ID used by saves and text lookups. Keep it unique and consistent with the resource filename.
@export var id: String = ""


@export_category("Rules")
## Time of day or species required by Rule Type; ignored when Rule Type is NONE.
var sub_rule
## Optional activation/equipment condition. TIME uses Sub Rule; SELF_SPEC checks the owner, TARGET_SPEC checks the target.
@export var rule_type : Enums.RULE_TYPE = Enums.RULE_TYPE.NONE:
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
				#"hint_string" : _array_to_string(PlayerData.get_item_keys())
			})
		Enums.RULE_TYPE.SELF_SPEC, Enums.RULE_TYPE.TARGET_SPEC:
			properties.append({
				"name" : "sub_rule",
				"type" : TYPE_INT,
				"hint" : PROPERTY_HINT_ENUM,
				"hint_string" : _enum_to_string(Enums.SPEC_ID)
				#"hint_string" : _array_to_string(PlayerData.get_item_keys())
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

func _format_to_id() -> String:
	var path = get_path()
	var new_id : String
	var count : int = path.get_slice_count("/")
	var slice :String = path.get_slice("/",count)
	new_id = slice.trim_suffix(".tres")
	print(id)
	print(new_id)
	return new_id

func get_resource_path()->String:
	var path:String = ""
	return path

func convert_to_data()->Dictionary:
	var converted:Dictionary={}
	converted = _get_values()
	return converted

func _get_values()->Dictionary:
	var values:Dictionary ={}
	values["id"] = id
	values["sub_rule"] = sub_rule
	values["rule_type"] = rule_type
	return values
