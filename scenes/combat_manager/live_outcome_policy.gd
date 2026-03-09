extends CombatOutcomePolicy
class_name LiveOutcomePolicy

var resolver:CombatServiceBase # CombatResolver

func begin(p_resolver:CombatServiceBase) -> void:
	resolver = p_resolver

func decide_hit(hit_chance: int) -> bool:
	hit_chance = resolver.clamp_chance(hit_chance)
	return resolver.roll_1_to_100() <= hit_chance

func decide_crit(crit_chance: int) -> bool:
	crit_chance = resolver.clamp_chance(crit_chance)
	return resolver.roll_1_to_100() <= crit_chance

func decide_crit_dmg(min:int,max:int) -> int:
	min=clampi(min,0,99)
	max=clampi(max,0,99)
	return resolver.roll_range(min,max)

func decide_effect_proc(proc_chance: int) -> bool:
	proc_chance = resolver.clamp_chance(proc_chance)
	return resolver.roll_1_to_100() <= proc_chance
