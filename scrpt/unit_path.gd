## Draws the unit's movement path using an autotile.
extends TileMapLayer
class_name UnitPath


#@export var grid: Resource

#var _pathfinder: PathFinder
var current_path := PackedVector2Array()



## Creates a new PathFinder that uses the AStar algorithm to find a path between two cells among
## the `walkable_cells`.
#func initialize(mapRect, mapCellSize, walkable_cells: Array) -> void:
#	_pathfinder = PathFinder.new(mapRect, mapCellSize, walkable_cells)
##	#print("unit_path: ", grid)
#
##	#print("unit_path", walkable_cells)


## Finds and draws the path between `cell_start` and `cell_end`
func draw(path: PackedVector2Array) -> void:
	clear()
	#print("Cell Start/End", cell_start, cell_end)
#	cell_start = grid.calculate_grid_coordinates(cell_start)
#	cell_end = grid.calculate_grid_coordinates(cell_end)
	current_path = path
#	print("current_path: ", current_path)
	set_cells_terrain_connect(current_path, 0, 0)


## Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	clear()
