extends UnitResource
class_name Aura

@export var range : int
@export var is_self := false
@export var target_team : Enums.TARGET_TEAM = Enums.TARGET_TEAM.NONE
@export var target : Enums.EFFECT_TARGET = Enums.EFFECT_TARGET.NONE
@export var effects : Array[Effect] = []


func convert_to_data() -> Dictionary:
	var values := _get_values()
	values["path"] = resource_path
	values["range"] = range
	values["is_self"] = is_self
	values["target_team"] = target_team
	values["target"] = target
	values["effects"] = []
	for effect in effects:
		if effect:
			values["effects"].append(effect.convert_to_data())
	return values


static func from_data(data: Dictionary) -> Aura:
	if data == null:
		return null

	var path := String(data.get("path", ""))
	var aura: Aura = null
	if path != "" and ResourceLoader.exists(path):
		aura = load(path) as Aura
	else:
		aura = Aura.new()

	aura.range = int(data.get("range", aura.range))
	aura.is_self = bool(data.get("is_self", aura.is_self))
	aura.target_team = int(data.get("target_team", aura.target_team))
	aura.target = int(data.get("target", aura.target))
	aura.effects.clear()
	for effect_data in data.get("effects", []):
		var effect := Effect.from_data(effect_data)
		if effect:
			aura.effects.append(effect)
	return aura
