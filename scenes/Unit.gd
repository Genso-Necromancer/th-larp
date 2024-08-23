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

@export var preDefined : bool = false
@export var generate : bool = true
@export_enum("Enemy", "Player", "NPC") var faction: String = "Enemy"
@export_enum("Fairy", "Human", "Kappa", "Lunarian", "Oni", "Doll", "Devil", "Yukionna", "Zombie", "Hermit", "Magician", "Spirit") var species: String = "Fairy"
@export_enum("Trblr", "Thief") var job: String = "Trblr"
@export var inventory: Array[String] = []

#Profile
@export var unitId = "unitID"
@export var unitName = "Name"
@export var move_speed := 150.0
@export var genLevel : int = 1
var deployed : bool = false
var forced : bool = false
var unitData
var itemData = UnitData.itemData
var allUnitData
var groupKeys = UnitData.groups
#var statKeys = UnitData.stats
var ykTag
var acted = false
var moveType = "Foot"
var needDeath = false
var terrainData

#equip variables
var unarmed = {"DATA": "NONE", "EQUIP": true, "DUR": -1}
var tempSet : bool = false
#status effects
var activeStatus = {"Sleep" : {"Active": false}}



#Call for pre-formualted combat stats
var combatData = {"DMG": 0, "HIT": 0, "AVOID": 0, "GRAZE": 0, "GRZPRC": 0, "CRIT": 0, "CRTAVD": 0, "TYPE":"Physical"}
#base stats of the unit
var baseStats = {}
#combination of base stats and buffs
var activeStats = {}
#de/buffs applied to unit
var activeBuffs = {}
var activeEffects = []
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
			_anim_player.play("selected")
		elif acted == false:
			_anim_player.play("idle")
		elif acted == true:
			_anim_player.play("disabled")

var _is_walking := false:
	set(value):
		_is_walking = value
#		set_process(_is_walking)
#var position := Vector2.ZERO:
#	set(value):
#		position = map.hex_centered(value)

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _anim_player: AnimationPlayer = $PathFollow2D/Sprite/AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D
@onready var map = get_parent()
@onready var lifeBar = $PathFollow2D/HPbar
var last_glb_position = Vector2.ZERO
var originCell

var walk_directions = [
	"walk_left",
	"walk_up",
	"walk_right",
	"walk_down",
]
var walk_directions_size = float(walk_directions.size())

#test
var spawnLoc
var originLocation

func _ready() -> void:
#	print(statVars)
#	#print("unit.gd:", unitId)
	set_process(false)
	_anim_player.play("idle")
	if preDefined:
		_load_stats()
		_load_sprites()
		if map.get_class() != "TileMap": #may not need in future, too specific to "test map"
			pass
		elif !map.map_ready.is_connected(self._on_test_map_map_ready):
			map.map_ready.connect(self._on_test_map_map_ready)
		
		# We create the curve resource here because creating it in the editor prevents us from
		# moving the unit.
		if not Engine.is_editor_hint():
			curve = Curve2D.new()
	else:
		if not Engine.is_editor_hint():
			curve = Curve2D.new()
	
	
func init_player_unit(iD):
	unitId = iD
	faction = "Player"
	_load_stats()
	_load_sprites()
	

func _process(delta: float) -> void:
	if needDeath:
		return
	if _is_walking == true:
		_path_follow.progress += move_speed * delta
		var current_move_vec = _sprite.global_position - last_glb_position
		last_glb_position = _sprite.global_position
	#	#print(last_glb_position)
		var norm_move_vec = current_move_vec.normalized()
		var direction_id = int(walk_directions_size * (norm_move_vec.rotated(PI / walk_directions_size).angle() + PI) / TAU)
		_anim_player.play(str(walk_directions[direction_id]))
	
	
	if _path_follow != null && _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = map.map_to_local(cell)
		curve.clear_points()
		_anim_player.play("idle")
		emit_signal("walk_finished")
	
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
	allUnitData = UnitData
	if faction == "Player":
		add_to_group("Player")
		unitData = UnitData.unitData[unitId].duplicate(true)
		baseStats = unitData.Stats
		unitName = unitData["Profile"]["UnitName"]
		check_passives()
		activeStats["CLIFE"] = baseStats["LIFE"]
	if faction == "Enemy":
		add_to_group("Enemy")
		var unique = false
		var baseTag = "youkai"
		var counter = 0
		var globalUD = UnitData.unitData
		if species == null or job == null:
			print("No Job, Weapon or Species.")
			return
		else:
			
			while !unique:
				ykTag = baseTag + str(counter)
				if UnitData.unitData.has(ykTag):
					counter += 1
				elif !UnitData.unitData.has(ykTag):
					unique = true
					UnitData.stat_gen(ykTag, genLevel, species, job)
			unitData = globalUD[ykTag].duplicate(true)
			baseStats = unitData.Stats.duplicate(true)
			activeStats["CLIFE"] = baseStats["LIFE"]
			
		update_stats()
		_init_inv()
	
	
#	var groups = get_groups()
#	print(unitName, " ", groups)


		
#keep track of active de/buffs during gameplay, seperate from actual stats
func apply_buff(attribute, effId, stat, buff, duration, curable = true, selfCast = false, source = ""):
	var _isBuff = false
	
	if effId == null:
		print("No SkillID found")
		return
	if duration == 0:
		unitData.Stats[stat] += buff
	else:
		activeBuffs[effId] = {}
		activeBuffs[effId]["Type"] = attribute
		activeBuffs[effId]["Stat"] = stat
		activeBuffs[effId]["Mod"] = buff
		activeBuffs[effId]["Duration"] = duration
		activeBuffs[effId]["Curable"] = curable
		#the following are currently not considered worth using. Thought they were needed, but don't see a purpose currently.
		activeBuffs[effId]["Fresh"] = selfCast
		activeBuffs[effId]["Source"] = source
	update_stats()
	
	
#tracks duration of effects, then removes them when reaching 0
func status_duration_tick():
	var idKeys = activeBuffs.keys()
	var statusKeys = activeStatus.keys()
	for skillId in idKeys:
#		var statKeys = activeBuffs[skillId].keys()
#		for stat in statKeys:
		if activeBuffs[skillId].Fresh:
			activeBuffs[skillId].Fresh = false
			continue
		if activeBuffs[skillId].Duration > 0:
			activeBuffs[skillId].Duration -= 1
		if activeBuffs[skillId].Duration == 0:
			activeBuffs.erase(skillId)
			
	for status in statusKeys:
		if activeStatus[status].Active and activeStatus[status].Duration > 0:
			activeStatus[status].Duration -= 1
		if activeStatus[status].Active and activeStatus[status].Duration == 0:
			activeStatus[status] = {"Active": false}
	$PathFollow2D/Cell2.set_text(str(activeStatus.Sleep.Active))
#	print(activeBuffs)
	update_stats()
	
func _load_sprites():
	
	if faction == "Player":
		_sprite.texture = unitData["Profile"]["Sprite"]
		_sprite.self_modulate = Color(1,1,1)
	if faction == "Enemy":
		_sprite.self_modulate = Color(1,0,0)
	_path_follow.rotates = false
	_anim_player.play("idle")
	
func _init_inv():
	var limit = unitData.MaxInv
	if inventory.size() < 1:
		return
	for thing in inventory:
		if unitData.Inv.size() >= limit:
			break
		var dur = itemData[thing].MAXDUR
		var newItem : Dictionary = {"DATA": thing, "EQUIP": false, "DUR": dur}
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
	
func get_equipped_weapon(): #returns the currently equipped weapon within inventory. use .DATA to find global statistics. Return generic "unarmed" if there is none.
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
	
func get_equipped_acc(): #returns the currently equipped accessories within inventory. use .DATA to find global statistics. Return false if none.
	
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
	var iData = UnitData.itemData[item.DATA]
	if iData.EFFECT and iData.EFFECT.size() > 0:
		for effect in iData.EFFECT:
			_add_effect(effect)
		print(activeEffects)
		
func _remove_equip_effects(item):
	var iData = UnitData.itemData[item.DATA]
	if iData.has("EFFECT"):
		for effect in iData.EFFECT:
			var i = activeEffects.find(effect)
			activeEffects.remove_at(i)
	print(activeEffects)
	
func get_icat(item):
	var iCat = itemData[item.DATA].CATEGORY
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
	var stat = activeStats
	var wep = itemData[equipped.DATA]
	
	combatData.TYPE = wep.TYPE
	if wep.TYPE == "Physical":
		combatData.DMG = wep.DMG + stat.PWR
	else:
		combatData.DMG = wep.DMG + stat.MAG
	combatData.ACC = stat.ELEG * 2 + (wep.ACC + stat.CHA)
	combatData.AVOID = stat.CELE * 2 + stat.CHA + terrainBonus
	combatData.GRAZE = wep.GRAZE
	combatData.GRZPRC = stat.ELEG + stat.BAR
	combatData.CRIT = stat.ELEG + wep.CRIT
	combatData.CRTAVD = stat.CHA
	combatData.MAGBASE = stat.MAG
	combatData.PWRBASE = stat.PWR
	combatData.ACCBASE = stat.ELEG * 2 + stat.CHA

func update_stats():
	if baseStats == null or activeStats == null or lifeBar == null:
		return
	lifeBar.max_value = baseStats.LIFE
	lifeBar.value = activeStats.CLIFE
	if activeStats["CLIFE"] <= 0:
		run_death()
	#######
		
	var statKeys = baseStats.keys()
	var idKeys = activeBuffs.keys()
	var buffTotal = {}
	for stat in statKeys:
		buffTotal[stat] = 0
	for id in idKeys:
		buffTotal[activeBuffs[id].Stat] += activeBuffs[id].Mod
	for stat in statKeys:
		activeStats[stat] = baseStats[stat] + buffTotal[stat]
	update_combatdata()
	if activeStatus.Sleep.Active:
		activeStats.MOVE = 0
		combatData.AVOID = 0
		combatData.GRZPRC = 0
#	print(unitName, ": ", activeStats)

func apply_dmg(dmg = 0):
	activeStats.CLIFE -= dmg
	activeStats.CLIFE = clampi(activeStats.CLIFE, 0, baseStats.LIFE)
	if dmg > 0 and activeStatus.Sleep.Active:
		cure_status("Sleep")
	return activeStats.CLIFE
	
func apply_heal(heal = 0):
	activeStats.CLIFE += heal
	activeStats.CLIFE = clampi(activeStats.CLIFE, 0, baseStats.LIFE)
	return activeStats.CLIFE

func cure_status(statusEff):
	if statusEff == "All":
		for status in activeStatus:
			if activeStatus[status].Curable:
				activeStatus[status] = {"Active" : false}
	elif activeStatus[statusEff].Active and activeStatus.Curable:
		activeStatus[statusEff] = {"Active" : false}
	$PathFollow2D/Cell2.set_text(str(activeStatus.Sleep.Active))
	update_stats()

func _on_test_map_map_ready():
	var coord = $PathFollow2D/Cell
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)
	originCell = cell
	coord.set_text(str(cell))


#func on_combat_resolved():
#	update_stats()
	
func on_turn_changed():
	check_passives()
	
	

func run_death():
	if faction != "Player":
		unitData.erase(ykTag)
#	emit_signal("imdead", self)
	fade_out(1.0)
	
		
func fade_out(duration: float):
	needDeath = true
	_anim_player.play("death")
	await get_tree().create_timer(duration).timeout
	$PathFollow2D/HPbar.visible = false
	emit_signal("death_done", self)
	
	

func set_status(status, duration, isCurable): #I wish I could inflict sleep status on myself
	if status == null:
		print("No SkillID found")
		return
	activeStatus[status] = {"Active" : true, "Duration" : duration, "Curable" : isCurable}
	$PathFollow2D/Cell2.set_text(str(activeStatus.Sleep.Active))
	
func check_status(status): #FIX find a way to set a generic "disabled" status, regardless of disabling debuff so a specific status isn't necessary to check for.
	if activeStatus[status].Active:
		return true
	else:
		return false

func set_acted(actState: bool):
	acted = actState
	match acted:
		false: _anim_player.play("idle")
		true: 
			_anim_player.play("disabled")
			status_duration_tick()
	
	
func update_terrain_data(data):
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
	if self.faction != "Player":
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
			
		results = allUnitData.level_up(unitData, lvlLoops).duplicate()
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
	
func _add_effect(effect):
	activeEffects.append(effect)
		
func _remove_effect(effect):
	var i = activeEffects.find(effect)
	activeEffects.remove_at(i)

#func get_equipped_items(): #returns Array of equipped items, stored in dictionaries: Item ID, Inventory Index; item category [{"ITEM":id, "INDEX": i, "CAT": c}]
	#var inv = unitData.Inv
	#var i : int = 0
	#var equipment : Array = [] 
	#for item in inv:
		#if item.EQUIP == true:
			#var p : Dictionary = {}
			#var c = get_icat(item)
			#p["ID"] = item.DATA
			#
			
			
