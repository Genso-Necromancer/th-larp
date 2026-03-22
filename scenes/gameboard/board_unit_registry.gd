extends RefCounted
class_name BoardUnitRegistry

var board: GameBoard


func _init(owner: GameBoard) -> void:
	board = owner


func is_occupied(cell: Vector2i) -> bool:
	return board.units.has(cell)


func get_unit(cell: Vector2i) -> Unit:
	if not board.units.has(cell):
		return null
	return board.units[cell]


func set_unit(cell: Vector2i, unit: Unit) -> void:
	board.units[cell] = unit
	if unit != null:
		board.unit_refs[unit.unit_id] = unit


func clear_cell(cell: Vector2i) -> void:
	if board.units.has(cell):
		board.units.erase(cell)


func relocate_unit(old_cell: Vector2i, new_cell: Vector2i, unit: Unit) -> void:
	clear_cell(old_cell)
	set_unit(new_cell, unit)


func swap_units(unit1: Unit, unit2: Unit) -> void:
	if unit1 == null or unit2 == null:
		return
	var cell1 := unit1.cell
	var cell2 := unit2.cell
	unit1.relocate_unit(cell2, false)
	unit2.relocate_unit(cell1, false)
	set_unit(cell1, unit2)
	set_unit(cell2, unit1)


func add_to_death_list(unit: Unit) -> void:
	if unit == null:
		return
	unit.visible = false
	unit.is_active = false
	board.death_list.append(unit)


func wipe_dead() -> void:
	for dead in board.death_list:
		clear_unit(dead)
	board.death_list.clear()


func clear_unit(unit: Unit) -> void:
	if unit == null:
		return
	var remove := unit.cell
	var faction_id := unit.FACTION_ID
	board._remove_turn(faction_id)
	clear_cell(remove)
	if board.unit_refs.has(unit.unit_id):
		board.unit_refs.erase(unit.unit_id)
	unit.queue_free()


func remove_from_grid(unit: Unit) -> void:
	if unit == null:
		return
	clear_cell(unit.cell)
