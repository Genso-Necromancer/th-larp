extends Node
class_name MapLoader

signal map_loaded


func load_map(map:String, save_data:Dictionary={})->GameMap:
	if !map: print("[GameBoard]load_map: empty map string")
	var newMap:GameMap = load(map).instantiate()
	newMap.map_ready.connect(self._on_map_ready)
	if save_data: _with_data(newMap,save_data)
	else: _without_data(newMap)
	return newMap


func _with_data(map:GameMap, save_data:Dictionary):
	map.load_data(save_data.GameMap)


func _without_data(map:GameMap):
	_set_game_time(map)


func _set_game_time(map:GameMap):
	Global.time_passed = 0
	Global.set_time(map.hours,map.minutes)


func _on_map_ready(map:GameMap):
	map_loaded.emit()


#func _initialize_new_map(map:GameMap):
	#var units:Dictionary[Vector2i,Unit] = {}
	#units.clear()
	#_store_enemy_units(units, map)
	#await _initialize_units() 
	##_init_gamestate() used in the old state scripts. Could be deleted later.
	#
	#units_loaded.emit(units)
#
#
#func _store_enemy_units(units:Dictionary[Vector2i,Unit], map:GameMap):
	#for child in map.get_children():
		#var unit := child as Unit
		#if not unit or unit.FACTION_ID == Enums.FACTION_ID.PLAYER or unit.is_queued_for_deletion(): continue
		#units[unit.cell] = unit
		#_connect_unit_signals(unit)
