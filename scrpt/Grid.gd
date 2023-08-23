## Represents a grid with its size, the size of each cell in pixels, and some helper functions to
## calculate and convert coordinates.
## It's meant to be shared between game objects that need access to those values.
class_name Grid
extends Resource


## The grid's rows and columns.
@export var region := Rect2i(Vector2i(0, 0), Vector2i(640, 360))
@export var size := Vector2(20, 20)
## The size of a cell in pixels.
@export var cell_size := Vector2(64, 24)
@export var game_map : GameMap


## Half of ``cell_size``
var _half_cell_size = cell_size / 2
#func _ready():
#

## Returns the position of a cell's center in pixels.
func calculate_map_position(grid_position: Vector2) -> Vector2:
#	#print("calculate_map_position", grid_position, cell_size, _half_cell_size, grid_position * cell_size + _half_cell_size)
	#print(grid_position)
	return grid_position * cell_size + _half_cell_size


## Returns the coordinates of the cell on the grid given a position on the map.
func calculate_grid_coordinates(map_position: Vector2) -> Vector2:
#	#print("calculate_grid_coordinates", map_position, cell_size, (map_position / cell_size).floor())
	
	return (map_position / cell_size).floor()


# Returns true if the `cell_coordinates` are within the grid.
func is_within_bounds(cell_coordinates: Vector2) -> bool:
#	var out := cell_coordinates.x >= 0 and cell_coordinates.x < size.x
#	return out and cell_coordinates.y >= 0 and cell_coordinates.y < size.y
	return true
#
#
### Makes the `grid_position` fit within the grid's bounds.
func grid_clamp(grid_position: Vector2) -> Vector2:
	var out := grid_position
	out.x = clamp(out.x, 0, size.x - 1.0)
	out.y = clamp(out.y, 0, size.y - 1.0)
	return grid_position
