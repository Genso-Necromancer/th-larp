@tool
extends TileMapLayer

class_name NarrativeLayer

##As you add narraitve_tiles to the map, their coordinates will be added and automatically assigned an ID [int]. Like wise, they will be removed when erasing a tile.
##IDs persist even when removing tiles, if you have tile 0, 1; 2 then erase 1, you will have 0; 2.
##The ID can be changed manually if needed. Ensure you never assign the same ID twice.
@export var tileIDs : Dictionary[Vector2i,int] = {}
var _usedIDs : Array[int] = []

var usedTiles : Array[Vector2i] = []:
	set(value): #maybe add automatic numbering?
		var ntkeys = tileIDs.keys()
		var i : int = 0
		for tile in ntkeys:
			if !value.has(tile): 
				_usedIDs.erase(tileIDs[tile])
				tileIDs.erase(tile)
				
			
		for tile in value:
			if !tileIDs.has(tile): 
				while _usedIDs.has(i):
					i += 1
				_usedIDs.append(i)
				tileIDs[tile] = i
			
		usedTiles = value
		notify_property_list_changed.call_deferred()
		print(tileIDs.keys())


			#update_configuration_warnings()
			#
	
	
func _process(_delta):
	if usedTiles != get_used_cells():
		usedTiles = get_used_cells()

func get_narrative_tile(id:int) -> Vector2i:
	var tile : Vector2i = tileIDs.find_key(id)
	if tile: return tile
	else: 
		print("BaseGameMap: get_narrative_tile: id not found")
		return Vector2i.ZERO
		
