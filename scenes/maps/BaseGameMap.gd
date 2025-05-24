@tool
extends Node2D
class_name GameMap
signal map_ready
signal events_checked
signal danmaku_progressed

enum MAP_EVENT{NONE, TIME, DEATH, SEIZE}
enum OBJECTIVE_STYLE{SEQUENTIAL, SIMULTANEOUS}
@export_category("Map Values")
##Units required to participate in this chapter.[br]
##WARNING: Do not use units which can die and arrive prior to this map]
@export var forcedUnits = ["Remilia"]
@export_file("*.tscn") var next_map : String
@export var chapterNumber: int = 0
@export var title: String = ""
@export_group("Conditions")
@export_subgroup("Win Conditions")
##Sequential: each objective in win_conidtions occurs one after the other. [br]
##Simultaneous: Every objective in win_conditions is active at the same time.
@export var win_style : OBJECTIVE_STYLE = OBJECTIVE_STYLE.SEQUENTIAL
##Objective of the map.[br]
##Make new of any desired style of objective, then input the desired requirements
@export var win_conditions : Array[Objective] = []:
	set(value):
		win_conditions = value
		update_configuration_warnings()
@export var winEvents : Dictionary = {"Seize" : 0} ## 0 = false, input number of event occurences required for win
@export var winKill : Array[Unit] = [] ##Use Add Element to select map units which trigger a win condition
@export_subgroup("Loss Conditions")
@export var playerDeath : Dictionary = {"Remilia" : true, "Sakuya" : true, "Patchouli" : false, "Meiling" : false} ##Tick Player units whose death triggers a loss condition
@export var lossKill : Array[Unit] = [] ##Use Add Element to select map units which trigger a loss condition
@export var hoursPassed : int = 0 ##0 = false, set hour limit before loss
@export_category("Danmaku")
@export var dmkScript : DanmakuScript
@export var dmkMaster : Unit
@export_category("Cute Scene Scripts")
@export_file("res://scenes/cutscenes/scene_events/*_event.json") var start_script = ""
@export_file("res://scenes/cutscenes/scene_events/*_event.json") var end_script = ""
@export_file("res://scenes/cutscenes/scene_events/*_event.json") var event_scripts : Array[String]
##ALL THE FUCKING LAYERS
@onready var ground :TileMapLayer= $Ground
@onready var modifier :TileMapLayer= $Modifier
@onready var object :TileMapLayer= $Object
@onready var deploy :TileMapLayer= $Deployments
##tiles with Even region numbers are treated as "Enemy Team" regions, while odd are considered "player" regions.
@onready var regions :TileMapLayer= $Regions
@onready var pathAttack :TileMapLayer= $PathAttack
@onready var narrative :TileMapLayer= $Narrative
@onready var dev :TileMapLayer= $Dev

@onready var tileSet :TileSet = ground.tile_set
@onready var tileSize : Vector2i = tileSet.get_tile_size()
@onready var tileShape = tileSet.get_tile_shape()
##Ai Manager
@onready var ai : AiManager = $AiManager



var hours : int = 0
var minutes : int = 0
var mapSize
var eventQue := []
#var dmkScene = preload("res://scenes/danmaku.tscn")
var actingDanmaku := {"Spawning":[], "Collision":[]}
#event trackers
var victoryKills : Array = []
var wasSeized : Array[Vector2i] = []
var sequenceStep := 0:
	set(value):
		sequenceStep = clampi(value,0,win_conditions.size()-1)
		Global.flags.ObjectiveComplete = true

func _ready():
	if not Engine.is_editor_hint():
		var p = get_parent()
		self.map_ready.connect(p._on_map_ready)
		_load_danmaku_scripts()
		dev.visible = false
		narrative.visible = false
		regions.visible = false
		for obj in win_conditions:
			if obj is KillUnit:
				for path in obj.hit_list_paths:
					obj.hit_list.append(get_node(path).unitId)

	mapSize = ground.get_used_rect().size
	SignalTower.action_seize.connect(self._on_seize)
	#print(mapSize)
	emit_signal("map_ready")
	_initialize_unit_cells()

#region warnings
func _get_configuration_warnings():
	if win_conditions.is_empty(): return ["Objective missing in win_condition, map is unbeatable."]
	else: return []


#region property list functions
func _get_property_list():
	var properties = []
	properties.append({
		"name":"Start_Time",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		"name" : "hours",
		"type" : TYPE_INT,
		"hint" : PROPERTY_HINT_RANGE,
		"hint_string" : "0,23,1"
	})
	properties.append({
		"name" : "minutes",
		"type" : TYPE_INT,
		"hint" : PROPERTY_HINT_RANGE,
		"hint_string" : "0,60,1"
	})
	
	return properties


func _array_to_string(arr: Array, seperator = ",") -> String:
	var string = ""
	for i in arr:
		string += str(i)+seperator
	return string
#endregion


func get_active_units() -> Dictionary:
	var unitList := {}
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		elif unit.isActive:
			unitList[unit.cell] = unit
	return unitList


func get_active_danmaku() -> Dictionary:
	var bulletList := {}
	for child in get_children():
		var bullet := child as Danmaku
		if not bullet:
			continue
		elif bullet.isActive:
			bulletList[bullet.cell] = bullet
	return bulletList


func _initialize_unit_cells():
	var units : Dictionary = get_active_units()
	for unit in units:
		units[unit].initialize_cell()


func _initialize_danmaku_cells():
	var danmaku : Dictionary = get_active_danmaku()
	for bullet in danmaku:
		danmaku[bullet].initialize_cell()

func get_objectives() -> Array:
	var objectives: Array = ["This is a Test", "Of The Emergency Broadcast", "System."]
	return objectives
	
	
func get_loss_conditions() -> Array:
	var loss: Array = ["Do NOT Be Alarmed."]
	return loss

func cell_clamp(grid_position: Vector2i) -> Vector2i:
	var out := grid_position
	out.x = clamp(out.x, 0, ground.get_used_rect().size.x - 1.0)
	out.y = clamp(out.y, 0, ground.get_used_rect().size.y - 1.0)
	return grid_position
	
func hex_centered(grid_position: Vector2i) -> Vector2i:
	var tileCenter = grid_position * tileSize + tileSize / 2
	return tileCenter

func get_movement_cost(cell, moveType):
	var base :TileData = ground.get_cell_tile_data(cell)
	var mod :TileData = modifier.get_cell_tile_data(cell)
	var baseTile : StringName
	var modTile : StringName
	var costData :Dictionary = UnitData.terrainData
	var cost := 0.0
	
	if base: baseTile = base.get_custom_data("TerrainType")
	if mod: modTile = mod.get_custom_data("TerrainType")
	cost += costData[baseTile][moveType]
	if modTile == "Bridge": cost = 0
	elif modTile: cost += costData[modTile][moveType]
	
	return cost


func get_terrain_tags(cell:Vector2i) -> Dictionary:
	var terrainTags: Dictionary = {"BaseType": "", "ModType": "", "BaseId": "", "ModId": "", "Locked": false}
	var base = ground.get_cell_tile_data(cell)
	var mod = modifier.get_cell_tile_data(cell)
	
	if base: 
		terrainTags.BaseType = base.get_custom_data("TerrainType")
		terrainTags.BaseId = base.get_custom_data("TerrainId")
	if mod:
		terrainTags.ModType = mod.get_custom_data("TerrainType")
		terrainTags.ModId = mod.get_custom_data("TerrainId")
		terrainTags.Locked = mod.get_custom_data("Locked")
	return terrainTags


func get_bonus(cell:Vector2i) -> Dictionary:
	var tags : Dictionary =  get_terrain_tags(cell)
	var cellParams : Dictionary
	var tData : Dictionary = UnitData.terrainData
	cellParams = tData[tags.BaseType].duplicate()
	if tags.ModType == "Bridge": cellParams = tData[tags.ModType]
	elif tags.ModType:
		for param in cellParams:
			cellParams[param] += tData[tags.ModType][param]
	return cellParams



func get_deployment_cells():
	var triggerCells :Array[Vector2i] = deploy.get_used_cells()
	var deploymentCells = []
	for cell in triggerCells:
		var tileData :TileData = deploy.get_cell_tile_data(cell)
		if tileData.get_custom_data("Trigger") == "deployCell":
			deploymentCells.append(cell)
	return deploymentCells


func get_walls() -> Dictionary:
	var walls := {}
	var noGo := []
	var shootOver := []
	var flyOver := []
	var modCells :Array[Vector2i] = modifier.get_used_cells()
	for cell in modCells:
		var tileData :TileData = modifier.get_cell_tile_data(cell)
		var type : StringName = tileData.get_custom_data("TerrainType")
		match type:
			"Wall": noGo.append(cell)
			"WallShoot": shootOver.append(cell)
			"WallFly": flyOver.append(cell)
		
	walls["Wall"] = noGo
	walls["WallShoot"] = shootOver
	walls["WallFly"] = flyOver
	return walls


func get_forced_deploy(): #make sure there is equal units assigned as forced as there are forced cells!
	var i = 0
	var triggerCells :Array[Vector2i] = deploy.get_used_cells()
	var forcedCells = []
	var forcedDeploy = {}
	for cell in triggerCells:
		var tileData :TileData = deploy.get_cell_tile_data(cell)
		if tileData.get_custom_data("Trigger") == "forcedCell":
			forcedCells.append(cell)
	for unit in forcedUnits:
		if i > forcedCells.size()+1:
			print("Not enough forced deploy Cells!")
			break
		forcedDeploy[unit] = forcedCells[i]
		i += 1
	return forcedDeploy


func get_narrative_tile(id:int) -> Vector2i:
	return narrative.get_narrative_tile(id)


func is_seize(cell:Vector2i) -> bool:
	if dev.get_used_cells_by_id(1,Vector2i(0,0),0).has(cell) and !wasSeized.has(cell):
		return true
	return false


func hide_deployment():
	deploy.set_enabled(false)
#endregion

#region Thanks Wokedot
func map_to_local(mapPosition: Vector2i) -> Vector2:
	return ground.map_to_local(mapPosition)
	

func local_to_map(localPosition: Vector2) -> Vector2i:
	return ground.local_to_map(localPosition)


func get_used_rect() -> Rect2i:
	return ground.get_used_rect()
#endregion

#region Event Functions
func _on_unit_death(unit):
	check_event(MAP_EVENT.DEATH, unit)


func _on_seize(cell:Vector2i):
	check_event(MAP_EVENT.SEIZE,cell)


func check_event(trigger:MAP_EVENT, parameter): ##Triggers: death, time, seize
	var triggered := false
	match trigger:
		MAP_EVENT.SEIZE: triggered = _check_seize_conditionals(parameter)
		MAP_EVENT.DEATH: triggered = _check_death_conditionals(parameter)
		MAP_EVENT.TIME: triggered = _check_time_conditional(parameter)
	return triggered


func _get_win_objective(event:MAP_EVENT) -> Objective:
	var toCheck : Array[Objective] = []
	var obj : Objective
	match win_style:
		OBJECTIVE_STYLE.SEQUENTIAL: return win_conditions[sequenceStep]
		OBJECTIVE_STYLE.SIMULTANEOUS: toCheck = win_conditions
	
	for con in toCheck:
		match event:
			MAP_EVENT.TIME: pass
			MAP_EVENT.SEIZE: if con is Seize: return con
			MAP_EVENT.DEATH:  if con is KillUnit: return con
	return obj


func _check_seize_conditionals(cell) -> bool:
	var c := 0
	var obj : Seize = _get_win_objective(MAP_EVENT.SEIZE)
	if !obj: return false
	elif is_seize(cell): wasSeized.append(cell)
	
	for event in dev.get_used_cells_by_id(1,Vector2i(0,0),0):
		if wasSeized.has(event): c += 1
	
	if c >= obj.seize_count:
		obj.complete = true
		sequenceStep += 1
		_check_victory()
		return true
	return false


func _check_death_conditionals(parameter) -> bool:
	var unitId
	var condition
	var triggered := false
	var winObj :KillUnit= _get_win_objective(MAP_EVENT.DEATH)
	if parameter.FACTION_ID == Enums.FACTION_ID.PLAYER:
		unitId = parameter.unitId
		condition = "Player Death"
	else:
		condition = "NPC Death"
		
	match condition:
		"Player Death":
			if playerDeath[unitId]:
				Global.flags.gameOver = true
				triggered = true
		"NPC Death":
			if lossKill.has(parameter):
				Global.flags.gameOver = true
				triggered = true
			if winObj.hit_list.has(parameter.unitId):
				_add_kill(parameter, true)
	if triggered:
		_check_off_event.call_deferred()
	return triggered


func _add_kill(unit, victory):
	var winObj :KillUnit = _get_win_objective(MAP_EVENT.DEATH)
	if victory:
		victoryKills.append(unit.unitId)
	if !winObj: return
	for kill in winObj.hit_list:
		if !victoryKills.has(kill):
			return
	winObj.complete = true
	sequenceStep += 1
	_check_victory()


func _check_time_conditional(_time) -> bool:
	var triggered := false
	if hoursPassed == 0: triggered = false
	elif Global.timePassed == hoursPassed:
		Global.flags.gameOver = true
		return true
	var childs = get_children()
	for child in childs:
		var spawner = child as UnitSpawner
		if spawner and spawner.timeMethod == "Time Passed" and spawner.timeHours <= Global.timePassed:
			_spawn_premade_units(spawner)
			triggered = true
		elif spawner and spawner.timeMethod == "Time of Day" and spawner.timeHours == Global.gameTime:
			_spawn_premade_units(spawner)
			triggered = true
	return triggered


func check_events():
	var triggered : bool
	triggered = check_event(MAP_EVENT.TIME, Global.gameTime)
	if triggered:
		eventQue.append(triggered)
	if eventQue.size() == 0:
		emit_signal("events_checked")
	#put other event triggers here, too


func _check_off_event():
	eventQue.pop_back()
	if eventQue.size() == 0:
		emit_signal("events_checked")


func _check_victory() -> void:
	var flag : bool
	for obj in win_conditions:
		if !obj.complete: return
	Global.flags.victory = true
#endregion

#region entity spawning
func _spawn_premade_units(spawner : UnitSpawner):
	# DIAGNOSIS: SIGNAL NEVER EMITS, BECAUSE ITS PROBABLY NOT SPAWNING THE UNIT. SOMETHING MIGHT NEED TO BE DEFERRED???
	var units = []
	var spawnPoints = spawner.get_spawn_points()
	var spawnGroup = spawner.get_group()
	var childs = spawnGroup.get_children()
	var tween = get_tree().create_tween()
	var delay := 0.5
	var timer := 1
	for child in childs:
		var unit := child as Unit
		if not unit: continue
		units.append(unit)
	
	for spawn in spawnPoints:
		var unit = units.pop_front()
		if !unit: break
		tween.tween_callback(_spawn_from_spawner.bind(unit, spawn)).set_delay(delay)
		await tween.finished #might not need this with how tweens work, will check later HERE
		
	await get_tree().create_timer(timer).timeout
	
	tween.kill()
	spawnGroup.queue_free()
	_check_off_event.call_deferred()

func _spawn_from_spawner(unit, spawn):
	unit.disabled = false
	var spawned = get_parent().spawn_unit(unit, spawn)
	if spawned: unit.reparent(self)
	else: unit.queue_free()

	
func _spawn_new_units():
	var unitPackage := {"Faction" : Enums.FACTION_ID.ENEMY, "Id" : "none", "GenLv" : 1, "Species" : Enums.SPEC_ID.FAIRY, "Job" : Enums.JOB_ID.TRBLR, "Cell" : Vector2i(1,1), "IsForced":false, "IsElite" : false}
	get_parent().spawn_raw_unit(unitPackage)


#region danmaku functions
func _load_danmaku_scripts():
	if dmkScript != null:
		var p = get_parent()
		if !self.danmaku_progressed.is_connected(p._on_danmaku_progressed):
			self.danmaku_progressed.connect(p._on_danmaku_progressed)
		dmkScript.master = dmkMaster
		dmkScript.map = self
	
	
func progress_danmaku_script() -> void:
	if !dmkScript: 
		emit_signal("danmaku_progressed")
		return
	var step = dmkScript.get_step()
	#var action = step.keys()[0]
	_process_bullets(step)
	#match step.Action:
		#"Spawn": _process_bullets(step.Bullets)
		#_: emit_signal("danmaku_progressed")

func _process_bullets(spawn_scene:PackedScene):
	var spawner :DanmakuPattern= spawn_scene.instantiate()
	var danmaku :Array[Danmaku]= spawner.get_danmaku()
	var anchor : Unit
	match spawner.anchorTarget:
		spawner.AnchorTarget.SELF: anchor = dmkMaster
		spawner.AnchorTarget.TARGET: anchor = get_danmaku_target() ##Not functioning yet
	anchor.add_child(spawner)
	if danmaku.size() == 0:
		emit_signal("danmaku_progressed")
		spawner.queue_free()
		return
	
	for bullet:Danmaku in danmaku:
		bullet.reparent(self, true)
		bullet.init_bullet(dmkMaster)
		actingDanmaku.Spawning.append(bullet)
		bullet.animation_completed.connect(self._on_danmaku_animation_completed)
	call_deferred("assign_danmaku", danmaku)
	spawner.queue_free()
	get_parent().camera_to_anchor(anchor.cell)
	await get_parent().camera_on_anchor
	_call_danmaku_entrance()
	
	#"Type": "DmkuKunai",
	#"SpawnStyle": "Left",
	#"Amount": 2,
	#"Offset": 1,
	#var dmkData = dmkScript.danmakuData
	#for bullet in bullets:
		#var a : int = bullet.Amount
		#var dmk : Dictionary = dmkData[bullet.Type]
		#var grouping := []
		#
		#for i in a:
			#var b = dmkScene.instantiate()
			#b.init_bullet(dmk, bullet.Type, dmkMaster)
			#grouping.append(b)
			#
		#var results : Array = get_parent().spawn_danmaku(grouping, bullet.Offset, dmkMaster.cell, bullet.AnchorType)
		#
		#for b in results:
			#if b.SpawnPoint:
				#add_child(b.Bullet)
				#b.Bullet.relocate(b.SpawnPoint)
				#b.Bullet.animation_completed.connect(self._on_danmaku_animation_completed)
				#actingDanmaku.Spawning.append(b.Bullet)
			#else: b.Bullet.queue_free()
	#if actingDanmaku.Spawning.size() > 0:
		#_call_danmaku_entrance()
##Not functioning yet
func get_danmaku_target() -> Unit:
	var target : Unit
	return target


func assign_danmaku(unassigned_danmaku:Array[Danmaku]):
	var danmaku : Dictionary[Vector2i,Danmaku]
	for b in unassigned_danmaku:
		b.initialize_cell()
		danmaku[b.cell] = b
	get_parent().append_danmaku(danmaku)


func _call_danmaku_entrance():
	for b in actingDanmaku.Spawning:
		b.call_deferred("play_animation", "Spawning")


func _on_danmaku_animation_completed(anim, bullet):
	if !actingDanmaku[anim] or actingDanmaku[anim].size() == 0:
		return
	actingDanmaku[anim].erase(bullet)
	if actingDanmaku[anim].size() == 0:
		match anim:
			"Spawning": emit_signal("danmaku_progressed")
	


#region Targeting and Pathing Functions
## Fills the tilemap with the cells, giving a visual representation of the cells a unit can walk.
func draw(cells: Array) -> void:
	pathAttack.clear()
	for cell in cells:
#		print("draw2:", cell)
		pathAttack.set_cell(cell, 10, Vector2i(0,0))
		
func draw_attack(cells: Array) -> void:
	pathAttack.clear()
	for cell in cells:
#		print("draw2:", cell)
		pathAttack.set_cell(cell, 9, Vector2i(0,0))
		
func draw_threat(walk: Array, threat: Array) -> void:
	pathAttack.clear()
	for cell in threat:
#		print("draw2:", cell)
		pathAttack.set_cell(cell, 9, Vector2i(0,0))
	for cell in walk:
#		print("draw2:", cell)
		pathAttack.set_cell(cell, 10, Vector2i(0,0))
