extends CombatOutcomePolicy
class_name LiveOutcomePolicy

var resolver:CombatServiceBase # CombatResolver
var last_hit_roll := -1
var last_crit_roll := -1
var last_effect_roll := -1

func begin(p_resolver:CombatServiceBase) -> void:
	resolver = p_resolver
	last_hit_roll = -1
	last_crit_roll = -1
	last_effect_roll = -1

func decide_hit(hit_chance: int) -> bool:
	hit_chance = resolver.clamp_chance(hit_chance)
	last_hit_roll = resolver.roll_1_to_100()
	return last_hit_roll <= hit_chance

func decide_crit(crit_chance: int) -> bool:
	crit_chance = resolver.clamp_chance(crit_chance)
	last_crit_roll = resolver.roll_1_to_100()
	return last_crit_roll <= crit_chance

func decide_crit_dmg(min:int,max:int) -> int:
	min=clampi(min,0,99)
	max=clampi(max,0,99)
	return resolver.roll_range(min,max)

func decide_effect_proc(proc_chance: int) -> bool:
	proc_chance = resolver.clamp_chance(proc_chance)
	last_effect_roll = resolver.roll_1_to_100()
	return last_effect_roll <= proc_chance
