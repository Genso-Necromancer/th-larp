@tool
extends Feature
class_name Passive

@export var type : Enums.PASSIVE_TYPE = Enums.PASSIVE_TYPE.NONE
@export var sub_type : Enums.SUB_TYPE = Enums.SUB_TYPE.NONE
@export var sub_weapon:Enums.WEAPON_SUB
@export var day_id : String
@export var night_id :String
@export var value : int = 0
@export var string_value : StringName
@export_category("Auras")
@export var is_time_sens : bool = false
@export var aura : Aura
@export var day : Aura
@export var night : Aura


func get_resource_path()->String:
	var path:String = "res://unit_resources/features/passives/%s.gd" % id
	return path
