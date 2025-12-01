extends Node
##Representation of the board's current state for AI evaluation
class_name BoardState

var map:GameMap
var units:Dictionary[Vector2i,UnitSim]
var turn:Enums.FACTION_ID
var turn_order:Array[StringName]
var terminal_conditions:Array[Objective]


func _init(source_units:Dictionary[Vector2i,Unit], source_turn:Enums.FACTION_ID, source_turn_order:Array[StringName], source_map:GameMap):
	units = {}
	turn = source_turn
	turn_order = source_turn_order
	map = source_map
	terminal_conditions = map.objectives
	for cell in source_units.keys():
		_add_unit(source_units[cell].to_sim())


##Copies the current state of the board
func clone() -> BoardState:
	var newState = BoardState.new({},turn,turn_order,map)
	newState.units = units.duplicate(true)
	return newState
	#var clone:Dictionary={}
	#clone["map"]=map
	#clone["units"]=units.duplicate()
	#clone["turn"]=turn


##restore boardstate
#func restore(state:BoardState):
	#units = state.units.duplicate(true)
	#turn = state.turn
	#map = state.map


##Applies an action to the BoardState
func apply(turn:Turn)->BoardState:
	var sim:BoardState = clone()
	var type:=Action.ACTION_TYPE
	for action:Action in turn:
		match action.type:
			type.MOVE: sim._apply_move(action)
			type.ATTACK: sim._apply_attack(action)
			type.SKILL_HOSTILE: sim._apply_skill_hostile(action)
			type.SKILL_FRIENDLY: sim._apply_skill_friendly(action)
			type.WAIT: sim._apply_wait(action)
			type.TRADE: sim._apply_trade(action)
			type.USE_ITEM: sim._apply_use_item(action)
			type.CANTO: sim._apply_canto(action)
			type.TIME_WARP: sim._apply_time_warp(action)
	sim.turn = sim.turn_order.pop_front()
	return sim


##Returns if BoardState is terminal
func is_terminal()->bool:
	return false

##Retrieves unit at given cell
func get_unit_at(cell: Vector2i)->Unit:
	return units.get(cell, null)

func get_terrain_data(cell: Vector2i)->Dictionary:
	return map.get_terrain_data(cell)

## Adds unit to state
func _add_unit(sim: UnitSim):
	units[sim.cell] = sim

##Simulates relocation
#WARNING does not account for entering or exiting auras due to them being hit-box dependant!
func _apply_move(action:Action):
	var unit:=units[action.from_cell]
	units.erase(action.from_pos)
	unit.cell=action.target_cell
	
	units[action.target_cell] = unit


func _apply_attack(action:Action):
	var attacker:=units[action.from_cell]
	var defender:=units[action.target_cell]
	#Need to simulate dmg/acc formulas
	var dmg:int
	var acc:int
	defender.current_life -= dmg
	if defender.current_life <= 0: units.erase(action.target_pos)



func _apply_skill_hostile(action:Action): pass
func _apply_skill_friendly(action:Action): pass
func _apply_wait(action:Action):
	var unit:= units[action.from_cell]
	unit.status.Acted = true
func _apply_trade(action:Action): pass
func _apply_use_item(action:Action): pass
func _apply_canto(action:Action): pass
func _apply_time_warp(action:Action): pass
