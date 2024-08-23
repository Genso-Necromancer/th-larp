extends TileMap
class_name BaseGameMap
signal map_ready

enum TERRAIN {
	Flat = 1,
	Fort = 2,
	Hill = 3
}
var tileSet = tile_set
var tileSize : Vector2i = tileSet.get_tile_size()
var tileShape = tileSet.get_tile_shape()

@export_category("Map Values")
@export var forcedUnits = ["Remilia"] ##Units required to participate in this chapter [Do not use units which can die and arrive prior to this map]
@export var gameTime = 12 ##Time of day at the start of chapter
@export var next_map : Resource
@export_category("Conditions")
@export_group("Win Conditions")
@export var winEvents : Dictionary = {"Seize" : 0} ## 0 = false, input number of event occurences required for win
@export var winKill : Array[Unit] = [] ##Use Add Element to select map units which trigger a win condition
@export_group("Loss Conditions")
@export var playerDeath : Dictionary = {"Remilia" : true, "Sakuya" : true, "Patchouli" : false, "Meiling" : false} ##Tick Player units whose death triggers a loss condition
@export var lossKill : Array[Unit] = [] ##Use Add Element to select map units which trigger a loss condition
@export var hoursPassed : int = 0 ##0 = false, set hour limit before loss



#event trackers
var victoryKills : Array = []
	

func _ready():
	#self.call_deferred("_connect_units")
	var p = get_parent()
	self.map_ready.connect(p.on_map_ready)
	#self.tree_exited.connect(p.on_map_gone)
	emit_signal("map_ready")
	#_init_conditions()
#	print(tileSize)


func cell_clamp(grid_position: Vector2i) -> Vector2i:
	var out := grid_position
	out.x = clamp(out.x, 0, get_used_rect().size.x - 1.0)
	out.y = clamp(out.y, 0, get_used_rect().size.y - 1.0)
	return grid_position
	
func hex_centered(grid_position: Vector2i) -> Vector2i:
	var tileCenter = grid_position * tileSize + tileSize / 2
	return tileCenter

func get_movement_cost(cell):
	
	var tileData = get_cell_tile_data(1, cell)
	var type
	if !tileData == null: 
		
		type = tileData.get_custom_data("terrainType")
		
	else: type = "Flat"
	return type
	
func get_bonus(cell):
	var bonus = 0
	var tileData = get_cell_tile_data(1, cell)
	if !tileData == null: 
			bonus = tileData.get_custom_data("terrainBonus")
	return bonus

func get_deployment_cells():
	var triggerCells = get_used_cells(2)
	var deploymentCells = []
	for cell in triggerCells:
		var tileData = get_cell_tile_data(2, cell)
		if tileData.get_custom_data("trigger") == "deployCell":
			deploymentCells.append(cell)
	return deploymentCells

func get_forced_deploy(): #make sure there is equal units assigned as forced as there are forced cells!
	var i = 0
	var triggerCells = get_used_cells(2)
	var forcedCells = []
	var forcedDeploy = {}
	for cell in triggerCells:
		var tileData = get_cell_tile_data(2, cell)
		if tileData.get_custom_data("trigger") == "forcedCell":
			forcedCells.append(cell)
	for unit in forcedUnits:
		forcedDeploy[unit] = forcedCells[i]
		i += 1
	return forcedDeploy

func hide_deployment():
	set_layer_enabled(2, false)
	
	
#Event Functions

func _on_unit_death(unit):
	check_event("death", unit)
	
func check_event(trigger, parameter): ##Triggers: death, time, seize
	
	match trigger:
		"death": _check_death_conditionals(parameter)
		"time": _check_time_conditional(parameter)
			
func _check_death_conditionals(parameter):
	var unitId
	var condition
	if parameter.faction == "Player":
		unitId = parameter.unitId
		condition = "Player Death"
	else:
		condition = "NPC Death"
		
	match condition:
		"Player Death":
			if playerDeath[unitId]:
				Global.flags.gameOver = true
		"NPC Death":
			if lossKill.has(parameter):
				Global.flags.gameOver = true
			if winKill.has(parameter):
				_add_kill(parameter, true)
	
func _add_kill(unit, victory):
	if victory:
		victoryKills.append(unit)
		
	for kill in winKill:
		if !victoryKills.has(kill):
			return
			
	Global.flags.victory = true
		
func _check_time_conditional(time):
	if gameTime - time >= hoursPassed:
		Global.flags.gameOver = true
