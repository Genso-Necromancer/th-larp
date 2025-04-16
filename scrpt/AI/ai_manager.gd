extends Node
class_name AiManager


@export var mind : Personality ##Personality Resource: contains the weights for each aspect of decision making

##references
var gb:GameBoard
var map:GameMap
var unitData = UnitData.unitData

##Decision Variables
var player := []
var enemy := []
var terrainData

var threatArray = []
var state: BoardState
var lvCap = 20
var terrainMax = 2
var terrainMin = 0
var newRange = (1-0)

#Parameters
var unitValues :Dictionary= {}
var oppValues :Dictionary= {}
var terrainValues :Dictionary= {}
var heatMap : Dictionary[Vector2i,int]= {}

var unitContext : Dictionary
var oppContext : Dictionary
var dazedUnits : Array = []

##link up dependancies
func init_ai(game_board:GameBoard):
	gb = game_board
	map = get_parent()


func get_move(faction:Enums.FACTION_ID) ->Dictionary:
	var bestMove : Dictionary
	var possibleMoves : Array
	_set_unit_context(faction)
	_set_cell_heat()
	terrainValues = _assign_terrain_value(gb.currMap)
	possibleMoves = _evaluate_priorities()
	bestMove = _find_best_move(possibleMoves)
	return bestMove


#region Root AI Functions
func _set_unit_context(faction:Enums.FACTION_ID):
	var dazeTried := false
	unitContext.clear()
	oppContext.clear()
	_sort_units(faction)
	if unitContext.size() <= 0: 
		_sort_units(faction,true)
		dazeTried = true
	if unitContext.size() <= 0 and dazeTried: pass
	#for unit in unitContext:
		#print(unit.unitName,":", unitContext[unit].BaseValue)
	#for unit in oppContext:
		#print(unit.unitName,":", oppContext[unit].BaseValue)
	#functions for adding context should go here
	#adding them as I realize I need it


func _set_cell_heat():
	var aHex : AHexGrid2D = AHexGrid2D.new(gb.currMap)
	heatMap.clear()
	for opp in oppContext:
		var threat = aHex.find_threat(oppContext[opp].Walkable, opp.get_reach())
		for cell in threat:
			if heatMap.has(cell): heatMap[cell] += 1
			else: heatMap[cell] = 0


func _evaluate_priorities() -> Array:
	var tiers : Array[Personality.PRIORITIES] = [mind.first,mind.second,mind.third,mind.fourth,mind.fifth,mind.sixth,mind.seventh]
	var moves : Array = []
	for p in tiers:
		match p:
			Personality.PRIORITIES.OBJECTIVE: pass
			Personality.PRIORITIES.OFFENSE: 
				var off := _value_offense()
				if off.size() == 0: continue
				elif _highest_value(off) >= mind.minimumValue: 
					moves += off
					break
			Personality.PRIORITIES.PLAYS: pass
			Personality.PRIORITIES.DEFENSE: 
				var deff := _value_defense()
				if deff.size() == 0: continue
				elif _highest_value(deff) >= mind.minimumValue:
					moves += deff
					break
			Personality.PRIORITIES.SURVIVAL: pass
			Personality.PRIORITIES.RECOVERY: pass
			Personality.PRIORITIES.SPECIAL: pass
	moves.append(_find_wait_unit())
	return moves


func _find_best_move(moves:Array)->Dictionary:
	var bestValue:float = -INF
	var tiedBest: Array = []
	var bestMove : Dictionary = {}
	var testArray:= []
	for m in moves:
		if m.Value > 0.7: testArray.append(m)
		if m.Value > bestValue:
			bestValue = m.Value
			bestMove = m
			tiedBest.clear()
			tiedBest.append(m)
		elif m.Value == bestValue:
			tiedBest.append(m)
	if tiedBest.size() > 0: pass
		
	#print("Moves over 0.7: ", testArray)
	return bestMove


#region sub_functions
func _sort_units(faction:Enums.FACTION_ID, useDazed := false):
	var units : Dictionary[Vector2i, Unit] = gb.units
	var aHex : AHexGrid2D = AHexGrid2D.new(gb.currMap)
	for cell in units:
		var ally : Unit
		var opp : Unit
		match units[cell].FACTION_ID:
			faction:
				ally = units[cell]
			Enums.FACTION_ID.PLAYER when faction == Enums.FACTION_ID.NPC: ally = units[cell]
			Enums.FACTION_ID.PLAYER when faction == Enums.FACTION_ID.ENEMY: opp = units[cell]
			Enums.FACTION_ID.NPC: opp = units[cell]
		if ally and _is_dazed(ally) and !useDazed: dazedUnits.append(ally)
		elif ally:
			unitContext[ally] = {}
			unitContext[ally]["Leash"] = ally.leash
			unitContext[ally]["Walkable"] = _get_walkable(ally)
			unitContext[ally]["BaseValue"] = _value_unit(ally)
			#unitContext[ally]["Reach"] = aHex.find_all_unit_paths(ally)
		elif opp: 
			oppContext[opp] = {}
			oppContext[opp]["Leash"] = opp.leash
			oppContext[opp]["Walkable"] = _get_walkable(opp)
			oppContext[opp]["BaseValue"] = _value_unit(opp, true)

func _value_offense() -> Array:
	var moves : Array = []
	var stash : Array = []
	for unit in unitContext:
		if unit.archetype == Unit.AI_TYPE.OFFENDER:
			#moves.append(_get_pressure_moves(unit))
			moves += _get_attacks(unit, unitContext[unit])
		else: stash.append(unit)
	if !_validate_minimum(moves):
		for unit in stash:
			#moves.append(_get_pressure_moves(unit))
			moves += _get_attacks(unit, unitContext[unit])
	return moves


func _value_defense() -> Array:
	var moves:Array=[]
	var stash : Array =[]
	var lowest := -INF
	for unit in unitContext:
		if unit.archetype == Unit.AI_TYPE.DEFENDER:
			pass
			#moves.append(find_best_move(unitContext[unit].Walkable,unit))
		else: stash.append(unit)
	if !_validate_minimum(moves):
		for unit in stash:
			pass
			#moves.append(find_best_move(unitContext[unit].Walkable,unit))
	return moves


func _find_wait_unit() -> Dictionary:
	var value: float = 0
	var archetype : float = 0.0
	var lowestVal : float = INF
	var lowestUnit : Unit
	var waitAction = {"Action": "Wait", "Value": value, "Unit":null}
	for unit in unitContext:
		match unit.archetype:
			Unit.AI_TYPE.NONE: archetype = 0.1
			Unit.AI_TYPE.OFFENDER: archetype = 0.4
			Unit.AI_TYPE.DEFENDER: archetype = 0.2
			Unit.AI_TYPE.SUPPORT: archetype = 0.6
			Unit.AI_TYPE.BOSS: archetype = 1.1
		value = unitContext[unit].BaseValue * archetype
		if value < lowestVal:
			lowestVal = value
			lowestUnit = unit
		elif value == lowestVal and randi_range(0,100) <= 50.0:
			lowestVal = value
			lowestUnit = unit
	waitAction.Value = lowestVal
	waitAction.Unit = lowestUnit
	return waitAction


#region search functions
func _get_pressure_moves(unit:Unit) -> Dictionary:
	var moves : Array[Dictionary] = []
	var aHex : AHexGrid2D = AHexGrid2D.new(gb.currMap)
	var archetype : float = 1.0
	var bestMove : Dictionary = {}
	match unit.archetype:
		Unit.AI_TYPE.NONE: return bestMove
		Unit.AI_TYPE.OFFENDER: archetype = 1.1
		Unit.AI_TYPE.DEFENDER: archetype = 0.9
		Unit.AI_TYPE.SUPPORT: archetype = 0.4
		Unit.AI_TYPE.BOSS: archetype = 0.5
	
	for cell in unitContext[unit].Walkable:
		var walkable := aHex.find_all_unit_paths(unit,cell)
		var futureAttacks := _find_valid_attacks(unit,walkable)
		for attack in futureAttacks:
			var value: float = (attack.Value * archetype * 0.5)
			var tile: Vector2i = attack.Launch
			moves.append({"Unit": unit, "Action":"Move","Tile":cell,"Value":value})
	bestMove = _find_best_move(moves)
	return bestMove


func _get_attacks(unit:Unit, context_entry:Dictionary) -> Array:
	var moves : Array = []
	var aHex : AHexGrid2D = AHexGrid2D.new(gb.currMap)
	moves = _find_valid_attacks(unit,context_entry.Walkable)
	return moves


func _find_threaten(unit:Unit):
	var aHex : AHexGrid2D = AHexGrid2D.new(gb.currMap)
	aHex.find_threat(unitContext[unit].Walkable,unit.get_reach())


func _get_walkable(unit:Unit) -> Array:
	var walkable : Array
	var aHex : AHexGrid2D = AHexGrid2D.new(gb.currMap)
	if unit.leash > -1: walkable = aHex.find_all_unit_paths(unit, unit.cell, unit.leash)
	else: walkable = aHex.find_all_unit_paths(unit)
	return walkable


func find_best_move(validMoves:Array, unit:Unit) -> Dictionary:
	var movePairs = []
	var curLife = unit.activeStats.CurLife
	var maxLife = unit.unitData.Stats.Life
	var lifePrc:float = (maxLife - ((maxLife-curLife) / maxLife)) / 10
#	var value:float = 0
	for cell in validMoves:
		if !gb.units.has(cell):
			movePairs.append({"Action": "Move","tile":Vector2i(cell), "Value": terrainValues[Vector2i(cell)]})
	var bestValue:float = terrainValues[unit.cell]
	var bestMove : Dictionary
#	var dmgTaken = 0
#	var dmgDealt = 0
#	var survRatio = 0
	for pair in movePairs:
#		print(pair)
		if pair["Value"] > terrainValues[Vector2i(unit.cell)]:
			if lifePrc < mind.survThresh:
				pair["Value"] = pair["Value"] * ((((maxLife-curLife) / maxLife) + 1) * mind.survival)
		if pair["Value"] > bestValue:
			bestValue = pair["Value"]
			bestMove = pair.duplicate()
#	print("best: ", bestMove)
	return bestMove


func _check_regions():
	pass

#endregion

#region utility functions
func _is_dazed(unit:Unit) -> bool:
	if unit.status.get("Daze", false):
		return true
	return false


func _validate_minimum(moves:Array):
	var minimum : float = 0.65
	if moves.size() <= 0: return false
	for m in moves:
		if m.Value > minimum:
			return true
	return false


func _highest_value(moves:Array) -> float:
	var highest : float = -INF
	for move in moves:
		highest = maxf(highest, move.Value)
	return highest
#endregion

#region micro valueing
func _value_threat(unit:Unit, opp:Unit, cell:Vector2i) -> float:
	var value : float = 0.0
	var combatValue : float
	
	value = (unitContext[unit].value + (oppContext[opp] + _get_dying_value(opp))) * (1-(heatMap[cell]/10))
	return value

func _value_unit(unit:Unit, isOpp := false) -> float:
	var value: float = 0
	var avgLv := 0
	var lvVariable : String
	var teamVariable : String
	match unit.FACTION_ID:
		Enums.FACTION_ID.PLAYER: 
			lvVariable = "pLvl"
			teamVariable = "player"
		Enums.FACTION_ID.ENEMY: 
			lvVariable = "eLvl"
			teamVariable = "enemy"
		Enums.FACTION_ID.NPC: 
			lvVariable = "nLvl"
			teamVariable = "npc"
	var total :int= gb.boardState[lvVariable]
	var team : Array[Unit] = gb.boardState[teamVariable]
	if team.size() != 0:
		avgLv = total / team.size()
	var lvRange: float = ((avgLv - 1) - (avgLv - 20))
	var oldValue: float = 0
	oldValue += floorf(avgLv - unit.unitData.Profile.Level)
	match unit.unitData.Profile.Role:
		"Lady": oldValue += 1
	value = ((oldValue-(avgLv - 20))*newRange/lvRange) + 0
	value = value * mind.units
	if !isOpp: 
		value = 1 - value
	#else:
		#var lifeValue: float = ((unit.activeStats.Life - unit.activeStats.CurLife) / unit.unitData.Stats.Life)
		#value += lifeValue * mind.finishOffUnits
	return value
	
	#if isTargets:
		#
	#else:
		#value -= value / mind.survival
	#teamValues[unit] = value
func _get_dying_value(unit:Unit) -> float:
	var value : float = 0.0
	var lifeValue: float = ((unit.activeStats.Life - unit.activeStats.CurLife) / unit.unitData.Stats.Life)
	value += lifeValue * mind.finishOffUnits
	return value

func _get_combat_value(unit:Unit, target:Unit, targetDef):
	var aiInv = unit.unitData.Inv
	var value: float
	var dmgDealt = unit.combatData.Dmg - target.unitData.Stats[targetDef]
	var remHP = target.activeStats.CurLife - dmgDealt
	remHP = clampf(remHP, 0, 1000)
	var dmgTaken = 0
	if remHP == 0:
		value += 1
	else:
#		print(value)
		value += ((target.unitData.Stats.Life - remHP) / target.unitData.Stats.Life)
#		print(target.unitData.Stats.Life)
#		print(value)
		value = value * mind.dmgWeight
	var accScore = unit.combatData.Hit - target.combatData.Graze
	accScore = clampf(accScore, 0, 1000)
	if accScore != 0:
		var accValue = accScore/100
		accValue = accValue - 0.5
		accValue = accValue * mind.accScale
		var grazeProc:float  = target.combatData.BarPrc
		var grazeScore: float = (grazeProc / 100)
		if grazeScore < 1:
#			print("grz: ", grazeScore)
#			print("b4: ",accValue)
			accValue -= grazeScore * mind.grWeight
#			print("aft: ",accValue)
		else:
			accValue = -10
		value += accValue * mind.accWeight
	else:
		value -= 10
	
			
	match target.combatData.Type:
		Enums.DAMAGE_TYPE.PHYS:
			dmgTaken = target.combatData.Dmg - unit.unitData.Stats.Def
		Enums.DAMAGE_TYPE.MAG:
			dmgTaken = target.combatData.Dmg - unit.unitData.Stats.Mag
		Enums.DAMAGE_TYPE.TRUE:
			dmgTaken = target.combatData.Dmg
			
	if unit.activeStats.CurLife - dmgTaken <= 0 and target.activeStats.CurLife - dmgDealt > 0:
		value = value * mind.survival
	return value
#endregion

func find_moves(state: BoardState, units:Array[Unit]) -> Dictionary:
	var validMoves :Array[Dictionary]= []
	for unit in units:
		if unit.status.Acted:
			continue
		var unitCell :Vector2i= unit.cell
		var moves :Dictionary= get_valid_moves(unit, unit.cell, unit.unitData.Stats.Move, state)
		if moves == null or moves.size() == 0: continue
		else: validMoves.append({"Unit": unit, "BestMove": moves})
	var bestAction = find_best_action(validMoves)
#	print(validMoves)
#	print("Best?? ", validMoves)
#	print("We made it: ", bestAction)
	return bestAction
	
func find_best_action(moves):
	var bestValue: float = -INF
	var bestMove = null
	for move in moves:
#		print(move)
		if move["BestMove"]["Value"] > bestValue:
			bestValue = move["BestMove"]["Value"]
			bestMove = move
	return bestMove
	
func get_valid_moves(unit, cell, move, state): #Doesn't realize when a move is technically out of reach HERE
	#This just runs the functions which actually compares all the possible moves before sending it up the pipeline
	var aHex:AHexGrid2D= AHexGrid2D.new(gb.currMap)
	var path:Array= aHex.find_all_unit_paths(unit)
	var threat
	var bestAttack = null
	var bestMove = null
	var bestSkill = null
	var waitValue = null
	var validMoves = path.duplicate()
	var validAttacks = _find_valid_attacks(unit, path)
	
	if unit.unitData.Skills: pass #Skill processing here
#	print(validAttacks)
	if validAttacks != null: bestAttack = find_best_attack(validAttacks)
	if validMoves != null: bestMove = find_best_move(validMoves, unit)
	waitValue = find_wait_value(unit, bestAttack, bestMove)
#	print(unit, "'s ","Best Attack: ", bestAttack)
#	print(unit, "'s ","BestMove: ", bestMove)
#	print(unit, "'s ","Wait Value: ", waitValue)
	var bestAction = find_best_of_set(bestAttack, bestMove, waitValue)
#	print(unit, "'s ","Best Action: ", bestAction)
	return bestAction
	#HERE You gathered each attackable unit and the spaces you can attack them from.
	#Each target and it's spaces need VALUES to be processed


func find_best_of_set(attack, move, wait):
	var bestMove = null
	if attack != null and attack["Value"] >= move["Value"] and attack["Value"] >= wait["Value"]:
		bestMove = attack
	elif move!= null and move["Value"] > wait["Value"]:
		bestMove = move
	else:
		bestMove = wait
	return bestMove
			
func find_wait_value(unit, bestAttack, bestMove):
	var value: float = 0
	var dmgTaken = 0
	var dmgDealt = 0
	var bestTerrain = terrainValues[Vector2i(unit.cell)]
	var tradeUp = false
	if bestAttack == null and bestMove == null:
		value = 1
	for terrain in terrainValues:
		if terrainValues[terrain] > terrainValues[Vector2i(unit.cell)]:
			tradeUp = true
	if !tradeUp:
		value += mind.waitWeight
	var waitAction = {"Action": "Wait", "Value": value}
	return waitAction



func find_best_attack(attacks):
	var bestValue:float = -INF
	var bestAttack = null
	for attack in attacks:
		if attack["Value"] > bestValue:
			bestValue = attack["Value"]
			bestAttack = attack.duplicate()
	return bestAttack
	
func _find_valid_attacks(aiUnit:Unit, path) -> Array:
	#Needs updating for unique weapon ID
	var validAttacks :Array= []
#	threat = aHex.find_threat(path, ranges)
	var aiInv :Array= aiUnit.unitData.Inv
	var wepData :Dictionary= UnitData.itemData
	var targetDef
	var aHex :AHexGrid2D= AHexGrid2D.new(gb.currMap)
	#var archetype : float = unit.get_archetype("Offense")
	var archetype : float = 1.0
	for wep in aiInv:
		var wepID = wep["ID"]
		aiUnit.set_temp_equip(wep)
		var ranges = aiUnit.get_weapon_reach()
		var threat = aHex.find_threat(path, ranges)
		for unit in oppContext:
			match wepData[wepID].Type:
				Enums.DAMAGE_TYPE.PHYS:
					targetDef = "Def"
					if (aiUnit.combatData.Dmg - unit.activeStats.Def <= 0):
						continue
				Enums.DAMAGE_TYPE.MAG:
					targetDef = "Mag"
					if (aiUnit.combatData.Dmg - unit.activeStats.Mag <= 0):
						continue
			
			if threat.has(unit.cell):
	#			var radius = aHex.find_all_paths(unit.cell, ranges[1], true)
				var reach = aHex.find_threat([unit.cell], ranges)
	#			print(reach)
				
				for cell in reach:
					var attack = {}
					if path.has(cell) and cell != unit.cell and !gb.units.has(cell):
						var safe = _check_safe(aiUnit, unit, cell)
						attack = {"Unit": aiUnit, "Action": "Attack", "Target" : unit, "Launch" : Vector2i(cell), "Safe": safe, "Weapon": wep, "Skill": false}
						var value = _get_attack_value(aiUnit, attack, targetDef)
						attack["Value"] = value * archetype
						validAttacks.append(attack)
		aiUnit.restore_equip()
	return validAttacks
	
func _get_attack_value(aiUnit, attack, targetDef):
	var value: float = 0.0
	var aHex = AHexGrid2D.new(gb.currMap)
	var archetype:float = 1.0
	match aiUnit.archetype:
		Unit.AI_TYPE.NONE: return value
		Unit.AI_TYPE.OFFENDER: archetype = 1.1
		Unit.AI_TYPE.DEFENDER: archetype = 0.8
		Unit.AI_TYPE.SUPPORT: archetype = 0.4
		Unit.AI_TYPE.BOSS: archetype = 0.6
#	print("StarT: ", value, " + ", unitValues[attack.Target])
	value += oppContext[attack.Target].BaseValue + _get_dying_value(attack.Target)
	value += unitContext[aiUnit].BaseValue * archetype
#	print(value)
#	print(" + ", terrainValues[attack.Launch])
	value += (terrainValues[attack.Launch])
	#value -= (aHex.compute_cost(aiUnit.cell, attack.Launch, aiUnit) / 100) 
#	print(value)
#	print(" + ", oppValues[aiUnit])
#	value += oppValues[aiUnit]
#	print(value)
#	print(" + ", combat_values(aiUnit, attack, targetDef))
	value += combat_values(aiUnit, attack, targetDef)
#	print(value)
	if attack.Safe:
		value *= mind.safeBonus
	return value
	
func combat_values(aiUnit, attack, targetDef):
	var aiInv = aiUnit.unitData.Inv
	var value: float
	var target = attack.Target
	var dmgDealt = aiUnit.combatData.Dmg - target.activeStats[targetDef]
	var remHP = attack.Target.activeStats.CurLife - dmgDealt
	remHP = clampf(remHP, 0, 1000)
	var dmgTaken = 0
	if remHP == 0:
		value += 1 * mind.dmgWeight
	else:
#		print(value)
		value += ((target.activeStats.Life - remHP) / target.activeStats.Life)
#		print(target.unitData.Stats.Life)
#		print(value)
		value = value * mind.dmgWeight
	var accScore = aiUnit.combatData.Hit - target.combatData.Graze
	accScore = clampf(accScore, 0, 1000)
	if accScore != 0:
		var accValue = accScore/100
		accValue = accValue - 0.5
		accValue = accValue * mind.accScale
		var barProc:float  = target.combatData.BarPrc
		var barScore: float = (barProc / 100)
		if barScore < 1:
#			print("grz: ", grazeScore)
#			print("b4: ",accValue)
			accValue -= barScore * mind.barrierChance
#			print("aft: ",accValue)
		else:
			accValue = -10
		value += accValue * mind.accWeight
	else:
		value -= 10
	
			
	match target.combatData.Type:
		Enums.DAMAGE_TYPE.PHYS: dmgTaken = target.combatData.Dmg - aiUnit.activeStats.Def
		Enums.DAMAGE_TYPE.MAG: dmgTaken = target.combatData.Dmg - aiUnit.activeStats.Mag
		Enums.DAMAGE_TYPE.TRUE: dmgTaken = target.combatData.Dmg
			
	if aiUnit.activeStats.CurLife - dmgTaken >= 0 and target.activeStats.CurLife - dmgDealt > 0:
		value -= (aiUnit.activeStats.CurLife - dmgTaken / aiUnit.activeStats.Life) * mind.survival
	return value
	
func _check_safe(aiUnit, target, launch):
	var wepData = UnitData.itemData
	var aHex = AHexGrid2D.new(gb.currMap)
	var distance = aHex.find_distance(launch, target.cell,)
	var equip = target.get_equipped_weapon()
	var wepID = equip["ID"]
	var targetReach
	var safe = false
	var wep = wepData[wepID]
	if target.is_in_group("Player"):
		targetReach = wep.MaxRange
	elif target.is_in_group("Enemy"):
		targetReach = wep.MaxRange
#	if distance == 3:
#		print(launch, target.cell)
	if distance > targetReach:
		safe = true
		return safe
	else:
		return safe
	
func _assign_terrain_value(map:GameMap) -> Dictionary:
	var oldValue: float = 0.0
	var value: float = 0.0
	var oldRange: float = (terrainMax - terrainMin)
	var valuedTiles :Dictionary= {}
	var groundTiles : Array[Vector2i] = map.ground.get_used_cells()
	var modTiles : Array[Vector2i] = map.modifier.get_used_cells()
	var walls : Dictionary = map.get_walls()
	var tData : Dictionary = UnitData.terrainData
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
			if heatMap.has(tile): value = value * (1-(heatMap[tile]/10))
			value = value * mind.terrain
			valuedTiles[tile] = value
	#print("Tile Values: ", valuedTiles)
	return valuedTiles


func assign_unit_value(team:Array[Unit], isTargets:bool = false):
	var teamValues = {}
	var i = 0
	var avgLv = 0
	var total = 0
	
	for unit in team:
		total += unit.unitData.Profile.Level
		
	if team.size() != 0:
		avgLv = total / team.size()
		
	var oldRange: float = ((avgLv - 1) - (avgLv - 20))
	for unit in team:
		var oldValue: float = 0
		var value: float = 0
		oldValue += floorf(avgLv - unit.unitData.Profile.Level)
		match unit.unitData.Profile.Role:
			"Lady": oldValue += 1
		value = ((oldValue-(avgLv - 20))*newRange/oldRange) + 0
		value = value * mind.units
		var lifeValue: float = ((unit.activeStats.Life - unit.activeStats.CurLife) / unit.unitData.Stats.Life)
		if isTargets:
			value += lifeValue * mind.ulWeight
		else:
			value -= value / mind.survival
		teamValues[unit] = value
	return teamValues
	
func compile_action(bestAction):
	
	var actor
	for key in bestAction:
		actor = key
	var action = bestAction[actor][0][0]
	var target = bestAction[actor][0][1]
#	var actorPath = threatArray[0][2]
	var compiledAction = [action, actor, target]
#	print(compiledAction)
	return compiledAction
	
