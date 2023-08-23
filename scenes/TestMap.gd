extends TileMap
class_name GameMap
signal mapReady

enum TERRAIN {
	Flat = 1,
	Fort = 2,
	Hill = 3
}
var tileSet = tile_set
var tileSize : Vector2 = tileSet.get_tile_size()
var tileShape = tileSet.get_tile_shape()
var lossConditions: Array
@export var gameTime = 12

func _ready():
	emit_signal("mapReady")
	lossConditions = ["Kill Lady"]
#	print(tileSize)
func cell_clamp(grid_position: Vector2) -> Vector2:
	var out := grid_position
	out.x = clamp(out.x, 0, get_used_rect().size.x - 1.0)
	out.y = clamp(out.y, 0, get_used_rect().size.y - 1.0)
	
	return grid_position
func hex_centered(grid_position: Vector2) -> Vector2:
	var tileCenter = grid_position * tileSize + tileSize / 2
	return tileCenter
	

func get_movement_cost(cell):
	var cost = 1
	var tileData = get_cell_tile_data(1, cell)
	var type
	if !tileData == null: 
		
		type = tileData.get_custom_data("terrainType")
		
	else: type = "Flat"
	return type
func get_bonus(cell):
	var bonus = 0
	var tileData = get_cell_tile_data(1, cell)
	if !tileData == null: 
			bonus = tileData.get_custom_data("terrainBonus")
	return bonus
