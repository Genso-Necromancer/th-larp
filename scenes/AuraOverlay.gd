
class_name AuraOverlay
extends TileMap
#@export var grid: Resource

var auraDataBase := {}
		

func draw_aura(cells: Array) -> void:
	clear()
	for cell in cells:
#		print("draw2:", cell)
		set_cell(0, cell, 6, Vector2i(0,0))

func toggle_visibility() -> void:
	set_visible(!is_visible())
	
#func get_max_aura_range():
	#pass
#
#func add_aura(aura, unit):
	#auraDataBase[aura.Id] = {"Range": 0, "Cells":{}}
	
	#for auraId in auraDataBase:
		#if aura.Range > auraId.Range:
			#
