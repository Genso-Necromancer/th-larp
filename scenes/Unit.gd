@tool
class_name Unit
extends Path2D
signal walk_finished
signal exp_handled
signal imdead
signal deathDone

#Unit Parameters
@export_enum("Enemy", "Player", "NPC") var faction: String = "Enemy"
@export_enum("Fairy", "Human", "Kappa", "Lunarian", "Oni", "Doll", "Devil", "Yukionna", "Zombie", "Hermit", "Magician", "Spirit") var species: String
@export_enum("Trblr", "Thief") var job: String 
@export var weapon : String = "Skip"
@export var weapon2: String = "Skip"
@export var weapon3: String = "Skip"
@export var weapon4: String = "Skip"
#Profile
@export var unitName = "Name"
@export var move_speed := 150.0
@export var genLevel : int
var unitData
var allUnitData
var groupKeys = UnitData.groups
var statKeys = UnitData.stats
var ykTag
var acted = false
var moveType = "Foot"
var baseMove
var needDeath = false


#Call for pre-formualted combat stats
var combatData = {"DMG": 0, "HIT": 0, "AVOID": 0, "GRAZE": 0, "GRZPRC": 0, "CRIT": 0, "CRTAVD": 0, "TYPE":"Physical"}
#base stats of the unit
var baseStats = {}
#combination of base stats and buffs
var activeStats = {}
#de/buffs applied to unit
var activeBuffs = {}
#var skin = UnitData.playerUnits[unitName]["Sprite"]:
#	set(value):
#		skin = value
#		if not _sprite:
#			await ready
#		_sprite.texture = value

@export var skin_offset := Vector2.ZERO:
	set(value):
		
		skin_offset = value
		if not _sprite:
			await ready
		_sprite.position = value
## Coordinates of the current cell the cursor moved to.
var cell := Vector2.ZERO:
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
		set_process(_is_walking)
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



#Stats
var currHp = 0



func _ready() -> void:
#	print(statVars)
#	#print("unit.gd:", unitId)
	load_stats()
	load_sprites()
	if !map.mapReady.is_connected(self._on_test_map_map_ready):
		map.mapReady.connect(self._on_test_map_map_ready)
	_path_follow.rotates = false
	_anim_player.play("idle")
	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
		
	

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
	var location = cell
	$PathFollow2D/Label.set_text(str(location))
	
	if _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = map.map_to_local(cell)
		curve.clear_points()
		_anim_player.play("idle")
		emit_signal("walk_finished")
		
		

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
	
func load_stats():
	allUnitData = UnitData
	if faction == "Player":
		add_to_group("Player")
		unitData = UnitData.unitData[unitName.get_slice(" ", 0)].duplicate(true)
		baseStats = unitData.Stats.duplicate(true)
		unitName = unitData["Profile"]["UnitName"]
		baseMove = baseStats["MOVE"]
		check_passives()
		activeStats["CLIFE"] = baseStats["LIFE"]
		init_wep(true)
	if faction == "Enemy":
		add_to_group("Enemy")
		var unique = false
		var baseTag = "youkai"
		var counter = 0
		if species == null or job == null or weapon == null:
			print("No Job, Weapon or Species.")
			pass
		else:
			var weapons = [weapon4, weapon3, weapon2, weapon]
			while !unique:
				ykTag = baseTag + str(counter)
				if UnitData.unitData.has(ykTag):
					counter += 1
				elif !UnitData.unitData.has(ykTag):
					unique = true
					UnitData.stat_gen(ykTag, genLevel, species, job)
			unitData = UnitData.unitData[ykTag].duplicate(true)
			baseStats = unitData.Stats.duplicate(true)
			activeStats["CLIFE"] = baseStats["LIFE"]
			unitData["StartInv"] = []
			for wep in weapons:
				if wep == null or wep == "Skip" or wep == "":
					continue
				else:
					unitData["StartInv"].append(wep)
		init_wep(false)
	active_and_buff_set_up()
	update_stats()
	update_combatdata()
#	var groups = get_groups()
#	print(unitName, " ", groups)

func active_and_buff_set_up():
	var keys = baseStats.keys()
	for stat in keys:
		activeStats[stat] = baseStats[stat]
		activeBuffs[stat] = {}
		activeBuffs[stat]["Mod"] = 0
		activeBuffs[stat]["Duration"] = 0
		activeBuffs[stat]["Fresh"] = false
		activeBuffs[stat]["Source"] = ""
		
#keep track of active de/buffs during gameplay, seperate from actual stats
func apply_buff(stat, buff, duration, selfCast = false, source = ""):
	activeBuffs[stat].Mod = buff
	activeBuffs[stat].Duration = duration
	activeBuffs[stat].Fresh = selfCast
	activeBuffs[stat].Source = source
	
#tracks duration of effects, then removes them when reaching 0
func status_duration_tick():
	var keys = activeBuffs.keys()
	for stat in keys:
		if activeBuffs[stat].Fresh:
			activeBuffs[stat].Fresh = false
			continue
		if activeBuffs[stat].Duration > 0:
			activeBuffs[stat].Duration -= 1
		if activeBuffs[stat].Duration == 0:
			activeBuffs[stat].Mod = 0
			activeBuffs[stat].Source = ""
#	print(activeBuffs)
	update_stats()
	
func load_sprites():
	
	if faction == "Player":
		_sprite.texture = unitData["Profile"]["Sprite"]
		_sprite.self_modulate = Color(1,1,1)
	if faction == "Enemy":
		_sprite.self_modulate = Color(1,0,0)
		
func init_wep(isPlayer):
	if unitData.StartInv.size() == 0:
		return
	var equipped = false
	var uniqueID
	for wep in unitData.StartInv:
		uniqueID = UnitData.add_inv(wep, isPlayer, true)
		unitData.Inv.append(uniqueID)
		if !equipped:
			unitData.EQUIP = uniqueID
			equipped == true
#	print(unitData.EQUIP)
#	print(unitData.Inv)
#	if isPlayer:
#		print(UnitData.plrInv[uniqueID])
#		print(UnitData.plrInv)
#	else:
#		print(UnitData.npcInv[uniqueID])
#		print(UnitData.npcInv)
#func stat_gen():
#	pass

#func update_stats(newStats):
#	level = newStats[0]
#	var hpBump = newStats[1] - maxHp
#	maxHp = newStats[1]
#	currHp += hpBump
#	moveRange = moveRange
#	uStr = newStats[2]
#	mag = newStats[3]

#func _on_main_exp_test():
#	var action = "defeat"
#	var targLvl = 2
#	var storage
#	storage = Leveling.get_experience(action, currExp, targLvl, stats, growths, caps)
#	currExp = storage[0]
#	stats = storage[1]
#	update_stats(stats)
#	emit_signal("exp_handled")

func check_passives():
	#ATTENTION
	#Terrible, garbage, what the fuck. Cheap imitation of how it should be.
	#will remake this
	var passives = unitData["Passive"]
#	if passives.has("Fly"):
#		moveType = "Fly"
#		unitData.Stats.MOVE = baseMove+1
#	if passives.has("SunWeak") and Global.day == true:
#		moveType = "Foot"
#		unitData.Stats.Move = baseMove
		
			
		

func set_equipped(weapon):
	unitData.EQUIP = weapon
	
func update_combatdata(terrainBonus: int = 0):
	var equipped = unitData.EQUIP
	var wep 
	var stat = activeStats
	if faction == "Player":
		wep = allUnitData.plrInv[equipped]
	else:
		wep = allUnitData.npcInv[equipped]
	
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
	#ATTENTION
	#Combat currently adjusts the stored base stats, not the unit's stats. 
	#Need to change it so unit alters it's stats itself.
	lifeBar.max_value = activeStats.LIFE
	lifeBar.value = activeStats.CLIFE
	if activeStats["CLIFE"] == 0:
		run_death()
	#######
		
	var keys = baseStats.keys()
	for stat in keys:
		activeStats[stat] = baseStats[stat] + activeBuffs[stat].Mod

func apply_dmg(dmg = 0):
	activeStats.CLIFE = activeStats.CLIFE - dmg
	activeStats.CLIFE = clampi(activeStats.CLIFE, 0, 1000)
	return activeStats.CLIFE
	
func _on_test_map_map_ready():
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)
	originCell = cell


#func on_combat_resolved():
#	update_stats()
	
func on_turn_changed():
	check_passives()
	
	

func run_death():
	if faction != "Player":
		unitData.erase(ykTag)
	emit_signal("imdead", self)
	fade_out(1.0)
	
		
func fade_out(duration: float):
	needDeath = true
	_anim_player.play("death")
	await get_tree().create_timer(duration).timeout
	$PathFollow2D/HPbar.visible = false
	emit_signal("deathDone")
	
	

func set_acted(actState: bool):
	acted = actState
	match acted:
		false: _anim_player.play("idle")
		true: 
			_anim_player.play("disabled")
			status_duration_tick()
	
	
func update_terrain_bonus(terrainData):
#	print(combatData.AVOID)
	var bonus = 0
	var i = find_nested(terrainData, Vector2i(cell))
	if i != -1:
		bonus = terrainData[i][2]
	if bonus != 0:
		update_combatdata(bonus)
#		print(unitName)
#		print(combatData.AVOID)
	
func find_nested(array, value):
#	print(value)
#	print(value)
	for i in range(array.size()):
#		print(array[i])
		if array[i].find(value) != -1:
			return i
	return -1


func _on_animation_player_animation_finished(anim_name):
#	if anim_name == "death":
#		var oka
	pass
	
