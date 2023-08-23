## Draws a selected unit's walkable tiles.
class_name UnitOverlay
extends TileMap
#@export var grid: Resource

## Fills the tilemap with the cells, giving a visual representation of the cells a unit can walk.
func draw(cells: Array) -> void:
	clear()
	for cell in cells:
#		print("draw2:", cell)
		set_cell(0, cell, 0, Vector2i(0,0))
		
func draw_attack(cells: Array) -> void:
	clear()
	for cell in cells:
#		print("draw2:", cell)
		set_cell(0, cell, 1, Vector2i(0,0))
		
func draw_threat(walk: Array, threat: Array) -> void:
	clear()
	for cell in threat:
#		print("draw2:", cell)
		set_cell(0, cell, 1, Vector2i(0,0))
	for cell in walk:
#		print("draw2:", cell)
		set_cell(0, cell, 0, Vector2i(0,0))
	
	
