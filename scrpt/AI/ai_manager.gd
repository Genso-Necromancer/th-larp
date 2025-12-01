extends Node
class_name AiManagerNew

@export var mind : Personality
#High Nodes
var director:GameBoard
var map:GameMap

#data storage
var unit_values
var terrain_values:Dictionary

#value constraints
var terrainMax = 2.0
var terrainMin = 0.0


func init_ai(game_board:GameBoard):
	director = game_board
	map = get_parent()


#region External Callable



#endregion


#region Internal Callable

#region value functions
func _assign_terrain_value(map:GameMap) -> Dictionary:
	var oldValue: float = 0.0
	var value: float = 0.0
	var newRange = (1.0-0.0)
	var oldRange: float = (terrainMax - terrainMin)
	var valuedTiles :Dictionary= {}
	var groundTiles : Array[Vector2i] = map.ground.get_used_cells()
	var modTiles : Array[Vector2i] = map.modifier.get_used_cells()
	var walls : Dictionary = map.get_walls()
	var tData : Dictionary = PlayerData.terrainData
	for tile in groundTiles:
		if !walls.Wall.has(tile) and !walls.WallShoot.has(tile) and !walls.WallFly.has(tile):
			var bonuses : Dictionary = map.get_bonus(tile)
			oldValue = float(bonuses.GrzBonus) / 100
			oldValue += float(bonuses.DefBonus) / 10
			oldValue += float(bonuses.PwrBonus) / 10
			oldValue += float(bonuses.MagBonus) / 10
			oldValue += float(bonuses.HitBonus) / 100
			oldValue += float(bonuses.HpRegen) / 100
			oldValue += float(bonuses.CompRegen) / 10
			value = ((oldValue-(terrainMin))*newRange/oldRange) + 0
			#if heatMap.has(tile): value = value * (1-(heatMap[tile]/10))
			value = value * mind.terrain
			valuedTiles[tile] = value
	#print("Tile Values: ", valuedTiles)
	return valuedTiles
#endregion

#endregion
