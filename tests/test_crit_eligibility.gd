extends SceneTree


func _initialize() -> void:
	var unit := UnitSim.new()
	unit.total_stats = {"Eleg": 10, "Cha": 3, "Pwr": 4, "Mag": 0, "Cele": 10, "Def": 0}
	unit.weapon = {"crit": 0}
	unit.recompute_derived_state()
	assert(not unit.combat_data.CanCrit and unit.combat_data.Crit == 0)
	unit.weapon.crit = 15
	unit.recompute_derived_state()
	assert(unit.combat_data.CanCrit and unit.combat_data.Crit == 25)
	assert(not unit.get_skill_combat_stats({"crit": 0}).CanCrit)
	assert(not unit.get_skill_combat_stats({"crit": null}).CanCrit)
	assert(unit.get_skill_combat_stats({"crit": 5}).CanCrit)
	assert(unit.get_skill_combat_stats({"crit": 0}, true).CanCrit)
	assert(not unit.get_skill_combat_stats({"crit": 5, "can_crit": false}, true).CanCrit)
	unit.weapon.crit = 0
	unit.recompute_derived_state()
	assert(unit.get_skill_combat_stats({"crit": 5}, true).CanCrit)
	assert(not unit.get_skill_combat_stats({"crit": 0}, true).CanCrit)
	# Eligibility must not trust stale or inflated derived-stat snapshots.
	unit.combat_data["Crit"] = 200
	unit.combat_data["CanCrit"] = true
	assert(not unit.can_action_crit(null, true))
	assert(not unit.can_action_crit({"crit": 0}, false))
	assert(unit.can_action_crit({"crit": 100}, false))
	unit.weapon.crit = 100
	assert(unit.can_action_crit(null, true))
	assert(not unit.can_action_crit({"crit": 100, "can_crit": false}, true))
	unit.free()
	print("Critical eligibility checks passed")
	quit()
