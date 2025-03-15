@tool
extends Node2D
class_name GameMap
signal map_ready
signal events_checked
signal danmaku_progressed


@export_category("Map Values")
@export var forcedUnits = ["Remilia"] ##Units required to participate in this chapter [Do not use units which can die and arrive prior to this map]
@export var gameTime = 12 ##Time of day at the start of chapter
@export var next_map : PackedScene
@export var chapterNumber: int = 0
@export var title: String = ""
@export_category("Conditions")
@export_group("Win Conditions")
@export var winEvents : Dictionary = {"Seize" : 0} ## 0 = false, input number of event occurences required for win
@export var winKill : Array[Unit] = [] ##Use Add Element to select map units which trigger a win condition
@export_group("Loss Conditions")
@export var playerDeath : Dictionary = {"Remilia" : true, "Sakuya" : true, "Patchouli" : false, "Meiling" : false} ##Tick Player units whose death triggers a loss condition
@export var lossKill : Array[Unit] = [] ##Use Add Element to select map units which trigger a loss condition
@export var hoursPassed : int = 0 ##0 = false, set hour limit before loss
@export_category("Danmaku")
@export var dmkScript : DanmakuScript
@export var dmkMaster : Unit

##ALL THE FUCKING LAYERS
@onready var ground := $Ground
@onready var modifier := $Modifier
@onready var object := $Object
@onready var deploy := $Deployments
@onready var pathAttack := $PathAttack
@onready var narrative := $Narrative
@onready var dev := $Dev

@onready var tileSet :TileSet = ground.tile_set
@onready var tileSize : Vector2i = tileSet.get_tile_size()
@onready var tileShape = tileSet.get_tile_shape()
var mapSize
var eventQue := []
var dmkScene = preload("res://scenes/danmaku.tscn")
var actingDanmaku := {"Spawning":[], "Collision":[]}



#event trackers
var victoryKills : Array = []


func _ready():
	if not Engine.is_editor_hint():
		var p = get_parent()
		self.map_ready.connect(p.on_map_ready)
		_load_danmaku_scripts()
		dev.visible = false
		narrative.visible = false
	mapSize = ground.get_used_rect().size
	print(mapSize)
	emit_signal("map_ready")
	_initialize_unit_cells()
	


func get_active_units() -> Dictionary:
	var unitList := {}
	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		elif unit.isActive:
			unitList[unit.cell] = unit
	return unitList

func _initialize_unit_cells():
	var units : Dictionary = get_active_units()
	for unit in units:
		units[unit].initialize_cell()

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
	
func get_bonus(cell): # WHOOPS BROKEN
	var bonus = 0
	var tileData = modifier.get_cell_tile_data(cell)
	#if !tileData == null: 
			#bonus = tileData.get_custom_data("terrainBonus")
	return bonus


func get_terrain_tags(cell:Vector2i) -> Dictionary:
	var terrainTags: Dictionary = {"TerrainType1": "", "TerrainType2": "", "TerrainId1": "", "TerrainId2": ""}
	var type1 = ground.get_cell_tile_data(cell)
	var type2 = modifier.get_cell_tile_data(cell)
	var id1 = ground.get_cell_tile_data(cell)
	var id2 = modifier.get_cell_tile_data(cell)
	
	if type1: 
		terrainTags.TerrainType1 = type1.get_meta("TerrainType", "")
	if type2:
		terrainTags.TerrainType2 = type2.get_meta("TerrainType", "")
	if id1:
		terrainTags.TerrainId1 = id1.get_meta("TerrainId", "")
	if id2:
		terrainTags.TerrainId2 = id2.get_meta("TerrainId", "")
		
	return terrainTags

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



func hide_deployment():
	deploy.set_enabled(false)
	

#region Thanks Wokedot
func map_to_local(mapPosition: Vector2i) -> Vector2:
	return ground.map_to_local(mapPosition)
	

func local_to_map(localPosition: Vector2) -> Vector2i:
	return ground.local_to_map(localPosition)


func get_used_rect() -> Rect2i:
	return ground.get_used_rect()
	
	
#region Event Functions

func _on_unit_death(unit):
	check_event("Death", unit)
	
func check_event(trigger, parameter): ##Triggers: death, time, seize
	var triggered := false
	match trigger:
		"Death": triggered = _check_death_conditionals(parameter)
		"Time": triggered = _check_time_conditional(parameter)
	return triggered
	
			
func _check_death_conditionals(parameter):
	var unitId
	var condition
	var triggered := false
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
			if winKill.has(parameter):
				_add_kill(parameter, true)
	if triggered:
		_check_off_event.call_deferred()
	return triggered
	
func _add_kill(unit, victory):
	if victory:
		victoryKills.append(unit)
		
	for kill in winKill:
		if !victoryKills.has(kill):
			return
			
	Global.flags.victory = true
		
func _check_time_conditional(_time):
	var triggered := false
	if Global.timePassed == hoursPassed:
		Global.flags.gameOver = true
		triggered = true
		return
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
	
	triggered = check_event("Time", Global.gameTime)
	if triggered:
		eventQue.append(triggered)
	if eventQue.size() == 0:
		emit_signal("events_checked")
	#put other event triggers here, too

func _check_off_event():
	eventQue.pop_back()
	if eventQue.size() == 0:
		emit_signal("events_checked")

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
	
	
func progress_danmaku_script():
	var step = dmkScript.get_pattern_step()
	#var action = step.keys()[0]
	match step.Action:
		"Spawn": _process_bullets(step.Bullets)
		_: emit_signal("danmaku_progressed")

func _process_bullets(bullets):
	#"Type": "DmkuKunai",
	#"SpawnStyle": "Left",
	#"Amount": 2,
	#"Offset": 1,
	var dmkData = dmkScript.danmakuData
	for bullet in bullets:
		var a : int = bullet.Amount
		var dmk : Dictionary = dmkData[bullet.Type]
		var grouping := []
		
		for i in a:
			var b = dmkScene.instantiate()
			b.init_bullet(dmk, bullet.Type, dmkMaster)
			grouping.append(b)
			
		var results : Array = get_parent().spawn_danmaku(grouping, bullet.Offset, dmkMaster.cell, bullet.AnchorType)
		
		for b in results:
			if b.SpawnPoint:
				add_child(b.Bullet)
				b.Bullet.relocate(b.SpawnPoint)
				b.Bullet.animation_completed.connect(self._on_danmaku_animation_completed)
				actingDanmaku.Spawning.append(b.Bullet)
			else: b.Bullet.queue_free()
	if actingDanmaku.Spawning.size() > 0:
		_call_danmaku_entrance()
		
		

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
