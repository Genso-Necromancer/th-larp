extends RefCounted
class_name CombatOutcomePolicy

func begin(_resolver) -> void:
	pass

func decide_hit(_hit_chance: int) -> bool:
	return false

func decide_crit(_crit_chance: int) -> bool:
	return false
	
func decide_crit_dmg(min:int,max:int) -> int:
	return 0

func decide_effect_proc(_proc_chance: int) -> bool:
	return false
