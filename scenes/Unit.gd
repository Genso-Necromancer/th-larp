@tool
class_name Unit
extends Path2D
signal walk_finished
signal exp_handled
signal death_done
signal unit_relocated
signal exp_gained
signal leveled_up


#Unit Parameters
@export var generate : bool = true ##Toggle on for randomly leveled stats based on growths, Toggle Off to use predefined stats
#Profile
								# Consider getting rid of one of these, or both. 
@export var unitId := "unitID" #Should be automated in the system
@export var unitName := "" #Presented strings will eventually be taken from a seperate file

@export var FACTION_ID := Enums.FACTION_ID.ENEMY

@export var SPEC_ID := Enums.SPEC_ID.FAIRY 

@export var JOB_ID := Enums.JOB_ID.TRBLR
@export var genLevel : int = 1
@export var inventory: Array[String] = [] #revisit this for ease of selection
@export_category("Animation Values")
@export var move_speed := 150.0


var deployed : bool = false
var forced : bool = false

var itemData = UnitData.itemData



var needDeath := false
var terrainData : Array
var statsLoaded := false

#equip variables
const unarmed : Dictionary = UnitData.unarmed
var tempSet : bool = false
#status effects
@export var status : Dictionary = {"ACTED":false, "SLEEP":false}
var sParam : Dictionary = {}

var unitData : Dictionary
#Call for pre-formualted combat stats
var combatData := {"Dmg": 0, "HIT": 0, "AVOID": 0, "GRAZE": 0, "GRZPRC": 0, "Crit": 0, "CRTAVD": 0, "RESIST": 0, "EFFACC":0, "Type":"Physical"}
#base stats of the unit
var baseStats := {}
#combination of base stats and buffs
var activeStats := {}
#de/buffs applied to unit
var activeBuffs := {}
var activeEffects := []
#var skin = UnitData.playerUnits[unitName]["Sprite"]:
#	set(value):
#		skin = value
#		if not _sprite:
#			await ready
#		_sprite.texture = value

#@export var skin_offset := Vector2i.ZERO:
#	set(value):
#
#		skin_offset = value
#		if not _sprite:
#			await ready
#		_sprite.position = value
## Coordinates of the current cell the cursor moved to.
var cell := Vector2i.ZERO:
	set(value):
		cell = map.cell_clamp(value)
		
# Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_animPlayer.play("selected")
		elif status.ACTED == false:
			_animPlayer.play("idle")
		elif status.ACTED == true:
			_animPlayer.play("disabled")

var _is_walking := false:
	set(value):
		_is_walking = value
#		set_process(_is_walking)
#var position := Vector2.ZERO:
#	set(value):
#		position = map.hex_centered(value)

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _animPlayer: AnimationPlayer = $PathFollow2D/Sprite/AnimationPlayer
@onready var _pathFollow: PathFollow2D = $PathFollow2D
@onready var map = get_parent()
@onready var lifeBar = $PathFollow2D/HPbar


var last_glb_position := Vector2.ZERO
var originCell

var walk_directions := [
	"walk_left",
	"walk_up",
	"walk_right",
	"walk_down",
]
var walk_directions_size := float(walk_directions.size())

#test
var spawnLoc
var originLocation

func _ready() -> void:
#	print(statVars)
#	#print("unit.gd:", unitId)
	set_process(false)
	_animPlayer.play("idle")
	_generate_id()
	_load_stats()
	_load_sprites()
	if map.get_class() != "TileMap": #may not need in future, too specific to "test map"
		pass
	elif !map.map_ready.is_connected(self._on_test_map_map_ready):
		map.map_ready.connect(self._on_test_map_map_ready)
	
	#Create the curve resource here because creating it in the editor prevents moving the unit
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
		
	#move type debugging
	#var testKey = UnitData.MOVE_TYPE.keys()[unitData.MoveType]
	#print(str(unitName) + " Move Type: " + str(testKey))
	
	
func init_unit(unique:bool = !generate, newFaction := FACTION_ID, iD : String = "none"):
	FACTION_ID = newFaction
	if iD != "none":
		unitId = iD
	if unique:
		generate = false
	return self
	#_load_stats()
	#_load_sprites()
	
func _generate_id():
	var u := false
	var c := 0
	if unitId != "unitID":
		u = true
	while !u:
		unitId = "yk" + str(c)
		if UnitData.unitData.has(unitId):
			c += 1
		elif !UnitData.unitData.has(unitId):
			UnitData.unitData[unitId] = {}
			u = true

func _process(delta: float) -> void:
	if needDeath:
		return
	if _is_walking == true:
		_pathFollow.progress += move_speed * delta
		var current_move_vec = _sprite.global_position - last_glb_position
		last_glb_position = _sprite.global_position
	#	#print(last_glb_position)
		var norm_move_vec = current_move_vec.normalized()
		var direction_id = int(walk_directions_size * (norm_move_vec.rotated(PI / walk_directions_size).angle() + PI) / TAU)
		_animPlayer.play(str(walk_directions[direction_id]))
	if _pathFollow != null && _pathFollow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_pathFollow.progress = 0.00001
		position = map.map_to_local(cell)
		curve.clear_points()
		_animPlayer.play("idle")
		emit_signal("walk_finished")
	if statsLoaded:
		update_stats()

## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
#	#print("walk along")
	if path.is_empty():
		#print("empty")
		return
#	#print(cell)
	originCell = map.local_to_map(position)
#	print(originCell)
#	#print(originCell, cell)
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(map.map_to_local(point) - position)
		
	cell = path[-1]
	
#	print(path[-1])
	_is_walking = true
#	print("unit cell: ", cell)
#	print("unit position: ", position)

func return_original():
	position = map.map_to_local(originCell)
	cell = originCell
#	#print(originCell, cell)
	return cell
	
func _load_stats():
	if generate:
		UnitData.stat_gen(JOB_ID, unitId, SPEC_ID)
	unitData = UnitData.unitData[unitId]
	match FACTION_ID:
		Enums.FACTION_ID.PLAYER: 
			add_to_group("Player") #maybe redundant? can think of situations it isn't.
		Enums.FACTION_ID.ENEMY: 
			add_to_group("Enemy")
		Enums.FACTION_ID.NPC:
			add_to_group("NPC")
	if unitName == "":
		unitName = unitData["Profile"]["UnitName"]
		
	if generate and genLevel > 1:
		UnitData.level_up(unitData, genLevel-1)
	
	baseStats = unitData.Stats.duplicate(true)
	activeStats["CLIFE"] = baseStats.LIFE
	activeStats["CCOMP"] = baseStats.COMP
	update_stats()
	_init_inv()
	check_passives()
	statsLoaded = true
	
	
#	var groups = get_groups()
#	print(unitName, " ", groups)


		
#keep track of active de/buffs during gameplay, seperate from actual stats
#re-evaluate the variable names, and if so many are necessary. VOODOO WARNING HERE
func set_buff(effId, effect):
	var statKeys : Array = Enums.CORE_STAT.keys()
	if effId == null:
		print("No effId found")
		return
	if effect.Stack:
		var i = 0
		var newId = effId + str(i)
		while activeBuffs.has(newId):
			i += 1
			newId = effId + str(i)
		effId = newId
	if effect.duration == -1:
		var stat : String = statKeys[effect.BuffStat]
		unitData.Stats[stat] += effect.BuffValue
	else:
		activeBuffs[effId] = effect.duplicate(true)
	update_stats()
	
func remove_buff(effId):
	activeBuffs.erase(effId)
	update_stats()
	
#tracks duration of effects, then removes them when reaching 0
func status_duration_tick():
	var idKeys = activeBuffs.keys()
	
	for effId in idKeys:
#		var statKeys = activeBuffs[effId].keys()
#		for stat in statKeys:
		if activeBuffs[effId].Duration > 0:
			activeBuffs[effId].Duration -= 1
		if activeBuffs[effId].Duration == 0:
			remove_buff(effId)
			
	#for key in statusKeys:
		#if status[key] and sParam[key].Duration > 0:
			#status[key].Duration -= 1
		#if status[key] and sParam[key].Duration == 0:
			#status[key] = {"Active": false}
			
	for key in status:
			if status[key] and sParam.has(key) and sParam[key].Duration > 0:
				sParam[key].Duration -= 1
			elif status[key] and sParam.has(key) and sParam[key].Duration <= 0:
				status[key] = false
				sParam.erase(key)
			
	$PathFollow2D/Cell2.set_text(str(status.SLEEP))
#	print(activeBuffs)
	update_stats()
	
func _load_sprites():
	if !generate: 
		_sprite.texture = unitData["Profile"]["Sprite"]
		_sprite.self_modulate = Color(1,1,1)
	else: 
		_sprite.texture = UnitData.get_generated_sprite(SPEC_ID, JOB_ID)
		_sprite.self_modulate = Color(1,0,0)
	_pathFollow.rotates = false
	_animPlayer.play("idle")
	
func _init_inv():
	var limit = unitData.MaxInv
	if inventory.size() < 1:
		return
	for thing in inventory:
		if unitData.Inv.size() >= limit:
			break
		var dur = itemData[thing].MAXDUR
		var newItem : Dictionary = {"ID": thing, "EQUIP": false, "DUR": dur}
		unitData.Inv.append(newItem)
	set_equipped()

func check_passives():
	#ATTENTION
	#Terrible, garbage, what the fuck. Cheap imitation of how it should be.
	#will remake this
	var _passives = unitData["Passive"]
#	if passives.has("Fly"):
#		moveType = "Fly"
#		unitData.Stats.MOVE = baseMove+1
#	if passives.has("SunWeak") and Global.day == true:
#		moveType = "Foot"
#		unitData.Stats.Move = baseMove
		
			
		
	
func restore_equip():
	var i = 0
	for item in unitData.Inv:
		if tempSet and get_icat(item) != "ACC" and item.EQUIP:
			unitData.Inv[i].EQUIP = false
			unitData.Inv[0].EQUIP = true
		i += 1
	tempSet = false
	
func set_temp_equip(i):
	var tempWep = unitData.Inv[i]
	if check_valid_equip(tempWep) and get_icat(tempWep) != "ACC":
		unitData.Inv[0].EQUIP = false
		tempWep.EQUIP = true
	tempSet = true
	update_combatdata()
	
func set_equipped(iInv = false): #searches for first valid if false or out of bounds, otherwise pass inv index and will equip if valid
	var valid = false
	var invItem
		
	if iInv and iInv < unitData.Inv.size() and iInv > -1:
		invItem = unitData.Inv[iInv]
		valid = check_valid_equip(invItem)
	else: 
		var i = 0
		for thing in unitData.Inv:
			if check_valid_equip(thing) and get_icat(thing) != "ACC":
				valid = true
				iInv = i
				break
			i += 1
	if valid and invItem and get_icat(invItem) == "ACC":
		_equip_acc(iInv)
	elif valid:
		_equip_weapon(iInv)
	tempSet = false
	update_combatdata()
	
func get_equipped_weapon(): #returns the currently equipped weapon within inventory. use .ID to find global statistics. Return generic "unarmed" if there is none.
	var found
	var wep
	for item in unitData.Inv:
		if item.EQUIP and check_valid_equip(item, 1):
			wep = item
			found = true
			break
	if !found:
		wep = unarmed
	return wep
	
func get_equipped_acc(): #returns the currently equipped accessories within inventory. use .ID to find global statistics. Return false if none.
	
	var acc : Array = []
	for item in unitData.Inv:
		if item.EQUIP and check_valid_equip(item, 2):
			acc.append(item)
	if acc.size() == 0:
		return false
	return acc
	
func unequip(slot = 0):
	var item = unitData.Inv[slot]
	while !item.EQUIP:
		slot += 1
		if slot >= unitData.Inv.size():
			return
		item = unitData.Inv[slot]
		
	_remove_equip_effects(item)
	item.EQUIP = false
	

func _equip_acc(i : int):
	var acc = unitData.Inv[i]
	var limit : int = 2
	var c : int = 0
	var first : int
	for item in unitData.Inv:
		var type : String = get_icat(acc)
		if type == "ACC" and acc.EQUIP and !first:
			c += 1
			first = unitData.Inv.find(item)
		elif type == "ACC" and acc.EQUIP:
			c += 1
	if c >= limit:
		unequip(first)
	acc.EQUIP = true
	
	_add_equip_effects(acc)

func _equip_weapon(index):
	var wep = unitData.Inv.pop_at(index)
	
	for item in unitData.Inv:
		var type : String = get_icat(wep)
		if type != "ACC" and wep.EQUIP:
			var i = unitData.Inv.find(wep)
			unequip(i)
		
	_add_equip_effects(wep)
	unitData.Inv.push_front(wep)
	unitData.Inv[0].EQUIP = true
	
func _add_equip_effects(item):
	var iData = UnitData.itemData[item.ID]
	
	if iData.Effect and iData.Effect.size() > 0:
		for effId in iData.Effect:
			_add_effect(effId)
	#print(activeEffects)
		
func _remove_equip_effects(item):
	var iData = UnitData.itemData[item.ID]
	if iData.has("Effect"):
		for effect in iData.Effect:
			var i = activeEffects.find(effect)
			activeEffects.remove_at(i)
	#print(activeEffects)
	
func _add_effect(effId):
	activeEffects.append(effId)
		
func _remove_effect(effId):
	var i = activeEffects.find(effId)
	activeEffects.remove_at(i)
	
func get_icat(item):
	var iCat = itemData[item.ID].CATEGORY
	return iCat

	
func check_valid_equip(item : Dictionary, mode : int = 0): #Subweapons not fully implemented, Sub returns true regardless of which sub it is. There is no differentiation yet. 0 = Any, 1 = Weapon; 2 = Accessory
	var iCat = get_icat(item) 
	if item.DUR == 0:
		return false
	if mode < 2 and unitData.Weapons.has(iCat):
		return true
	elif mode == 0 and iCat == "ACC":
		return true
	elif mode == 2 and iCat == "ACC":
		return true
	else:
		return false
			
func update_combatdata():
	#no catch for empty inv!!!!! HERE Wait, isn't there one? setting it to Null, and then having null translate to "NONE" when all null instances could just be "NONE" is retarded. Fix this, you god damned retard.
	var terrainBonus = update_terrain_bonus()
	var equipped = get_equipped_weapon()
	var wep = itemData[equipped.ID]
	
	combatData.Type = wep.Type
	if wep.Type == Enums.DAMAGE_TYPE.PHYS:
		combatData.Dmg = wep.Dmg + activeStats.PWR
	elif wep.Type == Enums.DAMAGE_TYPE.MAG:
		combatData.Dmg = wep.Dmg + activeStats.MAG
	elif wep.Type == Enums.DAMAGE_TYPE.TRUE:
		combatData.Dmg = wep.Dmg
	combatData.ACC = activeStats.ELEG * 2 + (wep.ACC + activeStats.CHA)
	combatData.AVOID = activeStats.CELE * 2 + activeStats.CHA + terrainBonus
	combatData.GRAZE = wep.GRAZE
	combatData.GRZPRC = activeStats.ELEG + activeStats.BAR
	combatData.Crit = activeStats.ELEG + wep.Crit
	combatData.CRTAVD = activeStats.CHA
	combatData.MAGBASE = activeStats.MAG
	combatData.PWRBASE = activeStats.PWR
	combatData.ACCBASE = activeStats.ELEG * 2 + activeStats.CHA
	combatData.CRITBASE = activeStats.ELEG
	combatData.RESIST = activeStats.CHA * 2
	combatData.EFFACC = activeStats.CHA * 2
	if status.SLEEP:
		combatData.AVOID = 0
		combatData.GRZPRC = 0
		
func get_skill_combat_stats(skillId):
	var stats = combatData.duplicate()
	var skill = UnitData.skillData[skillId]
	if skill.Dmg and skill.Type == Enums.DAMAGE_TYPE.PHYS:
		stats.Dmg = stats.PWRBASE + skill.Dmg
	elif skill.Dmg and skill.Type == Enums.DAMAGE_TYPE.MAG:
		stats.Dmg = stats.MAGBASE + skill.Dmg
	elif skill.Dmg and skill.Type == Enums.DAMAGE_TYPE.TRUE: 
		stats.Dmg = skill.Dmg
	else: stats.Dmg = false
	
	if skill.CanMiss:
		stats.ACC = stats.ACCBASE + skill.ACC
	else: stats.ACC = false
	stats.Crit = stats.CRITBASE
	return stats
func update_stats():
	if baseStats == null or activeStats == null or lifeBar == null:
		return
	lifeBar.max_value = baseStats.LIFE
	lifeBar.value = activeStats.CLIFE
	if activeStats["CLIFE"] <= 0:
		run_death()
		return
	#######
	var statKeys = baseStats.keys()
	var buffTotal = {}
	for stat in statKeys:
		buffTotal[stat] = 0
	for buff in activeBuffs:
		buffTotal[buff.BuffStat] += buff.BuffValue
	for effId in activeEffects:
			if UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.BUFF or UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.DEBUFF:
				buffTotal[UnitData.effectData[effId].BuffStat] += UnitData.effectData[effId].BuffValue
	for stat in statKeys:
		activeStats[stat] = baseStats[stat] + buffTotal[stat]
	update_combatdata()
	if status.SLEEP:
		activeStats.MOVE = 0
	
#	print(unitName, ": ", activeStats)

func apply_dmg(dmg = 0):
	activeStats.CLIFE -= dmg
	activeStats.CLIFE = clampi(activeStats.CLIFE, 0, baseStats.LIFE)
	if dmg > 0 and status.SLEEP:
		cure_status("SLEEP")
	return activeStats.CLIFE
	
func apply_heal(heal = 0):
	activeStats.CLIFE += heal
	activeStats.CLIFE = clampi(activeStats.CLIFE, 0, baseStats.LIFE)
	return activeStats.CLIFE

func cure_status(statusEff): #Unnest this someday? I dunno, eat shit.
	if statusEff == "All":
		for condition in status:
			if status[condition] and sParam.has(condition) and sParam[condition].Curable:
				status[condition] = false
				sParam.erase(statusEff)
	elif status[statusEff] and sParam.has(statusEff) and sParam.Curable:
		status[statusEff] = false
		sParam.erase(statusEff)
	update_stats()
	#$PathFollow2D/Cell2.set_text(str(status))
	
	
func set_status(effect): #I wish I could inflict sleep status on myself
	if !effect:
		print("No condition found")
		return
	var statusKeys : Array = Enums.STATUS_EFFECT.keys()
	var s : String = statusKeys[effect.Status]
	status[s] = true
	sParam[s] = {"Duration":effect.Duration, "Curable":effect.Curable}
	update_stats()
	#{"Active" : true, "Duration" : duration, "Curable" : isCurable}
	#$PathFollow2D/Cell2.set_text(str(status))
	
func check_status(condition:String):
	if status[condition]:
		return true
	else:
		return false

func set_acted(actState: bool):
	status.ACTED = actState
	match status.ACTED:
		false: _animPlayer.play("idle")
		true: 
			_animPlayer.play("disabled")

func _on_test_map_map_ready():
	var coord = $PathFollow2D/Cell
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)
	originCell = cell
	coord.set_text(str(cell))

#Turn Signals
func on_turn_changed():
	check_passives()
func on_turn_order_updated(_to):
	status_duration_tick()
	
#DEATH
func run_death():
	#if FACTION_ID != FACTION_ID.PLAYER:
		#unitData.erase(unitId)
#	emit_signal("imdead", self)
	fade_out(1.0)
		
func fade_out(duration: float):
	needDeath = true
	_animPlayer.play("death")
	await get_tree().create_timer(duration).timeout
	$PathFollow2D/HPbar.visible = false
	emit_signal("death_done", self)
	
	
func update_terrain_data(data : Array):
	terrainData = data
	
func update_terrain_bonus():
#	print(combatData.AVOID)
	var bonus = 0
	if deployed:
		var i = find_nested(terrainData, Vector2i(cell))
		if i != -1:
			bonus = terrainData[i][2]
		return bonus
	else:
		return 0

	
func find_nested(array, value):
#	print(value)
	if array == null:
		return -1
	for i in range(array.size()):
#		print(array[i])
		if array[i].find(value) != -1:
			return i
	return -1

func relocate_unit(location, gridUpdate = true): 
	var oldCell = cell
	var coord = $PathFollow2D/Cell
	cell = location
	coord.set_text(str(cell)) #not updated when a unit moves normally, oops
	position = map.map_to_local(cell)
	
	if gridUpdate:
		emit_signal("unit_relocated", oldCell, cell, self)
	
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)
	
func _on_animation_player_animation_finished(_animName):
	pass
	#HERE
	
func add_exp(action, _target = null): ##Adds exp if a unit is a place, as well as returning 'true', returns 'false' if not a player unit.
	if FACTION_ID != Enums.FACTION_ID.PLAYER:
		return false

	var xpVal = 0
	var results
	var oldStats = unitData.Stats.duplicate()
	var oldLevel = unitData.Profile.Level
	#var targetLevel
	var oldExp = unitData.Profile.EXP
	var expSteps = []
	var portrait = unitData.Profile.Prt
	var lvlLoops = 0
	var levelUpReport = {}

	#if target != null:
		#targetLevel = target.unitData.Profile.Level
#	print(unitData.Profile.EXP)
	match action:
		"Kill": xpVal = 150
		"Support": xpVal = 60
		"Generic": xpVal = 60
	unitData.Profile.EXP += xpVal
	
#	print(unitData.Profile.EXP)
	if unitData.Profile.EXP <= 100:
		expSteps.append(unitData.Profile.Exp) 
		
	if unitData.Profile.EXP >= 100 and unitData.Profile.Level < 20:
		var expBracket = unitData.Profile.EXP
		while expBracket > 100:
			expSteps.append(100)
			expBracket -= 100
			
			if expBracket < 100:
				expSteps.append(expBracket)
		
		while unitData.Profile.EXP > 100:	
			unitData.Profile.EXP = unitData.Profile.EXP - 100
			lvlLoops += 1
			
		results = UnitData.level_up(unitData, lvlLoops).duplicate()
		levelUpReport["Results"] = results
		levelUpReport["Levels"] = lvlLoops
		levelUpReport["OldStats"] = oldStats
		levelUpReport.OldStats["LVL"] = oldLevel
#		print(unitData)
	emit_signal("exp_gained", oldExp, expSteps, levelUpReport, portrait, unitData.Profile.UnitName)
	return true

func map_start_init():
	originCell = map.local_to_map(position) #BUG GY
	#print(originCell)
	


#func get_equipped_items(): #returns Array of equipped items, stored in dictionaries: Item ID, Inventory Index; item category [{"ITEM":id, "INDEX": i, "CAT": c}]
	#var inv = unitData.Inv
	#var i : int = 0
	#var equipment : Array = [] 
	#for item in inv:
		#if item.EQUIP == true:
			#var p : Dictionary = {}
			#var c = get_icat(item)
			#p["ID"] = item.ID
			#
			
			
