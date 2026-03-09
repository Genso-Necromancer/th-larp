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
	var dmg:int
	var reduction:int = _get_damage_reduction(target, effect.sub_type)
	dmg = effect.value - reduction
	return dmg

func _get_damage_reduction(target:UnitSim, damage_type:Enums.DAMAGE_TYPE)->int:
	var reduction:int
	var targetDef:int
	var targetDR:int = target.combat_data.get(&"DRes",0)
	match damage_type:
		Enums.DAMAGE_TYPE.PHYS: targetDef = target.active_stats.get(&"Def",0)
		Enums.DAMAGE_TYPE.MAG: targetDef = target.active_stats.get(&"Mag", 0)
		Enums.DAMAGE_TYPE.TRUE: 
			targetDef = 0
			targetDR = 0
	reduction = targetDef + targetDR
	return reduction

func _factor_healing(actor:UnitSim, target:UnitSim, effect) -> int:
	var bonusEff := 0
	#Add checks for bonus effects here
	var statBonus : int
	var healPower : int
	if effect.from_item:
		statBonus = 0
	else:
		statBonus = actor.active_stats.get(&"Mag", 0)
	healPower = effect.value + statBonus + bonusEff
	print("Target Life: ", target.current_life, " Heal:", healPower, " New Life Total: ", target.current_life)
	return healPower


func _speed_check(unit1:UnitSim, unit2:UnitSim) -> bool:
	var unit1Spd = unit1.active_stats.get(&"Cele", 0)
	var unit2Spd = unit2.active_stats.get(&"Cele", 0)
	print("Checking speed... ","Unit1 Spd: ", unit1Spd, " Required Spd: ", str(unit2Spd+Global.spdGap))
	if unit1Spd >= (unit2Spd + Global.spdGap):
		print("Passed, follow-up allowed")
		return true
	print("Failed")
	return false
