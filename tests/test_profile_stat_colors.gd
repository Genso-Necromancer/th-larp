extends SceneTree


class TestUnit:
	extends Unit
	var test_weapon: Weapon

	func get_equipped_weapon() -> Weapon:
		return test_weapon if test_weapon != null else unarmed


func _initialize() -> void:
	var unit := TestUnit.new()
	unit.base_stats_final = {"Cele": 10}
	unit.base_combat = {"HitBase": 20}
	unit.combat_data = {"Hit": 85}
	unit.test_weapon = Weapon.new()
	unit.test_weapon.stats = WeaponResource.new()
	unit.test_weapon.stats.hit = 65
	var label := LabelValue.new()
	var neutral := Color("dddddd")
	label.add_theme_color_override("font_color", neutral)
	label.key1 = &"active_stats"
	label.key2 = &"Cele"
	_check(label, unit, 12, label.boosted_color)
	_check(label, unit, 8, label.reduced_color)
	_check(label, unit, 10, neutral)
	label.key1 = &"combatData"
	label.key2 = &"Hit"
	_check(label, unit, 85, neutral)
	_check(label, unit, 80, label.reduced_color)
	_check(label, unit, 90, label.boosted_color)
	unit.test_weapon = null
	unit.combat_data.Hit = 20
	_check(label, unit, 20, neutral)
	label.key1 = &"current_life"
	_check(label, unit, 1, neutral)
	label.free()
	unit.free()
	print("Profile stat color checks passed")
	quit()


func _check(label: LabelValue, unit: Unit, value: int, expected: Color) -> void:
	label._update_stat_color(unit, value)
	assert(label.get_theme_color("font_color") == expected, "Unexpected profile stat color")
