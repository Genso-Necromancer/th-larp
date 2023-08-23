extends TileMap
@export var grid: Resource
var _pathfinder: PathFinder
var ui_size := PackedVector2Array()
var actions = get_tree().get_nodes_in_group("ActionLabels")
@onready var textWidth = (get_node(actions).size.y + 16) / 16
@onready var textHeight = (get_node(actions).size.x + 16) / 16






## Finds and draws the path between `cell_start` and `cell_end`
func draw(cell_start: Vector2, cell_end: Vector2) -> void:
	clear()
	cell_start = Vector2(0,0)
	cell_end = Vector2(textWidth, textHeight)
	ui_size = [cell_start, cell_end]
	set_cells_terrain_connect(0, ui_size, 0, 0)


## Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	ui_size = [0]
	clear()
