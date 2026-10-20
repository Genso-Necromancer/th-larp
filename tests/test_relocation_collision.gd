extends SceneTree


class MockMap:
	extends RefCounted

	var active_units: Dictionary = {}
	var wall_masks: Dictionary = {}
	var wall_types: Dictionary = {}

	func get_used_rect() -> Rect2i:
		return Rect2i(Vector2i.ZERO, Vector2i(20, 20))

	func get_active_units() -> Dictionary:
		return active_units

	func get_wall_direction(cell: Vector2i) -> int:
		return int(wall_masks.get(cell, 0))

	func get_wall_type(cell: Vector2i) -> StringName:
		return StringName(wall_types.get(cell, &""))


func _initialize() -> void:
	var map := MockMap.new()
	var grid := AHexGrid2D.new(map)
	var actor := grid.axial_to_oddq(Vector2i(4, 3))
	var target := grid.axial_to_oddq(Vector2i(5, 3))
	var first := grid.axial_to_oddq(Vector2i(6, 3))
	var second := grid.axial_to_oddq(Vector2i(7, 3))
	var behind := grid.axial_to_oddq(Vector2i(3, 3))
	grid.mapCells.assign([behind, actor, target, first, second])

	var blocker := RefCounted.new()
	map.active_units[second] = blocker
	var shoved := grid.resolve_shove(actor, target, 3)
	assert(shoved.Hex == first)
	assert(shoved.Path == [target, first])
	assert(shoved.CollisionHex == second)
	assert(shoved.UniColl == blocker)
	assert(shoved.Travel == 1)

	map.active_units.clear()
	map.active_units[behind] = blocker
	var tossed := grid.resolve_toss(target, actor, 1)
	assert(tossed.Hex == actor)
	assert(tossed.CollisionHex == behind)
	assert(tossed.UniColl == blocker)

	map.active_units.clear()
	var clear_toss := grid.resolve_toss(target, actor, 1)
	assert(clear_toss.Hex == behind)
	assert(clear_toss.UniColl == null)

	var outgoing_bit := grid.get_wall_bit_between(target, first)
	map.wall_masks[target] = outgoing_bit
	map.wall_types[target] = &"Wall"
	var wall_shove := grid.resolve_shove(actor, target, 2)
	assert(wall_shove.Hex == target)
	assert(wall_shove.WallColl and wall_shove.CollisionHex == first)
	assert(wall_shove.UniColl == null)
	var wall_toss := grid.resolve_toss(target, actor, 1)
	assert(wall_toss.Hex == behind and not wall_toss.WallColl)

	map.wall_types[target] = &"WallFly"
	wall_shove = grid.resolve_shove(actor, target, 1)
	assert(wall_shove.WallColl and wall_shove.Hex == target)
	wall_toss = grid.resolve_toss(target, actor, 1)
	assert(wall_toss.Hex == behind and not wall_toss.WallColl)
	map.wall_masks.clear()
	map.wall_types.clear()
	map.wall_masks[second] = grid.get_opposite_wall_bit(grid.get_wall_bit_between(first, second))
	map.wall_types[second] = &"WallShoot"
	wall_shove = grid.resolve_shove(actor, target, 2)
	assert(wall_shove.Hex == first and wall_shove.WallColl)
	assert(wall_shove.CollisionHex == second)

	map.wall_masks.clear()
	map.wall_types.clear()
	var toss_bit := grid.get_wall_bit_between(actor, behind)
	map.wall_masks[behind] = grid.get_opposite_wall_bit(toss_bit)
	map.wall_types[behind] = &"WallShoot"
	wall_toss = grid.resolve_toss(target, actor, 1)
	assert(wall_toss.Hex == actor and wall_toss.WallColl)
	assert(wall_toss.CollisionHex == behind)

	map.wall_types[behind] = &"WallFly"
	map.wall_masks[actor] = toss_bit
	map.wall_types[actor] = &"Wall"
	wall_toss = grid.resolve_toss(target, actor, 1)
	assert(wall_toss.WallColl)

	map.wall_masks.clear()
	map.wall_types.clear()
	map.wall_masks[actor] = grid.get_wall_bit_between(actor, target)
	map.wall_types[actor] = &"WallShoot"
	wall_toss = grid.resolve_toss(target, actor, 1)
	assert(wall_toss.Hex == target and wall_toss.WallColl)
	assert(wall_toss.CollisionHex == actor)
	map.wall_types[actor] = &"WallFly"
	wall_toss = grid.resolve_toss(target, actor, 1)
	assert(wall_toss.Hex == behind and not wall_toss.WallColl)
	quit()
