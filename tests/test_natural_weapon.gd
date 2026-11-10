extends SceneTree


class TestUnit extends Unit:
	func update_stats():
		pass

	func validate_active_effect_skills():
		pass


func _initialize() -> void:
	var unit := TestUnit.new()
	unit.buff_controller = BuffController.new(unit)
	unit.equipment_helper = EquipmentHelper.new(unit)
	var passive: Passive = load("res://unit_resources/features/passives/martial.tres")
	for level in [1, 3, 4, 5, 6, 15, 16, 25, 26, 35, 36, 40]:
		unit.unit_level = level
		unit._update_natural(passive)
		assert(unit.natural.dmg == 1 + floori(level / 4.0))
		assert(unit.natural.hit == 65 + level)
		assert(unit.natural.barrier == 2 + floori(level / 6.0))
		unit._update_natural(passive)
		assert(unit.natural.hit == 65 + level, "Scaling must not accumulate")

	var weapon := Weapon.new(load("res://unit_resources/items/weapons/polearm/polearm_charge_basic.tres"))
	unit.inventory.append(weapon)
	unit.set_equipped(unit.natural)
	assert(unit.get_multi_swing() == 2)
	var snapshot := unit.equipment_helper.snapshot_equipment_state()
	unit.set_equipped(weapon, true)
	assert(unit.get_multi_swing() == false, "Fists must not grant double strike to polearms")
	assert(not unit.natural.equipped)
	unit.restore_equip()
	assert(unit.get_equipped_weapon() == unit.natural)
	assert(unit.get_multi_swing() == 2)
	unit.set_equipped(weapon)
	unit.set_equipped(unit.natural, true)
	unit.restore_equip()
	assert(unit.get_equipped_weapon() == weapon)
	assert(unit.get_multi_swing() == false)
	unit.equipment_helper.restore_equipment_state(snapshot)
	assert(unit.get_equipped_weapon() == unit.natural)
	assert(unit.inventory.size() == 1 and unit.inventory[0] == weapon)
	unit.set_equipped()
	unit.set_equipped()
	assert(unit.equipment_helper.equipped_effects.size() == 1)
	assert(unit.get_multi_swing() == 2)
	var sim := UnitSim.new()
	sim.equipped_effects = unit._effects_to_sim_data(unit.equipment_helper.equipped_effects)
	assert(sim.get_multi_swing() == 2)
	sim.free()
	unit.free()
	print("Natural weapon checks passed")
	quit()
