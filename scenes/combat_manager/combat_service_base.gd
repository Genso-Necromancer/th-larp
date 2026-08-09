extends Node
class_name CombatServiceBase

var cm: CombatManager
var rng_tool: RngTool
var gameBoard: GameBoard

func roll_1_to_100() -> int:
	# IMPORTANT: no randomize() here; state-based RNG stays deterministic.
	return rng_tool.rng.randi_range(1, 100)

func roll_range(min:int,max:int) ->int:
	return rng_tool.rng.randi_range(min,max)

func clamp_chance(p: int) -> int:
	return clampi(p, 0, 1000)

func _factor_dmg(target:UnitSim, effect:Effect) -> int:
	if typeof(effect.value) == TYPE_FLOAT:
		return _factor_life_percent(target, float(effect.value))

	var dmg:int
	var reduction:int = _get_damage_reduction(target, effect.sub_type)
	dmg = effect.value - reduction
	return max(0, dmg)

func _get_damage_reduction(target:UnitSim, damage_type:Enums.DAMAGE_TYPE)->int:
	var reduction:int
	var targetDef:int
	var targetDR:int = target.combat_data.get(&"DRes",0)
	var terrainDef:int = int(target.get_terrain_bonus().get("DefBonus", 0))
	match damage_type:
		Enums.DAMAGE_TYPE.PHYS: targetDef = target.active_stats.get(&"Def",0) + terrainDef
		Enums.DAMAGE_TYPE.MAG: targetDef = target.active_stats.get(&"Mag", 0)
		Enums.DAMAGE_TYPE.TRUE: 
			targetDef = 0
			targetDR = 0
	reduction = targetDef + targetDR
	return reduction

func _factor_healing(actor:UnitSim, target:UnitSim, effect) -> int:
	if typeof(effect.value) == TYPE_FLOAT:
		return _factor_life_percent(target, float(effect.value))

	var bonusEff := 0
	#Add checks for bonus effects here
	var statBonus : int
	var healPower : int
	if effect.from_item:
		statBonus = int(floor(float(actor.active_stats.get(&"Mag", 0)) / 2.0))
	else:
		statBonus = actor.active_stats.get(&"Mag", 0)
	healPower = effect.value + statBonus + bonusEff
	print("Target Life: ", target.current_life, " Heal:", healPower, " New Life Total: ", target.current_life)
	return healPower

func _factor_life_percent(target: UnitSim, pct: float) -> int:
	if target == null:
		return 0
	var max_life := int(target.active_stats.get("Life", target.total_stats.get("Life", target.current_life)))
	return max(0, int(round(float(max_life) * pct)))

func _factor_life_steal(damage_dealt: int, value) -> int:
	if damage_dealt <= 0:
		return 0
	if typeof(value) == TYPE_FLOAT:
		return max(0, int(round(float(damage_dealt) * float(value))))
	return max(0, int(round(float(damage_dealt) * float(int(value)) / 100.0)))


func _speed_check(unit1:UnitSim, unit2:UnitSim) -> bool:
	var unit1Spd = unit1.active_stats.get(&"Cele", 0)
	var unit2Spd = unit2.active_stats.get(&"Cele", 0)
	if unit1Spd >= (unit2Spd + Global.spdGap):
		return true
	return false


func _range_band_hit_penalty(source, distance: int) -> int:
	if _is_distance_in_range_band(source, distance, "close") or _is_distance_in_range_band(source, distance, "far"):
		return int(Global.RANGE_BAND_HIT_PENALTY)
	return 0


func _has_brace_effect(target: UnitSim) -> bool:
	if target == null:
		return false
	return (
		_effect_array_has_type(target.equipped_effects, Enums.EFFECT_TYPE.BRACE)
		or _effect_pool_has_type(target.active_buffs, Enums.EFFECT_TYPE.BRACE)
		or _effect_pool_has_type(target.active_debuffs, Enums.EFFECT_TYPE.BRACE)
	)


func _effect_array_has_type(effects: Array, effect_type: int) -> bool:
	for effect_data in effects:
		if int(_source_value(effect_data, "type", Enums.EFFECT_TYPE.NONE)) == effect_type:
			return true
	return false


func _effect_pool_has_type(pool: Dictionary, effect_type: int) -> bool:
	for entry in pool.values():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var effect_data = entry.get("effect", {})
		if int(_source_value(effect_data, "type", Enums.EFFECT_TYPE.NONE)) == effect_type:
			return true
	return false


func _is_distance_in_range_band(source, distance: int, prefix: String) -> bool:
	if source == null:
		return false
	var min_reach := int(_source_value(source, "%s_min_reach" % prefix, 0))
	var max_reach := int(_source_value(source, "%s_max_reach" % prefix, 0))
	if min_reach == 0 and max_reach == 0:
		return false
	if min_reach == 0:
		min_reach = max_reach
	if max_reach == 0:
		max_reach = min_reach
	return distance >= min_reach and distance <= max_reach


func _source_value(source, key: String, default_value = null):
	if source == null:
		return default_value
	if typeof(source) == TYPE_DICTIONARY:
		return source.get(key, default_value)
	var resolved = source.get(key)
	return resolved if resolved != null else default_value
