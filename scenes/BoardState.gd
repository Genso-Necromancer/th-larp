extends Resource
class_name BoardState

var terrainData: Array
var player: Array[Unit]
var enemy: Array[Unit]
var npc: Array[Unit]
var playerTurns: int
var enemyTurns: int
var npcTurns: int
var turnOrder: Array[String]
var acted: Array
var win: Array
var occupied: Dictionary
var pLvl := 0
var eLvl := 0
var nLvl := 0

func update_map_data(mapData):
	terrainData = mapData

func update_unit_data(units):
	player.clear()
	enemy.clear()
	npc.clear()
	pLvl = 0
	eLvl = 0
	nLvl = 0
#	var i = 0
	var solidDick = {}
	
	for cell in units:
		if units[cell]:
			solidDick[cell] = units[cell]
	units = solidDick
	for unit in units:
		match units[unit].FACTION_ID:
			Enums.FACTION_ID.PLAYER: 
				player.append(units[unit])
				pLvl += units[unit].unit_level
			Enums.FACTION_ID.ENEMY: 
				enemy.append(units[unit])
				eLvl += units[unit].unit_level
			Enums.FACTION_ID.NPC: 
				npc.append(units[unit])
				nLvl += units[unit].unit_level
	occupied = units.duplicate()
#	print(player)
#	print(enemy)

func update_remaining_turns(turns)->void:
	playerTurns = 0
	enemyTurns = 0
	npcTurns = 0
	for turn in turns:
		match turn:
			"Player": playerTurns += 1
			"Enemy": enemyTurns += 1
			"NPC":npcTurns += 1

func add_acted(unit):
	acted.append(unit)

func clear_acted():
	acted.clear()

func set_win(conditions):
	for condition in conditions:
		win.append(condition)
