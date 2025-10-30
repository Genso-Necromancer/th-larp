## Draws the unit's movement path using an autotile.
extends TileMapLayer
class_name UnitPath

var current_path := PackedVector2Array()
var path_groups:Array[Array] = []
var path_array:Array[Vector2i] = []


func draw(path: PackedVector2Array) -> void:
	clear()
	current_path = path
	set_cells_terrain_connect(current_path, 0, 0)


func stop() -> void:
	clear()


func update_pathing_array(unit:Unit, wayPoint:Vector2i, map:GameMap): #Pathing
	var path :Array[Vector2i]= []
	var start : Vector2i = unit.cell
	if path_array: start = path_array[-1]
	path = get_path_to_cell(start, wayPoint, map, unit)
	path_groups.append(path)
	path_array.append_array(path)


func get_path_to_cell(start:Vector2i, end:Vector2i, map:GameMap, unit = false)->Array[Vector2i]: #Pathing
	var hexStar = AHexGrid2D.new(map)
	return hexStar.find_path(start, end, unit) #HEX REF


func remove_last_segment():
	path_groups.pop_back()
	path_array.clear()
	for group in path_groups:
		path_array.append_array(group)
	

func clear_path():
	path_groups.clear()
	path_array.clear()
	clear()
