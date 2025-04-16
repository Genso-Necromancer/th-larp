@tool
class_name Unit
extends Path2D
signal walk_finished
signal exp_handled
signal death_done
signal unit_relocated
signal exp_gained
signal leveled_up
signal post_complete
signal turn_complete(unit)
signal effect_complete

signal item_targeting(item, unit)
signal item_activated(item, unit, target)





var defaultId := "UnitId"
enum AI_TYPE {
	NONE,
	DEFENDER,
	OFFENDER,
	SUPPORT,
	BOSS
}
##Unit Parameters
@export_category("Unit Parameters")
@export_group("Base Parameters")
@export var generate : bool = true ##Toggle on for randomly leveled stats based on growths, Toggle Off to use predefined stats
@export var unitId := "UnitId" ## Only change if unique unit
@export var disabled := false:
	get:
		return disabled
	set(value):
		disabled = value
		set_process(!value)

var unitName := "" #Presented strings will eventually be taken from a seperate file
@export var FACTION_ID :Enums.FACTION_ID = Enums.FACTION_ID.ENEMY
@export_group("Generated Only")
@export var SPEC_ID :Enums.SPEC_ID= Enums.SPEC_ID.FAIRY 
@export var JOB_ID :Enums.JOB_ID= Enums.JOB_ID.TRBLR
@export var genLevel : int = 1
@export_group("Spawn Parameters")
@export var isForced := false
@export var isActive := true
@export_category("AI Paramters")
@export var isBoss : bool = false
@export var isMidBoss : bool = false
@export var archetype :AI_TYPE = AI_TYPE.NONE
@export var leash : int = -1 ##Number of spaces a target must be for the them move and attack. -1 turns this off.
@export var one_time_leash:bool = false ##True: After a unit is moved, their leash value will be set to -1 False: Unit never loses it's leash value
@export_category("Animation Values")
@export var moveSpeed := 200.0
@export var shoveSpeed := 350.0
@export var tossSpeed := 350.0

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _animPlayer: AnimationPlayer = $PathFollow2D/Sprite/AnimationPlayer
@onready var _pathFollow: PathFollow2D = $PathFollow2D
@onready var lifeBar = $PathFollow2D/Sprite/HPbar
@onready var map = get_parent()

#status effects
@export_category("Conditions")
@export var status : Dictionary = {"Acted":false, "Sleep":false}
var sParam : Dictionary = {}



@export_category("Inventory")
var _items : String:
	get:
		return _items
	set(value):
		_items = "NONE"
		_add_initial_item(value)
		if value != "NONE":
			print(value)
			
var inventory: Array[String]: #revisit this for ease of selection
		get:
			return inventory
		set(value):
			inventory = value
			update_configuration_warnings()
			notify_property_list_changed.call_deferred()



var firstLoad := false
var tick = 1
var deployed : bool = false
var forced : bool = false

var needDeath := false
var deathFlag := false
var killer : Unit
var terrainTags: Dictionary = {"BaseType": "", "ModType": "", "BaseId": "", "ModId": "", "Locked": false}
var postSequenceFlags := {"Bars":false, "Death":false}

#equip variables
var natural  : Dictionary = {"ID": "NONE", "Equip": false, "Dur": -1, "Broken": false}
var unarmed := {"ID": "NONE", "Equip": false, "Dur": -1, "Broken": false}
var tempSet = false


#unit base data
var unitData : Dictionary
#Call for pre-formualted combat stats
var combatData := {"Dmg": 0, "Hit": 0, "Graze": 0, "Barrier": 0, "BarPrc": 0, "Crit": 0, "Luck": 0, "Resist": 0, "EffHit":0, "DRes": 0, "Type":Enums.DAMAGE_TYPE.PHYS, "CanMiss": true}
var isAmbushing := false

#base stats of the unit
var baseCombat := {}
var baseStats := {}
#aura owned by unit
var unitAuras := {}
#combination of base stats and buffs
var activeStats :Dictionary= {}
#de/buffs applied to unit
var activeBuffs := {}
var activeDebuffs := {}
var activeEffects := []
var activeAuras := {}
var bonusSkills := []

#Unique NPC/Enemy params
var isElite : bool = false

#Danmaku
var danmakuTypes := {}
var masterOf : String

## Coordinates of the current cell the cursor moved to.
var cell := Vector2i.ZERO:
	set(value):
		cell = map.cell_clamp(value)
var lastGlbPosition := Vector2.ZERO
var originCell

# Toggles the "selected" animation on the unit.
var isSelected := false:
	set(value): #Buggy, causes idling when hovering unit after selecting and choosing movement
		isSelected = value
		if isSelected:
			_animPlayer.play("selected")
			#print(unitId,":", _animPlayer.current_animation,":","Selected")
		elif status.Acted == false:
			_animPlayer.play("idle")
			#print(unitId,":", _animPlayer.current_animation,"Selected")
		elif status.Acted == true:
			_animPlayer.play("disabled")
			#print(unitId,":", _animPlayer.current_animation,"Selected")

#Animation Variables
var isWalking := false
var isShoved := false
var isTossed := false
var isHurt := false
var cDir := ""
var cAnim := ""
var pathPaused := false
var walkDirections := [
	"walk_left",
	"walk_up",
	"walk_right",
	"walk_down",
]
var shoveDirections := [
	"shoved_left",
	"shoved_right",
	"shoved_right",
	"shoved_left"
]
var tossDirections := [
	"tossed_from_left",
	"tossed_from_right",
	"tossed_from_right",
	"tossed_from_left"
]

var walkDirectionsSize := float(walkDirections.size())
var shoveDirectionsSize := float(shoveDirections.size())
var tossDirectionsSize := float(tossDirections.size())
var lastAnim := "idle"

#test
var spawnLoc
var originLocation

func _ready() -> void:
	var hitBox = $PathFollow2D/Sprite/UnitArea
#	print(statVars)
#	#print("unit.gd:", unitId)
	set_process(false)
	_animPlayer.play("idle")
	#print(unitId,":", _animPlayer.current_animation,"Ready")
	#if generate and !UnitData.unitData.has(unitId):
		#_generate_id()
	_load_stats()
	_load_sprites()
	_validate_skills()
	hitBox.set_master(self)
	hitBox.area_entered.connect(self._on_aura_entered)
	hitBox.area_exited.connect(self._on_aura_exited)
	if map.get_class() != "TileMap": #may not need in future, too specific to "test map"
		pass
	elif !map.map_ready.is_connected(self._on_test_map_map_ready):
		map.map_ready.connect(self._on_test_map_map_ready)
	

	
	#Create the curve resource here because creating it in the editor prevents moving the unit
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
	update_stats()
	#move type debugging
	#var testKey = UnitData.MOVE_TYPE.keys()[unitData.MoveType]
	#print(str(unitName) + " Move Type: " + str(testKey))


#region property list functions
func _get_property_list():
	var properties = []
	properties.append({
		"name" : "_items",
		"type" : TYPE_STRING,
		"hint" : PROPERTY_HINT_ENUM,
		"hint_string" : _array_to_string(UnitData.get_item_keys())
		#"hint_string" : _array_to_string(UnitData.get_item_keys())
	})
	properties.append({
		"name" : "inventory",
		"type" : TYPE_ARRAY,
		"hint" : PROPERTY_HINT_TYPE_STRING,
		"hint_string" : "%d:" % [TYPE_STRING]
	})
	return properties

func _array_to_string(arr: Array, seperator = ",") -> String:
	var string = ""
	for i in arr:
		string += str(i)+seperator
	return string
#endregion

func _add_initial_item(item:String):
	if item != "NONE":
		inventory += [item]

func init_unit(currentMap:GameMap, unique:bool = !generate, newFaction := FACTION_ID, id : String = "none", elite = false, lv = genLevel, spec = SPEC_ID, job = JOB_ID):
	FACTION_ID = newFaction
	isElite = elite
	map = currentMap
	if id != "none":
		unitId = id
	if unique:
		generate = false
	else:
		generate = true
		genLevel = lv
		SPEC_ID = spec
		JOB_ID = job
	return self
	#_load_stats()
	#_load_sprites()


func _process(delta: float) -> void:
	if tick == 0:
		var coord = $PathFollow2D/Cell
		coord.set_text(str(cell))
		tick = 1
	else:
		tick -= 1
	
	#swapped above needDeath, may break something. Return below if need be.
	if !pathPaused: _process_motion(delta)
	
	if needDeath:
		return
	
	#if firstLoad:
		#firstLoad = false
		#update_stats()



func _process_motion(delta):
	var directions
	var directionsSize
	var motion
	var speed
	if isShoved:
		directions = shoveDirections
		directionsSize = shoveDirectionsSize
		motion = "shove"
		speed = shoveSpeed
	elif isWalking:
		directions = walkDirections
		directionsSize = walkDirectionsSize
		motion = "walk"
		speed = moveSpeed
	elif isTossed:
		directions = tossDirections
		directionsSize = tossDirectionsSize
		motion = "toss"
		speed = tossSpeed
	
	if isShoved or isWalking or isTossed:
		var current_move_vec 
		var norm_move_vec 
		var direction_id 
		
		lastGlbPosition = _sprite.global_position

		_pathFollow.progress += speed * delta
		current_move_vec = _sprite.global_position - lastGlbPosition
		lastGlbPosition = _sprite.global_position
		
		norm_move_vec = current_move_vec.normalized()
		direction_id = int(directionsSize * (norm_move_vec.rotated(PI / directionsSize).angle() + PI) / TAU)
	
	
		_animPlayer.play(str(directions[direction_id]))
		
		
	if _pathFollow != null and _pathFollow.progress_ratio >= 1.0:
		#print("SHOULDN'T SEE BELOW 1.0 ",_pathFollow.progress_ratio)
		# Setting this value to 0.0 causes a Zero Length Interval error
		_pathFollow.progress = 0.00001
		lastGlbPosition = Vector2(0,0)
		cDir = ""
		cAnim = ""
		position = map.map_to_local(cell)
		curve.clear_points()
		
		match motion:
			"walk": 
				isWalking = false
				emit_signal("walk_finished")
			"shove": 
				isShoved = false
				revert_animation()
				emit_signal("effect_complete")
			"toss": 
				isTossed = false
				emit_signal("effect_complete")
		emit_signal("unit_relocated", originCell, cell, self)
		


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
#	#print("walk along")
	lastAnim = _animPlayer.current_animation
	if path.is_empty():
		print("walk_along Path Empty")
		return
#	#print(cell)
	originCell = map.local_to_map(position)
#	print(originCell)
#	#print(originCell, cell)
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(map.map_to_local(point) - position)
	#print(curve.point_count)
	#print(path)
	cell = path[-1]
#	print(path[-1])
	isWalking = true
#	print("unit cell: ", cell)
#	print("unit position: ", position)
	

func shove_unit(location):
	var oldCell = cell
	var path = [cell, location]
	
	lastAnim = _animPlayer.current_animation
	
	if cell > location:
		_animPlayer.play("shoved_left")
	else:
		_animPlayer.play("shoved_right")
	
	#print("Shoved: ", _animPlayer.current_animation)
	originCell = map.local_to_map(position)
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(map.map_to_local(point) - position)
	cell = path[-1]
	isShoved = true
	emit_signal("unit_relocated", oldCell, cell, self)
	
	#position = map.map_to_local(cell)
	#
	#cell = map.local_to_map(position)
	#position = map.map_to_local(cell)
	
func toss_unit(location):
	var oldCell = cell
	var path = [cell, location]
	#localMiddle.x = ((localCell.x + localLocation.x) / 2)
	#localMiddle.y = ((localCell.y + localLocation.y) / 2) - 100
	lastAnim = _animPlayer.current_animation
	originCell = map.local_to_map(position)
	curve.add_point(Vector2.ZERO)
	curve.add_point(map.map_to_local(cell) - position)
	#curve.add_point(localMiddle - position)
	curve.add_point(map.map_to_local(location) - position)
	cell = path[-1]
	isTossed = true
	emit_signal("unit_relocated", oldCell, cell, self)


func relocate_unit(location, gridUpdate = true):
	var oldCell = cell
	
	cell = location
	position = map.map_to_local(cell)
	
	if gridUpdate:
		emit_signal("unit_relocated", oldCell, cell, self)
	
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)

func play_arrival(path):
	var arrival : String
	var tween = get_tree().create_tween()
	var color = _sprite.get_self_modulate()
	var delay = 1
	pass
	#print("MODULATION:",_sprite.get_self_modulate())
	color.a = color.a - 1
	_sprite.set_self_modulate(color)
	color.a = color.a + 1
	
	
	walk_along(path)
	#print("MODULATION:",get_self_modulate())
	tween.tween_property(_sprite, "self_modulate", color, delay).set_trans(Tween.TRANS_LINEAR)
	#print("MODULATION:",get_self_modulate())
	
	
	
func play_animation(anim):
	lastAnim = _animPlayer.current_animation
	_animPlayer.play(anim)


func revert_animation():
	if _animPlayer.current_animation == lastAnim:
		return
	#print(lastAnim, " surely I will return to idle")
	_animPlayer.play(lastAnim)
	#print(unitId,":", _animPlayer.current_animation,"Revert")

func toggle_path_pause():
	pathPaused = !pathPaused

func return_original():
	position = map.map_to_local(originCell)
	cell = originCell
#	#print(originCell, cell)
	return cell
	

func _load_stats():
	var specKeys := Enums.SPEC_ID.keys()
	var path : String
	var tempTag
	var genData
	
	if generate:
		genData = UnitData.stat_gen(JOB_ID, SPEC_ID)
		if not Engine.is_editor_hint():
			unitId = UnitData.generate_id()
			UnitData.add_to_unitdata(genData, unitId)
			unitData = UnitData.unitData[unitId]
			
		else:
			unitData = genData
			
	else:
		unitData = UnitData.unitData[unitId]
	
	
	match FACTION_ID:
		Enums.FACTION_ID.PLAYER: 
			add_to_group("Player") #maybe redundant? can think of situations it isn't.
		Enums.FACTION_ID.ENEMY: 
			add_to_group("Enemy")
		Enums.FACTION_ID.NPC:
			add_to_group("NPC")
	if unitName == "" and !generate:
		path = "unit_name_%s" % [unitId.to_snake_case()]
		unitName = StringGetter.get_string(path)
	elif unitName == "" and generate:
		var strings : Array = []
		var template : String = StringGetter.get_template("unit_name")
		strings.append(StringGetter.get_string("species_name_%s" % [specKeys[unitData.Profile.Species].to_snake_case()]))
		strings.append(StringGetter.get_string("role_name_%s" % [unitData.Profile.Role.to_snake_case()]))
		unitName = StringGetter.mash_string(template, strings)
		
		
	if generate and genLevel > 1:
		UnitData.level_up(unitData, genLevel-1)
	
	baseStats = unitData.Stats.duplicate(true)
	activeStats["CurLife"] = baseStats.Life
	activeStats["CurComp"] = baseStats.Comp
	activeStats["MoveType"] = unitData.MoveType
	activeStats["Weapons"] = unitData.Weapons
	activeStats["Skills"] = unitData.Skills
	
	update_stats()
	_init_inv()
	firstLoad = true

func _validate_skills():
	if !unitData.has("Skills"):
		return
	for skillId in unitData.Skills:
		if !UnitData.skillData.has(skillId):
			unitData.Skills.erase(skillId)
			print(str(unitName) + ": Invalid SkillId. Removed.")
		

#keep track of active de/buffs during gameplay, seperate from actual stats
#re-evaluate the variable names, and if so many are necessary. VOODOO WARNING HERE
func set_buff(effId, effect):
	var statKeys : Array = Enums.CORE_STAT.keys()
	var type = effect.Type
	var buffs
	match type:
		Enums.EFFECT_TYPE.BUFF: buffs = activeBuffs
		Enums.EFFECT_TYPE.DEBUFF: buffs = activeDebuffs
	if effId == null:
		print("No effId found")
		return
	if effect.Stack:
		var i = 0
		var newId = effId + str(i)
		while buffs.has(newId):
			i += 1
			newId = effId + str(i)
		effId = newId
	if effect.DurationType == Enums.DURATION_TYPE.PERMANENT:
		var stat : String = statKeys[effect.SubType]
		unitData.Stats[stat] += effect.Value
	else:
		buffs[effId] = effect.duplicate(true)
	update_stats()
	
	
func remove_buff(effId):
	if activeBuffs.has(effId):
		activeBuffs.erase(effId)
	elif activeDebuffs.has(effId):
		activeDebuffs.erase(effId)
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
			
	$PathFollow2D/Cell2.set_text(str(status.Sleep))
#	print(activeBuffs)
	update_stats()
	
	
func _load_sprites():
	if !generate: 
		_sprite.texture = unitData["Profile"]["Sprite"]
	else: 
		_sprite.texture = UnitData.get_generated_sprite(SPEC_ID, JOB_ID)
	match FACTION_ID:
		Enums.FACTION_ID.ENEMY: _sprite.self_modulate = Color.RED
		Enums.FACTION_ID.PLAYER: _sprite.self_modulate = Color(1, 1, 1)
	#print("MODULATION:",get_self_modulate())
		
	_pathFollow.rotates = false
	_animPlayer.play("idle")
	#print(unitId,":", _animPlayer.current_animation,"Load Sprite")
	
func _init_inv():
	var limit = unitData.MaxInv
	var initInv = inventory
	var rng = RandomNumberGenerator.new()
	var usedIds = []
	if FACTION_ID == Enums.FACTION_ID.PLAYER:
		initInv = unitData.SpawnGear
	if initInv.size() < 1:
		return
	for thing in initInv:
		
		if unitData.Inv.size() >= limit:
			break
			
		var dur = UnitData.itemData[thing].MaxDur
		
		var uId = rng.randi()
		while usedIds.has(uId):
			uId = rng.randi()
		usedIds.append(uId)
		
		var newItem : Dictionary = {"ID": thing, "Equip": false, "Dur": dur, "UniqueId": uId,}
		if UnitData.itemData.has(thing):
			unitData.Inv.append(newItem)
		else:
			print("Invalid item ID: " + str(thing))
	#print(unitName + ": " + str(unitData.Inv))
	set_equipped()

func get_condition() -> Dictionary: #maybe expand this in the future, for now that's all
	var c: Dictionary = {}
	c["Hp%"] = (activeStats.CurLife / activeStats.Life) * 100
	c["Comp"] = activeStats.CurComp
	c["Status"] = status.duplicate(true)
	return c

func can_act() -> bool:
	if activeStats.CurLife <= 0 or status.Sleep or get_equipped_weapon() == unarmed:
		return false
	return true


#Passive Functions
func check_passives():
	var passives = unitData.Passives
	var pData = UnitData.passiveData
	var valid = []
	
	for id in passives:
		var p = pData[id]
		match p.Type:
			Enums.PASSIVE_TYPE.AURA:
				valid.append(_assign_auras(p))
			Enums.PASSIVE_TYPE.SUB_WEAPON:
				_add_sub_type(p.SubType)
				_update_natural(p)
				
	validate_auras(valid)


##Non-permanent Skills Function
func validate_skills():
	var skills = unitData.Skills
	var sData = UnitData.skillData
	var valid = []
	for id in skills:
		var s = sData[id]
		match s.Target:
			Enums.EFFECT_TARGET.EQUIPPED: pass
				
	validate_auras(valid)


##Validate skills from effects
func validate_active_effect_skills():
	var eData = UnitData.effectData
	for skill in bonusSkills:
		unitData.Skills.erase(skill)
	bonusSkills.clear()


	for effId in activeEffects:
		if eData[effId].Type == Enums.EFFECT_TYPE.ADD_SKILL:
			_resolve_bonus_skill(effId)


func _resolve_bonus_skill(effId: String) -> void:
	var data = UnitData.effectData[effId]
	if unitData.Skills.has(data.Skill): return
	else: 
		bonusSkills.append(data.Skill)
		unitData.Skills.append(data.Skill)


func _add_sub_type(subType):
	var st = Enums.WEAPON_CATEGORY.keys()[subType]
	activeStats.Weapons.Sub.append(st)



func _assign_auras(passive:Dictionary) -> StringName:
	var aura : StringName 
	match passive.RuleType:
		Enums.RULE_TYPE.MORPH: aura = passive[Enums.TIME.keys()[Global.timeOfDay].to_pascal_case()]
		Enums.RULE_TYPE.TIME: 
			if passive.Rule == Global.timeOfDay: aura = passive.Aura
		_: aura = passive.Aura
	if !unitAuras.has(aura):load_aura(aura)
	return aura


func check_time_prot() -> bool:
	var passives = unitData.Passives
	var pData = UnitData.passiveData
	var validTime
	Global.timeOfDay
	for id in passives:
		var p = pData[id]
		match p.Type:
			Enums.PASSIVE_TYPE.NIGHT_PROT:
				validTime = Enums.TIME.NIGHT
			Enums.PASSIVE_TYPE.DAY_PROT:
				validTime = Enums.TIME.DAY
			_: continue
		if p.Rule == SPEC_ID and Global.timeOfDay == validTime:
			return true
	return false


func search_passive_id(type):
	var highest = 0
	var found = false
	for passive in unitData.Passives:
		var p = UnitData.passiveData[passive]
		if p.Type == type and p.Value > highest:
			highest = p.Value
			found = passive
	return found


##Aura Functions
func validate_auras(valid:Array):
	for a in unitAuras:
		if !valid.has(a):
			remove_aura(a)


func remove_aura(a):
	if unitAuras.has(a):
		unitAuras[a].queue_free()
		unitAuras.erase(a)


func load_aura(id):
	if unitAuras.has(id):
		return
	var auData = UnitData.auraData
	var a = auData[id]
	var auraArea = preload("res://scenes/aura_collision.tscn").instantiate()
	var pathFollow = $PathFollow2D
	
	pathFollow.add_child(auraArea)
	auraArea.call_deferred("set_aura",self, a)
	unitAuras[id] = auraArea
	
	
func get_visual_aura_range() -> int:
	var auData = UnitData.auraData
	var pData = UnitData.passiveData
	var highest := 0
	for p in unitAuras:
		var a = auData[pData[p].Aura]
		if a.Range > highest:
			highest = a.Range
	return highest
		

func _on_aura_entered(area):
	#print("Aura Entered: ", area)
	if !area.aura:
		return
	
	match area.aura.TargetTeam:
		Enums.TARGET_TEAM.ALLY:
			if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and FACTION_ID == Enums.FACTION_ID.NPC:
				pass
			elif area.master.FACTION_ID != FACTION_ID:
				return
		Enums.TARGET_TEAM.ENEMY:
			if area.master.FACTION_ID == FACTION_ID:
				return
	
	if area.aura.Target == Enums.EFFECT_TARGET.SELF:
		return
	elif !activeAuras.has(area):
		activeAuras[area] = area.aura.Effects.duplicate()
		
	update_stats()
	
	
	
	
func _on_aura_exited(area):
	#print("Aura Exited: ", area)
	if activeAuras.has(area):
		activeAuras.erase(area)
		#print("Active Aura Effects: ", activeAuras)
	update_stats()

func _on_self_aura_entered(area, ownArea):
	var effectData = UnitData.effectData
	#print("on_self_aura_entered: ", area.master)
	match ownArea.aura.TargetTeam:
		Enums.TARGET_TEAM.ALLY:
			if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and FACTION_ID == Enums.FACTION_ID.NPC:
				pass
			elif area.master.FACTION_ID != FACTION_ID:
				return
		Enums.TARGET_TEAM.ENEMY:
			if area.master.FACTION_ID == FACTION_ID:
				return
	
	if ownArea.aura.Target == Enums.EFFECT_TARGET.SELF:
		if !activeAuras.has(ownArea):
			activeAuras[ownArea] = ownArea.aura.Effects.duplicate()
		else: 
			for effId in ownArea.aura.Effects:
				if effectData[effId].Stack:
					activeAuras[ownArea].append(effId)
	
	
	update_stats()
	#print("Active Aura Effects: ", activeAuras)
		

func _on_self_aura_exited(area, ownArea):
	#print("on_self_aura_exited: ", area.master)
	if activeAuras.has(ownArea) and activeAuras[ownArea].size() > 0:
		activeAuras[ownArea].pop_back()
	if activeAuras.has(ownArea) and activeAuras[ownArea].size() <= 0:
		activeAuras.erase(ownArea)
	print("Active Aura Effects: ", activeAuras)
	update_stats()

##Equipment functions
func restore_equip():
	if tempSet:
		for item in unitData.Inv:
			if get_icat(item).Main != "ACC" and item.Equip:
				item.Equip = false
				
		tempSet.Equip = true
		tempSet = false
		update_stats()
		
func set_temp_equip(weapon):
	var tempWep
	var i = unitData.Inv.find(weapon)
	tempSet = get_equipped_weapon()
	if tempSet != natural and tempSet != unarmed:
		var indx = unitData.Inv.find(tempSet)
		unequip(indx)
	
	if i > -1:
		tempWep = unitData.Inv[i]
	elif unitData.Weapons.Sub and unitData.Weapons.Sub.has("NATURAL"):
		tempWep = natural
	if tempWep == natural:
		_equip_weapon(-2, true)
	elif check_valid_equip(tempWep) and get_icat(tempWep).Main != "ACC":
		#print(i)
		#print(unitData.Inv)
		_equip_weapon(i, true)
		
	update_stats()
	


func set_direct_equipped(item:Dictionary):
	var i : int = unitData.Inv.find(item)
	set_equipped(i)


	
func set_equipped(iInv = false): #searches for first valid if false or out of bounds, otherwise pass inv index and will equip if valid
	var valid = false
	var invItem
	if iInv and iInv < unitData.Inv.size() and iInv > -1:
		invItem = unitData.Inv[iInv]
		valid = check_valid_equip(invItem, 1)
	else: 
		var i = 0
		#print("sorting starting Inv....")
		for thing in unitData.Inv:
			#print("checking: ", str(thing))
			if check_valid_equip(thing, 1) and get_icat(thing).Main != "ACC":
				#print(str(thing), "Validated")
				valid = true
				iInv = i
				break
			i += 1
	if valid and invItem and get_icat(invItem).Main == "ACC":
		_equip_acc(iInv)
	elif valid:
		_equip_weapon(iInv)
	tempSet = false
	update_stats()
	
func get_equipped_weapon(): #returns the currently equipped weapon within inventory. use .ID to find global statistics. Returns generic "unarmed" if there is none.
	var found
	var wep
	for item in unitData.Inv:
		if item.Equip and check_valid_equip(item, 1):
			wep = item
			found = true
			break
	if !found and activeStats.Weapons.Sub and activeStats.Weapons.Sub.has("NATURAL"):
		wep = natural
		_equip_weapon(-2)
	elif !found:
		wep = unarmed
		_equip_weapon(-1)
	return wep
	
func get_equipped_acc(): #returns the currently equipped accessories within inventory. use .ID to find global statistics. Return false if none.
	var acc : Array = []
	for item in unitData.Inv:
		if item.Equip and check_valid_equip(item, 2):
			acc.append(item)
	if acc.size() == 0:
		return false
	return acc

func get_reach() -> Dictionary:
	var reach = {"Max":-INF, "Min":INF}
	var wep = get_weapon_reach()
	var aug = {"Max":-INF, "Min":INF}
	var skill = {"Max":-INF, "Min":INF}
	for s in unitData.Skills:
		if UnitData.skillData[s].Augment: 
			var r = get_aug_reach(s)
			aug.Min = min(aug.Min, r.Min, aug.Min)
			aug.Max = max(aug.Max, r.Max, aug.Max)
		elif UnitData.skillData[s].MaxRange > 0:
			var r = get_skill_reach(s)
			skill.Min = min(skill.Min, r.Min, skill.Min)
			skill.Max = max(skill.Max, r.Max, skill.Max)
	reach.Min = min(reach.Min, skill.Min, reach.Min)
	reach.Max = max(reach.Max, skill.Max, reach.Max)
	reach.Min = min(reach.Min, aug.Min, reach.Min)
	reach.Max = max(reach.Max, aug.Max, reach.Max)
	return reach


##Returns reach = {"Max":int, "Min":int} of given currently equipped weapon
func get_weapon_reach() -> Dictionary:
	var reach = {"Max":-INF, "Min":INF}
	var wepData :Dictionary = UnitData.itemData
	for wep in unitData.Inv:
			if !check_valid_equip(wep):
				continue
			reach.Min = min(reach.Min, wepData[wep.ID].MinRange, reach.Min)
			reach.Max = max(reach.Max, wepData[wep.ID].MaxRange, reach.Max)
	var id = get_equipped_weapon().ID
	reach.Min = min(reach.Min, wepData[id].MinRange, reach.Min)
	reach.Max = max(reach.Max, wepData[id].MaxRange, reach.Max)
	return reach


##Returns reach = {"Max":int, "Min":int} of given skillId
func get_skill_reach(skillId : String) -> Dictionary:
	var reach = {"Max":-INF, "Min":INF}
	var skill = UnitData.skillData[skillId]
	reach.Min = skill.MinRange
	reach.Max = skill.MaxRange
	
	#Insert passive check for skill range bonuses here
	return reach


##Returns reach = {"Max":int, "Min":int} of given augment type skillId
func get_aug_reach(skillId : String) -> Dictionary:
	var reach = {"Max":-INF, "Min":INF}
	var skill = UnitData.skillData[skillId]
	var wepData :Dictionary = UnitData.itemData
	
	for wep in unitData.Inv:
			if wep.Dur == 0:
				continue
	
	if skill.MinRange == 0 or skill.MaxRange == 0:
		for wep in unitData.Inv:
			if wep.Dur == 0:
				continue
			reach.Min = min(reach.Min, wepData[wep.ID].MinRange, reach.Min)
			reach.Max = max(reach.Max, wepData[wep.ID].MaxRange, reach.Max)
	else:
		reach.Min = skill.MinRange
		reach.Max = skill.MaxRange
	
	reach.Min += skill.BonusMinRange
	reach.Max += skill.BonusMaxRange

	return reach


func has_valid_aug_weapon(skillId : String) -> bool:
	var isValid := false
	var skill :Dictionary = UnitData.skillData[skillId]
	var iData : Dictionary = UnitData.itemData
	var wepCats = Enums.WEAPON_CATEGORY.keys()
	
	for i in unitData.Inv:
		var item = iData[i.ID]
		var hasReach := false
		var hasType := false
		
		if skill.MaxRange == 0 and skill.MinRange == 0: hasReach = true
		elif item.MinRange <= skill.MinRange or item.MaxRange >= skill.MaxRange: hasReach = true
		
		if skill.WepCat == Enums.WEAPON_CATEGORY.ANY or item.Category.to_upper() == wepCats[skill.WepCat] or item.SubGroup.to_upper() ==  wepCats[skill.WepCat]: 
			hasType = true
		
		if hasReach and hasType:
			isValid = true
			break
	
	return isValid

func unequip(slot = 0): #Stop taking drugs. Fix this up later, it makes no fucking sense. HERE
	var item = unitData.Inv[slot]
	var noweapon = false
	
	match slot:
		-2: 
			natural.Equip = false
			_remove_equip_effects(natural)
		-1: 
			natural.Equip = false
			_remove_equip_effects(noweapon)
		_:
			while !item.Equip:
				slot += 1
				if slot >= unitData.Inv.size():
					return
				item = unitData.Inv[slot]
			_remove_equip_effects(item)
			item.Equip = false
			
			noweapon = true
			for i in unitData.Inv:
				if i.Equip: 
					noweapon = false
					break
			
	if noweapon and unitData.Weapons.Sub and unitData.Weapons.Sub.has("NATURAL"):
		_equip_weapon(-2)
	elif noweapon:
		_equip_weapon(-1)


func _equip_acc(i : int):
	var acc = unitData.Inv[i]
	var limit : int = 2
	var c : int = 0
	var first : int
	for item in unitData.Inv:
		var type : String = get_icat(acc).Main
		if type == "ACC" and acc.Equip and !first:
			c += 1
			first = unitData.Inv.find(item)
		elif type == "ACC" and acc.Equip:
			c += 1
	if c >= limit:
		unequip(first)
	acc.Equip = true
	_add_equip_effects(acc)


func _equip_weapon(index, isTemp = false) -> void:
	var wep
	
	for item in unitData.Inv:
		var type : String = get_icat(item).Main
		if type != "ACC" and item.Equip:
			var i = unitData.Inv.find(item)
			unequip(i)
	
	match index:
		-2: 
			wep = natural
			
		-1: 
			wep = unarmed
			
		_: 
			if unitData.Inv[index].Equip == true:
				return
			elif isTemp:
				#unitData.Inv[index].Equip = true
				wep = unitData.Inv[index]
			else:
				#unitData.Inv[index].Equip = true
				wep = unitData.Inv.pop_at(index)
				unitData.Inv.push_front(wep)
	if wep.ID != "NONE": 
		wep.Equip = true
		_add_equip_effects(wep)
	#print(wep)


func _add_equip_effects(item):
	var iData = UnitData.itemData[item.ID]
	var effData = UnitData.effectData
	
	if iData.Effects and iData.Effects.size() > 0:
		for effId in iData.Effects:
			if effData[effId].Target == Enums.EFFECT_TARGET.EQUIPPED:
				_add_effect(effId)
	#print(activeEffects)


func _remove_equip_effects(item):
	var iData = UnitData.itemData[item.ID]
	if iData.has("Effects"):
		for effect in iData.Effects:
			var i = activeEffects.find(effect)
			activeEffects.remove_at(i)
	#print(activeEffects)
	
	
func _add_effect(effId):
	activeEffects.append(effId)
		
		
func _remove_effect(effId):
	var i = activeEffects.find(effId)
	activeEffects.remove_at(i)
	
	
func check_valid_equip(item : Dictionary, mode : int = 0): #Subweapons not fully implemented, Sub returns true regardless of which sub it is. There is no differentiation yet. 0 = Any, 1 = Weapon; 2 = Accessory
	var iCat = get_icat(item) 
	if item.Dur == 0:
		return false
	if mode < 2 and iCat.Sub and activeStats.Weapons.has(iCat.Sub):
		return true
	elif mode < 2 and activeStats.Weapons.has(iCat.Main):
		return true
	elif mode == 0 and iCat.Main == "ACC":
		return true
	elif mode == 2 and iCat.Main == "ACC":
		return true
	elif mode == 0 and iCat.Main == "ITEM":
		return true
	else:
		return false
		
	
func get_icat(item) -> Dictionary:
	var iCat = {"Main" : UnitData.itemData[item.ID].Category, "Sub" : false}
	if UnitData.itemData[item.ID].SubGroup:
		iCat.Sub = UnitData.itemData[item.ID].SubGroup
	return iCat


func use_item(item):
	var data = UnitData.itemData[item.ID]
	if data.MinRange > 0 or data.MaxRange > 0:
		emit_signal("item_targeting", item, self)
	else: activate_item(item, self)


func activate_item(item, target):
	emit_signal("item_activated", item, self, target)
	reduce_durability(item)
	

func reduce_durability(item : Dictionary, reduc : int = 1): ##Weapon only considered broken at 0 durability!!! -1 is unbreakable! If reduc value would put an item below 0, it is clamped to 0 and will break.
	var inv = unitData.Inv
	var i = inv.find(item)
	var maxDur = UnitData.itemData[item.ID].MaxDur
	print("Durability reduction for: ", item)
	if item.Dur == -1:
		print("Weapon is unbreakable")
		return
	item.Dur -= reduc
	clampi(item.Dur, 0, maxDur)
	print("Durability reduced to: ", item.Dur)
	if item.Dur == 0 and item.Equip:
		print("Item Broken, unequipping")
		unequip(i)
	if item.Dur == 0 and UnitData.itemData[item.ID].Expendable:
		print("Queued item Deletion")
		call_deferred("delete_item", item)
		#delete_item(item)


func delete_item(item):
	var inv = unitData.Inv
	var eqp = get_equipped_weapon()
	var i = inv.find(item)
	if eqp == item:
		unequip(i)
	inv.remove_at(i)

func _update_natural(passive):
	if passive.SubType != Enums.WEAPON_CATEGORY.NATURAL:
		return
	var base : Dictionary = UnitData.itemData[passive.String].duplicate()
	var scaleType = passive.String
	var final : Dictionary = base
	var dmgScale := 0
	var hitScale := 0
	var grazeScale := 0
	var tier : int = unitData.Profile.Level
	
	match scaleType:
		"NaturalMartial": 
			dmgScale = 2 + ceili(unitData.Profile.Level/4)
			hitScale = 65 + ceili(unitData.Profile.Level)
			grazeScale = 2 + ceili(unitData.Profile.Level/6)
	
	match tier:
		40: tier = 6
		tier when tier > 35: tier = 5
		tier when tier > 25: tier = 4
		tier when tier > 15: tier = 3
		tier when tier > 5: tier = 2
		_: tier = 1
	
	final.Dmg = base.Dmg + dmgScale
	final.Hit = base.Hit + hitScale
	final.Barrier = base.Barrier + grazeScale
	final.Name = scaleType + str(tier)
	UnitData.itemData[unitName] = final
	natural.ID = unitName
	
##Effect Functions
func get_effects(key, value, falseRule = false):
	var effData = UnitData.effectData
	var matched := []
	for effId in activeEffects:
		if !falseRule and effData[effId].has(key) and effData[effId][key] == value:
			matched.append(effId)
		elif effData[effId].has(key) and effData[effId][key] != value:
			matched.append(effId)
	if matched.size() <= 0:
		return false
	return matched


func get_multi_swing():
	var swings : int = 0
	for effId in activeEffects:
		if UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.MULTI_SWING and UnitData.effectData[effId].Value > swings:
			swings = UnitData.effectData[effId].Value
	if swings == 0:
		return false
	else:
		return swings


func get_multi_round():
	var rounds : int = 0
	for effId in activeEffects:
		if UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.MULTI_ROUND and UnitData.effectData[effId].Value > rounds:
			rounds = UnitData.effectData[effId].Value
	if rounds == 0:
		return false
	else:
		return rounds


func get_crit_dmg_effects():
	var data = UnitData.effectData
	var effects : Dictionary = {"CritDmg": false, "CritMulti": false}
	var highest := 0
	var dmgStack := [0, 0]
	
	for id in activeEffects:
		if data[id].Type == Enums.EFFECT_TYPE.CRIT_BUFF and data[id]["CritDmg"]:
			dmgStack[0] += data[id]["CritDmg"][0]
			dmgStack[1] += data[id]["CritDmg"][1]
			effects.CritDmg = dmgStack
		if data[id].Type == Enums.EFFECT_TYPE.CRIT_BUFF and data[id]["CritMulti"] and data[id]["CritMulti"] > highest:
			highest = data[id]["CritMulti"]
			effects.CritMulti = highest
			
	return effects


func update_combatdata():
	#no catch for empty inv!!!!! HERE Wait, isn't there one? setting it to Null, and then having null translate to "NONE" when all null instances could just be "NONE" is retarded. Fix this, you god damned retard.
	var tBonus = update_terrain_bonus()
	var wep = UnitData.itemData[get_equipped_weapon().ID]
	
	combatData.Type = wep.Type
	if wep.Type == Enums.DAMAGE_TYPE.PHYS:
		combatData.Dmg = wep.Dmg + activeStats.Pwr + tBonus.PwrBonus
	elif wep.Type == Enums.DAMAGE_TYPE.MAG:
		combatData.Dmg = wep.Dmg + activeStats.Mag + tBonus.MagBonus
	elif wep.Type == Enums.DAMAGE_TYPE.TRUE:
		combatData.Dmg = wep.Dmg
	combatData.Hit = activeStats.Eleg * 2 + (wep.Hit + activeStats.Cha + tBonus.HitBonus)
	combatData.Graze = activeStats.Cele * 2 + activeStats.Cha + tBonus.GrzBonus
	combatData.Barrier = wep.Barrier
	combatData.BarPrc = activeStats.Eleg + activeStats.Def + tBonus.DefBonus
	combatData.Crit = activeStats.Eleg + wep.Crit
	combatData.Luck = activeStats.Cha
	combatData.CompRes = (activeStats.Cha / 2) + (activeStats.Eleg / 2)
	combatData.CompRes = clampi(combatData.CompRes, -200, 75)
	combatData.CompBonus = activeStats.Cha / 4
	combatData.MagBase = activeStats.Mag
	combatData.PwrBase = activeStats.Pwr
	combatData.HitBase = activeStats.Eleg * 2 + activeStats.Cha
	combatData.CritBase = activeStats.Eleg
	combatData.Resist = activeStats.Cha * 2
	combatData.EffHit = activeStats.Cha
	combatData.DRes = {Enums.DAMAGE_TYPE.PHYS: activeStats.Def, Enums.DAMAGE_TYPE.MAG: activeStats.Mag, Enums.DAMAGE_TYPE.TRUE: 0}
	combatData.CanMiss = true
	if status.Sleep:
		combatData.Graze = 0
		combatData.BarPrc = 0
	baseCombat = combatData.duplicate()
	
func get_skill_combat_stats(skillId, augmented := false):
	var skill = UnitData.skillData[skillId]
	var stats = combatData.duplicate()
	var dmgStat := 0
	var attack
	var typeLord
	if augmented: 
		attack = UnitData.itemData[get_equipped_weapon().ID]
	else: attack = skill
	
	if augmented and skill.Type: typeLord = skill.type
	else: typeLord = attack.Type
	
	match typeLord:
		Enums.DAMAGE_TYPE.PHYS: dmgStat = stats.PwrBase
		Enums.DAMAGE_TYPE.MAG: dmgStat = stats.MagBase
		Enums.DAMAGE_TYPE.TRUE: dmgStat = 0
		
	if !skill.CanDmg:
		stats.Dmg = false
	elif augmented:
		stats.Dmg = dmgStat + attack.Dmg + skill.Dmg
	else:
		stats.Dmg = dmgStat + attack.Dmg

	stats.CanMiss = skill.CanMiss
	
	if augmented:
		stats.Hit = stats.HitBase + attack.Hit + skill.Hit
	else:
		stats.Hit = stats.HitBase + attack.Hit
	
	if !skill.Crit and skill.Crit != 0:
		stats.Crit = false
	elif augmented: 
		stats.Crit = stats.CritBase + attack.Crit + skill.Crit
	else: 
		stats.Crit = stats.CritBase + attack.Crit
	
		
	return stats


func update_stats(): #GO BACK AND FINISH ACTIVE DEBUFFS AFTER THIS
	var effSort := []
	var time := Global.timeOfDay
	var timeMod : Dictionary = UnitData.timeModData[unitData.Profile.Species][time]
	var statKeys := baseStats.keys()
	var buffTotal := {}
	var baseUpdated := false
	var combatUpdated := false
	var modifiedStats := activeStats
	var baseValues := baseStats
	var subKeys := Enums.SUB_TYPE.keys()
	
	check_passives()
	validate_active_effect_skills()
	
	if baseStats == null or activeStats == null or lifeBar == null:
		return
	lifeBar.max_value = baseStats.Life
	#lifeBar.value = activeStats.CurLife
	#if activeStats["CurLife"] <= 0:
		#run_death()
		#return
	#if activeStats.CurComp <= 0:
		#pass #comp check!
	#######
	
	while !combatUpdated:
		buffTotal.clear()
		if baseUpdated:
			statKeys = combatData.keys()
			modifiedStats = combatData 
			#This updates activeStats, and leaves base stats alone.
			#It does not do the same for combatData, it directly buffs it with no seperation.
			baseValues = combatData
			
		for stat in statKeys:
			stat = stat.to_pascal_case()
			buffTotal[stat] = 0
			if timeMod.has(stat) and check_time_prot():
				buffTotal[stat] += clampi(timeMod[stat], 0, 999999)
			elif timeMod.has(stat):
				buffTotal[stat] += timeMod[stat]
		
		for aura in activeAuras:
			for effect in activeAuras[aura]:
				var mod = UnitData.effectData[effect]
				var stat = subKeys[mod.SubType].to_pascal_case()
				if buffTotal.has(stat): buffTotal[stat] += mod.Value
		
		for buff in activeBuffs:
			var stat = subKeys[activeBuffs[buff].SubType].to_pascal_case()
			if buffTotal.has(stat): buffTotal[stat] += activeBuffs[buff].Value
			
		for debuff in activeDebuffs:
			var stat = debuff.SubType.to_pascal_case()
			if buffTotal.has(stat): buffTotal[stat] += debuff.Value
			
		for effId in activeEffects:
			if UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.BUFF or UnitData.effectData[effId].Type == Enums.EFFECT_TYPE.DEBUFF:
				effSort.append(effId)
					
		for effId in effSort:
			var stat = subKeys[UnitData.effectData[effId].SubType].to_pascal_case()
			if UnitData.effectData[effId].Target == Enums.EFFECT_TARGET.EQUIPPED:
				if buffTotal.has(stat): buffTotal[stat] += UnitData.effectData[effId].Value
		
		for stat in statKeys:
			if !buffTotal.has(stat):
				continue
			match stat:
				"DRes": 
					modifiedStats["DRes"][Enums.DAMAGE_TYPE.PHYS] += buffTotal[stat]
					modifiedStats["DRes"][Enums.DAMAGE_TYPE.MAG] += buffTotal[stat]
				"PhysDef": modifiedStats["DRes"][Enums.DAMAGE_TYPE.PHYS] += buffTotal[stat]
				"MagDef": modifiedStats["DRes"][Enums.DAMAGE_TYPE.MAG] += buffTotal[stat]
				"CanMiss": continue
				_: modifiedStats[stat] = baseValues[stat] + buffTotal[stat]
		
		
		if timeMod.MoveType: #HERE need sprite swap for fly/foot movement changes
			modifiedStats["MoveType"] = timeMod.MoveType
			
		if !baseUpdated:
			update_combatdata()
			baseUpdated = true
		else:
			combatUpdated = true
		
	update_sprite()
	
	if status.Sleep:
		activeStats.Move = 0

func on_sequence_concluded():
	#check post-sequence event que?
	update_life_bar()
	check_death()
	#finally allow turn completion?

func danmaku_collision():
	update_life_bar()
	check_death()

func confirm_post_sequence_flags(flag):
	postSequenceFlags[flag] = true
	for f in postSequenceFlags:
		if !postSequenceFlags[f]:
			return
	_turn_complete()


func _turn_complete():
	postSequenceFlags.Bars = false
	postSequenceFlags.Death = false
	emit_signal("turn_complete", self)


func update_sprite():
	for condition in status:
		if status[condition]:
			if condition == "Sleep" or condition == "Acted":
				_animPlayer.play("disabled")
				#print(unitId,":", _animPlayer.current_animation,"Update Sprite")
				return
	if !isWalking and !isShoved and !needDeath:
		_animPlayer.play("idle")
		#print(unitId,":", _animPlayer.current_animation,"Update Sprite")
		
		
func check_death():
	if activeStats["CurLife"] <= 0:
		run_death()
	else:
		confirm_post_sequence_flags("Death")

func update_life_bar():
	var tween = get_tree().create_tween()
	if isHurt:
		play_animation("Hit")
		isHurt = false
	tween.finished.connect(self._life_tween_finished)
	tween.tween_property($PathFollow2D/Sprite/HPbar, "value", activeStats.CurLife, 0.5)
	

func _life_tween_finished():
	revert_animation()
	confirm_post_sequence_flags("Bars")


func update_composure_bar():
	if activeStats.CurComp <= 0:
		pass #comp check!



func apply_dmg(dmg : int, source : Unit):
	activeStats.CurLife -= dmg
	activeStats.CurLife = clampi(activeStats.CurLife, 0, activeStats.Life)
	if activeStats.CurLife == 0:
		killer = source
		deathFlag = true
	
	if dmg > 0 and status.Sleep:
		cure_status("Sleep")
	if dmg > 0:
		isHurt = true
	#return activeStats.CurLife
	
func apply_heal(heal := 0):
	activeStats.CurLife += heal
	activeStats.CurLife = clampi(activeStats.CurLife, 0, activeStats.Life)
	
func apply_composure(comp := 0):
	activeStats.CurComp -= comp
	activeStats.CurComp = clampi(activeStats.CurComp, 0, activeStats.Comp)


func has_enough_comp(skillId) -> bool:
	var isValid := false
	var cost = UnitData.skillData[skillId].Cost
	if cost <= activeStats.CurComp: isValid = true
	return isValid


func cure_status(cureType, ignoreCurable = false): #Unnest this someday? I dunno, eat shit.
	var statusKeys : Array = Enums.SUB_TYPE.keys()
	var s : String = statusKeys[cureType].to_pascal_case()
	if s == "All":
		for condition in status:
			if status[condition] and sParam.has(condition) and sParam[condition].Curable and condition != "Acted":
				status[condition] = false
				sParam.erase(condition)
				_clear_status_fx(condition)
	elif status[s] and sParam.has(s) and !ignoreCurable and sParam.Curable:
		status[s] = false
		sParam.erase(s)
		_clear_status_fx(s)
	elif status[s] and sParam.has(s) and ignoreCurable:
		status[s] = false
		sParam.erase(s)
		_clear_status_fx(s)
	else:
		print("No status cured")
	update_stats()
	#$PathFollow2D/Cell2.set_text(str(status))
	
func _clear_status_fx(condition):
	var sprite = $PathFollow2D/Sprite
	var kids = sprite.get_children()
	for kid in kids:
		if kid is AnimatedSprite2D and kid.get_animation() == condition.to_pascal_case():
			kid.queue_free()
	
func set_status(effect): #Missing a check for "duration type", same goes for ticking the duration
	#I wish I could inflict sleep status on myself
	var fxPath = "res://scenes/animations/status_effects/animated_sprite_%s.tscn"
	var sprite = $PathFollow2D/Sprite
	var hp = $PathFollow2D/Sprite/HPbar
	if !effect:
		print("No condition found")
		return
	var statusKeys : Array = Enums.SUB_TYPE.keys()
	var s : String = statusKeys[effect.SubType].to_pascal_case()
	status[s] = true
	if sParam.has(s) and !sParam[s].Curable:
		sParam[s].Duration = effect.Duration
	else:
		sParam[s] = {"Duration":effect.Duration, "Curable":effect.Curable}
	fxPath = fxPath % [s.to_snake_case()]
	var fxAnimation = load(fxPath).instantiate()
	if fxAnimation:
		fxAnimation.play(s)
		sprite.add_child(fxAnimation)
		fxAnimation.call_deferred("move_before",hp)
	update_stats()


func check_status(condition:String):
	if status[condition]:
		return true
	else:
		return false

func set_acted(actState: bool):
	status.Acted = actState
	match status.Acted:
		false:
			_animPlayer.play("idle")
			#print(unitId,":", _animPlayer.current_animation,"Set Acted")
		true: 
			if one_time_leash and leash > -1: leash = -1
			_animPlayer.play("disabled")
			#print(unitId,":", _animPlayer.current_animation,"Set Acted")

func initialize_cell():
	var coord = $PathFollow2D/Cell
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)
	originCell = cell
	coord.set_text(str(cell))

#Turn Signals
func on_turn_changed():
	update_stats()
	
	
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
	$PathFollow2D/Sprite/HPbar.visible = false
	confirm_post_sequence_flags("Death")
	emit_signal("death_done", self)
	
	
func update_terrain_data():
	terrainTags = get_parent().get_terrain_tags(cell)
	
	
func update_terrain_bonus() -> Dictionary:
#	print(combatData.Graze)
	
	var tVal := {"GrzBonus": 0, "DefBonus": 0, "PwrBonus": 0, "MagBonus": 0, "HitBonus": 0,}
	var terrainData = UnitData.terrainData
	if !isActive or activeStats.MoveType == Enums.MOVE_TYPE.FLY: return tVal
	
	if terrainTags.BaseType:
		for bonus in tVal:
			tVal[bonus] += terrainData[terrainTags.BaseType][bonus]
			
	if terrainTags.ModType:
		for bonus in tVal:
			tVal[bonus] += terrainData[terrainTags.ModType][bonus]
	
	return tVal
	#if deployed:
		#var i = find_nested(terrainData, Vector2i(cell))
		#if i != -1:
			#bonus = terrainData[i][2]
		#return bonus
	#else:
		#return 0

	
func find_nested(array, value):
#	print(value)
	if array == null:
		return -1
	for i in range(array.size()):
#		print(array[i])
		if array[i].find(value) != -1:
			return i
	return -1
	
func _on_animation_player_animation_finished(_animName):
	pass
	#HERE for what?!!!
	
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
	
