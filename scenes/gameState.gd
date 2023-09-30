extends Node
class_name GameState

var terrainData: Array
var player: Array
var enemy: Array
var playerTurns: int
var enemyTurns: int
var acted: Array
var win: Array
var occupied: Dictionary


func update_map_data(mapData):
	terrainData = mapData

func update_unit_data(units):
	player.clear()
	enemy.clear()
#	var i = 0
	var solidDick = {}
	for cell in units:
		if units[cell]:
			solidDick[cell] = units[cell]
	units = solidDick
	for unit in units:
		match units[unit].is_in_group("Player"):
			true: player.append(units[unit])
			false: enemy.append(units[unit])
	occupied = units.duplicate()
#	print(player)
#	print(enemy)

func update_remaining_turns(turns):
	playerTurns = 0
	enemyTurns = 0
	for turn in turns:
		match turn[0]:
			false: playerTurns += 1
			true: enemyTurns += 1

func add_acted(unit):
	acted.append(unit)

func clear_acted():
	acted.clear()

func set_win(conditions):
	for condition in conditions:
		win.append(condition)


