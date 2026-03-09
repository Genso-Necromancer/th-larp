extends RefCounted
class_name CombatBranchBuilder

var resolver: CombatResolver

func _init(p_resolver: CombatResolver) -> void:
	resolver = p_resolver

# Returns a dictionary:
# {
#   "p_hit": float,
#   "hit": CombatResults,
#   "miss": CombatResults
# }
func build_hit_branches(attacker: UnitSim, defender: UnitSim, action: Dictionary) -> Dictionary:
	var clash := resolver._evaluate_clash(attacker, defender, action)
	var hit_chance := resolver.clamp_chance(int(clash.get("Hit", 0)))
	var p := float(hit_chance) / 100.0

	var swings := resolver._get_swing_count(attacker, action)
	var p_any_hit := 1.0 - pow(1.0 - p, float(swings))

	var hit_res: CombatResults = resolver.resolve_sim_hit_success(attacker.clone(), defender.clone(), action)
	var miss_res: CombatResults = resolver.resolve_sim_hit_failure(attacker.clone(), defender.clone(), action)

	return {
		"p_hit": p_any_hit,
		"hit": hit_res,
		"miss": miss_res
	}
