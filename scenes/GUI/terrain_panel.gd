extends PanelContainer

class_name TerrainPanel


func update_terrain_data(cell:Vector2i) -> void:
	var map : GameMap = Global.flags.CurrentMap
	var tags := map.get_terrain_tags(cell)
	var lock : TextureRect = $TerrainMargin/TerrainHBox/TexturePanel/TextureMargin/LockIcon
	
	if tags: 
		get_tree().call_group("TerrainName", "get_and_set_name", tags.BaseId, tags.ModId)
		get_tree().call_group("TerrainValue", "update_yourself_now", tags.BaseType, tags.ModType)
		lock.visible = tags.Locked
		_set_preview_tiles(cell, map)

func _set_preview_tiles(cell:Vector2i, map: GameMap) -> void:
	var base :TileMapLayer = $TerrainMargin/TerrainHBox/TexturePanel/BaseLayer
	var mod :TileMapLayer = $TerrainMargin/TerrainHBox/TexturePanel/ModLayer
	var atlas1 : Vector2i = map.ground.get_cell_atlas_coords(cell)
	var atlas2 : Vector2i = map.modifier.get_cell_atlas_coords(cell)
	var source1 : int = map.ground.get_cell_source_id(cell)
	var source2 : int = map.modifier.get_cell_source_id(cell)
	base.clear()
	mod.clear()
	if atlas1 != Vector2i(-1,-1): base.set_cell(Vector2i(0,0), source1, atlas1)
	else: 
		print("TerrainPanel: _set_preview_tiles: Missing Base Tile Atlas")
		return
	if atlas2 != Vector2i(-1,-1): mod.set_cell(Vector2i(0,0), source2, atlas2)
		


#region utility
func _get_terrain_name() -> String:
	var finalString : String
	
	return finalString
