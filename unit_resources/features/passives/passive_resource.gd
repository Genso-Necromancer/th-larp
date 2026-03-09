@tool
extends Feature
class_name Passive

@export var type : Enums.PASSIVE_TYPE = Enums.PASSIVE_TYPE.NONE
@export var proc: int = 100 ## 0-100 lower to make passive random, not valid with all passives.
@export var sub_type : Enums.SUB_TYPE = Enums.SUB_TYPE.NONE
@export var sub_weapon: Enums.WEAPON_SUB
@export var day_id : String
@export var night_id :String
@export var value : int = 0
@export var string_value : StringName
@export_category("Auras")
@export var is_time_sens : bool = false
@export var aura : Aura
@export var day : Aura
@export var night : Aura



func get_resource_path() -> String:
	var path: String = "res://unit_resources/features/passives/%s.tres" % id
	return path

func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["path"] = resource_path if resource_path != "" else get_resource_path()
	values["type"] = int(type)
	values["proc"] = int(proc)
	values["sub_type"] = int(sub_type)
	values["sub_weapon"] = int(sub_weapon)
	values["day_id"] = day_id
	values["night_id"] = night_id
	values["value"] = int(value)
	values["string_value"] = string_value
	values["is_time_sens"] = bool(is_time_sens)
	values["aura"] = aura
	values["day_aura"] = day
	values["night_aura"] = night
	# Resource references stored as paths for save data
	# shouldn't actually be necessary as loading the passive's path will come with these loaded
	values["aura_path"] = aura.resource_path if aura else ""
	values["day_aura_path"] = day.resource_path if day else ""
	values["night_aura_path"] = night.resource_path if night else ""
	
	return values

static func from_data(data: Dictionary) -> Passive:
	if data == null:
		return null

	var path := String(data.get("path", ""))
	var p: Passive = null

	if path != "" and ResourceLoader.exists(path):
		p = load(path) as Passive
	else:
		p = Passive.new()

	if data.has("type"): p.type = int(data["type"])
	if data.has("proc"): p.proc = int(data["proc"])
	if data.has("sub_type"): p.sub_type = int(data["sub_type"])
	if data.has("sub_weapon"): p.sub_weapon = int(data["sub_weapon"])

	if data.has("day_id"): p.day_id = String(data["day_id"])
	if data.has("night_id"): p.night_id = String(data["night_id"])

	if data.has("value"): p.value = int(data["value"])
	if data.has("string_value"): p.string_value = data["string_value"]

	if data.has("is_time_sens"): p.is_time_sens = bool(data["is_time_sens"])

	var ap := String(data.get("aura_path", ""))
	if ap != "" and ResourceLoader.exists(ap):
		p.aura = load(ap)

	var dp := String(data.get("day_aura_path", ""))
	if dp != "" and ResourceLoader.exists(dp):
		p.day = load(dp)

	var np := String(data.get("night_aura_path", ""))
	if np != "" and ResourceLoader.exists(np):
		p.night = load(np)

	return p
