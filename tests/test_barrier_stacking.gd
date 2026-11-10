extends SceneTree


func _initialize() -> void:
	var unit := UnitSim.new()
	unit.total_stats = {"Eleg": 8, "Def": 6, "Cha": 0, "Cele": 0, "Pwr": 0, "Mag": 0}
	unit.terrain_bonus = {"DefBonus": 3}
	unit.active_buffs = {
		"chance": {"source": Enums.EFFECT_SOURCE.BUFF, "effect": _bonus(Enums.SUB_TYPE.BARPRC, 5)}
	}
	# Weapon chance, accessory chance, expected total (7 natural + 3 terrain + 5 buff).
	for example in [[30, 40, 55], [50, 40, 65], [40, 40, 55], [30, 0, 45], [0, 40, 55], [0, 0, 15]]:
		unit.weapon = {"barrier": 2, "barrier_chance": example[0]}
		unit.equipped_effects = [_bonus(Enums.SUB_TYPE.BARRIER, 4), _bonus(Enums.SUB_TYPE.BARPRC, example[1])]
		unit.recompute_derived_state()
		assert(unit.combat_data.Barrier == 6, "Barrier amounts must remain additive")
		assert(unit.combat_data.BarPrc == example[2], "Equipment chance must use the higher source")
	unit.free()
	print("Barrier stacking checks passed")
	quit()


func _bonus(sub_type: int, value: int) -> Dictionary:
	return {"type": Enums.EFFECT_TYPE.BUFF, "sub_type": sub_type, "value": value}
