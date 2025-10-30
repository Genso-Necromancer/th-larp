extends Node
class_name UnitLoader

signal deploy_count_changed(slots:int)
signal unit_removed(unit:Unit)
signal units_loaded()
var master:GameBoard
var map:GameMap
var save_enum:Enums.SAVE_TYPE = Enums.SAVE_TYPE.NONE
#deployment
var filled_slots:int = 0
var forced_deploy:Dictionary
var deployment_cells:Array
var dep_cap:int = 0


func _init(new_master:GameBoard, new_save_enum:Enums.SAVE_TYPE, new_map:GameMap):
	master = new_master
	save_enum = new_save_enum
	map = new_map


func load_map_units(map:GameMap,units:Dictionary[Vector2i,Unit],refs: Dictionary[String, Unit]):
	_initialize_units(units,map,refs)


func load_units_from_file(map:GameMap,units:Dictionary[Vector2i,Unit],refs: Dictionary[String, Unit]):
	await map.load_map_units()
	_initialize_units(units,map,refs)


func _initialize_units(units:Dictionary[Vector2i,Unit],map:GameMap,refs: Dictionary[String, Unit]):
	_store_enemy_units(units, map, refs)
	await _process_player_units(units, map, refs)
	units_loaded.emit()


func _store_enemy_units(units:Dictionary[Vector2i,Unit], map:GameMap, refs: Dictionary[String, Unit]):
	for child in map.get_children():
		var unit := child as Unit
		if not unit or unit.FACTION_ID == Enums.FACTION_ID.PLAYER or unit.is_queued_for_deletion(): continue
		units[unit.cell] = unit
		_connect_unit_signals(unit)


func _process_player_units(units:Dictionary[Vector2i,Unit], map:GameMap, refs: Dictionary[String, Unit]):
	var roster := PlayerData.rosterData
	var order := PlayerData.roster_order
	var unitData:Dictionary = PlayerData.unitData
	var deploymentHistory := {"Deployed":[],"Undeployed":[]}
	#var spawnLoc
	filled_slots = 0
	deployment_cells = map.get_deployment_cells()
	forced_deploy = map.get_forced_deploy()
	dep_cap = deployment_cells.size() + forced_deploy.size()
	_deploy_forced(forced_deploy, units,refs)
	_deploy_group(order[Enums.DEPLOYMENT.DEPLOYED], units,refs)
	_deploy_group(order[Enums.DEPLOYMENT.UNDEPLOYED], units,refs)
	_update_roster_label()


func _deploy_forced(forced_dictionary:Dictionary, units:Dictionary[Vector2i,Unit],refs: Dictionary[String, Unit]):
	var roster := PlayerData.rosterData
	var unitData:Dictionary = PlayerData.unitData
	var group:Array = forced_dictionary.keys()
	for id in group:
		if roster[id].deployment == Enums.DEPLOYMENT.GRAVEYARD: continue
		var playerUnit:Unit = _load_player_unit(roster[id].Path)
		deploy_unit(playerUnit, true, forced_dictionary[id])
		units[playerUnit.cell] = playerUnit
		refs[playerUnit.unit_id] = playerUnit


func _deploy_group(group:Array, units:Dictionary[Vector2i,Unit],refs: Dictionary[String, Unit]):
	var roster := PlayerData.rosterData
	var unitData:Dictionary = PlayerData.unitData
	var groupCopy:= group.duplicate()
	for id in groupCopy:
		if roster[id].deployment == Enums.DEPLOYMENT.GRAVEYARD: continue
		var playerUnit:Unit = _load_player_unit(roster[id].Path)
		if filled_slots < dep_cap:
			deploy_unit(playerUnit)
			units[playerUnit.cell] = playerUnit
		elif filled_slots >= dep_cap:
			undeploy_unit(playerUnit, true)
		refs[playerUnit.unit_id] = playerUnit


func _update_roster_label():
	#print(filled_slots)
	deploy_count_changed.emit(filled_slots)


func _load_player_unit(path:String) -> Unit:
	var playerUnit :Unit= load(path).instantiate()
	var unitData:Dictionary = PlayerData.unitData
	playerUnit.map = map
	if unitData and unitData.PLAYER.get(playerUnit.unit_id,false): 
		playerUnit.pre_load(unitData.PLAYER[playerUnit.unit_id])
	#unitObjs[playerUnit.unit_id] = playerUnit
	_connect_unit_signals(playerUnit)
	map.add_child(playerUnit)
	return playerUnit


##Intended for player units, maps will handle Enemy and NPC units
func post_load_unit(unit:Unit)->void:
	var faction:String = Enums.FACTION_ID.keys()[unit.FACTION_ID]
	var ID: String = unit.unit_id
	var unitData:Dictionary = PlayerData.unitData[faction]
	var setCell:bool = false
	if save_enum == Enums.SAVE_TYPE.SUSPENDED: setCell = true
	if unitData and unitData.get(ID,false): unit.post_load(unitData[ID],setCell)


func deploy_unit(unit:Unit, forced = false, spawnLoc = Vector2i(0,0)):
	if filled_slots >= dep_cap: 
		print("Roster Full")
		return
	if forced:
		unit.deployment = Enums.DEPLOYMENT.FORCED
	else:
		spawnLoc = _first_available_dep_cell()
		unit.deployment = Enums.DEPLOYMENT.DEPLOYED
	
	unit.visible = true
	unit.is_active = true
	if save_enum != Enums.SAVE_TYPE.SUSPENDED: unit.relocate_unit(spawnLoc)
	filled_slots += 1
	_update_roster_label()
	
		


func undeploy_unit(unit:Unit, ini = false):
	var spawnLoc = Vector2i(0,0)
	if unit.deployment != Enums.DEPLOYMENT.FORCED:
		unit.visible = false
		unit.is_active = false
		unit.deployment = Enums.DEPLOYMENT.UNDEPLOYED
		unit_removed.emit(unit)
		unit.relocate_unit(spawnLoc, false)
	else:
		print("Must deploy: " + unit.unit_id)
	if unit.deployment != Enums.DEPLOYMENT.FORCED and !ini:
		filled_slots -= 1
		_update_roster_label()


func _first_available_dep_cell():
	var firstCell = null
	var filled :Array= master.units.keys()
	for cell in deployment_cells:
		if !filled.has(cell):
			firstCell = cell
			break
	return firstCell


func _connect_unit_signals(unit:Unit):
#	if !combatManager.combat_resolved.is_connected(unit.on_combat_resolved):
#		combatManager.combat_resolved.connect(unit.on_combat_resolved)
	if !unit.death_done.is_connected(master.on_death_done):
		unit.death_done.connect(master.on_death_done)
	#if !master.turn_changed.is_connected(unit.on_turn_changed): 
		#master.turn_changed.connect(unit.on_turn_changed)
	if !unit.unit_relocated.is_connected(master.on_unit_relocated): 
		unit.unit_relocated.connect(master.on_unit_relocated)
	if !unit.exp_gained.is_connected(master.on_exp_gained) and unit.FACTION_ID == Enums.FACTION_ID.PLAYER:
		unit.exp_gained.connect(master.on_exp_gained)
	if !master.new_round.is_connected(unit._on_new_round):
		master.new_round.connect(unit._on_new_round)
	if !master.turn_changed.is_connected(unit._on_turn_changed):
		master.turn_changed.connect(unit._on_turn_changed)
	#if !master.sequence_concluded.is_connected(unit.on_sequence_concluded):
		#master.sequence_concluded.connect(unit.on_sequence_concluded)
	if !unit.turn_complete.is_connected(master.on_turn_complete):
			unit.turn_complete.connect(master.on_turn_complete)
	if !unit.effect_complete.is_connected(master.on_effect_complete):
		unit.effect_complete.connect(master.on_effect_complete)
	if !unit.item_targeting.is_connected(master._on_unit_item_targeting):
		unit.item_targeting.connect(master._on_unit_item_targeting)
	if !unit.item_activated.is_connected(master._on_unit_item_activated):
		unit.item_activated.connect(master._on_unit_item_activated)
	if !unit.unit_ready.is_connected(master._on_unit_ready):
		unit.unit_ready.connect(master._on_unit_ready)
	if !unit.walk_finished.is_connected(master._on_unit_walk_finished):
		unit.walk_finished.connect(master._on_unit_walk_finished)
	if !unit.animation_complete.is_connected(master._on_unit_animation_complete):
		unit.animation_complete.connect(master._on_unit_animation_complete)
	if !unit.bars_updated.is_connected(master._on_bars_updated):
		unit.bars_updated.connect(master._on_bars_updated)
