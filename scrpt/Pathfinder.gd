class_name PathFinder
extends Resource

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

#var _grid: Resource
var _astar := AStarGrid2D.new()
var mapLimits

## Initializes the AstarGrid2D object upon creation.
func _init(mapRect, cellSize, walkable_cells: Array) -> void:
	mapLimits = mapRect
#	print(mapRect.size)
	_astar.size = mapRect.size
	_astar.cell_size = cellSize
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_astar.update()
	# Iterate over all points on the grid and disable any which are
	#	not in the given array of walkable cells
	for y in mapRect.size.y:
		for x in mapRect.size.x:
			if not walkable_cells.has(Vector2(x,y)):
				_astar.set_point_solid(Vector2(x,y))

## Returns the path found between `start` and `end` as an array of Vector2 coordinates.
func calculate_point_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	# With an AStarGrid2D, we only need to call get_id_path to return
	#	the expected array
#	print("calculate: ", start, end)
#	print(_astar.get_id_path(start, end))
	return _astar.get_id_path(start, end)

#func calculate_point_index(point) -> Vector2:
#	point -= Vector2(mapLimits.position)
#	return point.y * mapLimits.size.x + point.x
	
