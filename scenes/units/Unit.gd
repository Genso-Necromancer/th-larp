@tool
class_name Unit
extends Path2D
signal walk_finished
signal exp_handled
signal death_done(unit:Unit)
signal unit_relocated
signal exp_gained
signal leveled_up
signal post_complete
signal turn_complete(unit)
signal effect_complete
signal unit_ready(unit:Unit)
signal item_targeting(item, unit)
signal item_activated(item, unit, target)
signal animation_complete(unit:Unit)
signal bars_updated(unit:Unit)




#region export variables
var defaultId := ""
enum AI_TYPE {
	NONE,
	DEFENDER,
	OFFENDER,
	SUPPORT,
	BOSS
}
##Unit Parameters
@export var unit_id := "" ## Only change if unique unit
@export var disabled := false:
	get:
		return disabled
	set(value):
		disabled = value
		set_process(!value)
@export var recruited:= false
var unit_name := "" #Presented strings will eventually be taken from a seperate file
@export var FACTION_ID :Enums.FACTION_ID = Enums.FACTION_ID.ENEMY:
	set(value):
		FACTION_ID = value
		_set_faction_group(value)
@export_group("Spawn Parameters")
#@export var isForced := false
@export var is_active := true
@export_group("AI Paramters")
@export var isBoss : bool = false
@export var isMidBoss : bool = false
@export var archetype :AI_TYPE = AI_TYPE.NONE
@export var leash : int = -1 ##Number of spaces a target must be for the them move and attack. -1 turns this off.
@export var one_time_leash:bool = false ##True: After a unit is moved, their leash value will be set to -1 False: Unit never loses it's leash value
@export_group("Animation Values")
@export var moveSpeed := 200.0
@export var shoveSpeed := 350.0
@export var tossSpeed := 350.0
@export_category("Unit Parameters")
#@export_group("Class-Species-Level")
##False: loads generic sprite/portrait art based on spec_id + role_id[br]
##True: Loads art assets based on unit_id
@export var unique_art: bool = false
##False: Unit will use it's literal stats as presented under "Stat Totals", regardless of Level[br]
##True: Unit will treat it's given stats as if it was level 1, and level it's self based on growth rates up to it's given Level
@export var simulate_leveling : bool = true
##Level of unit at run time. Will simulate leveling to this value if simulate_leveling == true.
@export var unit_level : int = 1
@export var SPEC_ID :Enums.SPEC_ID= Enums.SPEC_ID.NONE:
	set(value):
		SPEC_ID = value
		_generate_base_stats()
			
@export var ROLE_ID :Enums.ROLE_ID= Enums.ROLE_ID.NONE:
	set(value):
		ROLE_ID = value
		_generate_base_stats()

@export var move_type:Enums.MOVE_TYPE
@export_category("Unit Stats")
@export_group("Stat Modifiers") 
##added to combined base stats from SPEC_ID and ROLE_ID
@export var mod_growth:Dictionary[StringName,float] = { 
					"Move": 0.0, 
					"Life": 0.0,
					"Comp": 0.0,
					"Pwr": 0.0, 
					"Mag": 0.0,
					"Eleg": 0.0,
					"Cele": 0.0,
					"Def": 0.0,
					"Cha": 0.0,
					}:
						set(value):
							mod_growth = value
							if not Engine.is_editor_hint():
								_update_totals()
##added to combined base stats from SPEC_ID and ROLE_ID
@export var mod_stats:Dictionary[StringName,int] = { 
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}:
						set(value):
							mod_stats = value
							if not Engine.is_editor_hint():
								_update_totals()
##added to combined base stats from SPEC_ID and ROLE_ID
@export var mod_caps:Dictionary[StringName,int] = { 
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}:
						set(value):
							mod_caps = value
							if not Engine.is_editor_hint():
								_update_totals()

@export_group("Stat Totals")
@export var total_growth:Dictionary[StringName,float] = { 
					"Move": 0.0,
					"Life": 0.0,
					"Comp": 0.0,
					"Pwr": 0.0, 
					"Mag": 0.0,
					"Eleg": 0.0,
					"Cele": 0.0,
					"Def": 0.0,
					"Cha": 0.0,
					}
@export var total_stats:Dictionary[StringName,int] = { 
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}
@export var total_caps:Dictionary[StringName,int] = { 
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}
var base_growth:Dictionary = { 
					"Move": 0.0,
					"Life": 0.0,
					"Comp": 0.0,
					"Pwr": 0.0, 
					"Mag": 0.0,
					"Eleg": 0.0,
					"Cele": 0.0,
					"Def": 0.0,
					"Cha": 0.0,
					}
var base_stats:Dictionary = { 
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}
var base_caps: = { 
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}
var level_stats:Dictionary = {
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}
var unit_exp:int = 0


@export_category("Features")
##Skills added to this array are treated as a unit's personal skills, they stick with a unit regardless of Species or Role
@export var personal_skills:Array[Skill]= []:
	set(value):
		personal_skills = value
		_generate_base_stats()
@export var personal_leveled_skills:Dictionary[int,Skill] = {}:
	set(value):
		personal_leveled_skills = value
		_generate_base_stats()
##Passives added to this array are treated as a unit's personal passives, they stick with a unit regardless of Species or Role
@export var personal_passives:Array[Passive]= []:
	set(value):
		personal_passives = value
		_generate_base_stats()
@export var personal_leveled_passives:Dictionary[int,Passive] = {}:
	set(value):
		personal_leveled_passives = value
		_generate_base_stats()

@export_category("Total Features - Do Not Edit")
##These are the accumilated Skills from Personal, Species, Role; Items. Do NOT add skills to this. Use personal_skills you fuckin' dipshit
@export var skills:Array[Skill] = []
##What did I say?
@export var leveled_skills:Dictionary[int,Passive] = {}
##These are the accumilated Passives from Personal, Species, Role; Items. Do NOT add passives to this. Use personal_passives you fuckin' dipshit
@export var passives:Array[Passive] = []
##What did I tell you to do?
@export var leveled_passives:Dictionary[int,Passive] = {}
#feature sorting arrays
var base_skills:Array[Skill] = []
var bonus_skills:Array[Skill]= []
var base_passives:Array[Passive] = []
var bonus_passives:Array[Passive] = []


@export_category("Inventory")
##Weapons and Subweapons usable by the Unit. It is better to give the unit a passive that adds/removes weapon prof than to change this manually.
@export var weapon_prof:Dictionary={ 
					"Blade": false,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Ofuda": false,
					"Bow": false,
					"Gun": false,
					"Sub": false}
var base_prof:Dictionary={
					"Blade": false,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Ofuda": false,
					"Bow": false,
					"Gun": false,
					"Sub": false}
##Maximum number of items a Unit can carry, cannot exceed [TBA]. It is better to give the unit a passive that increases Inv size than to change this number manually.
@export var max_inv : int = 0
##Unit inventory, add the appropriate resource wrapper, then make a new resource for the sort of item it is and fill in it's parameters.
@export var inventory: Array[Item]
#var inventory : Array[Item] = []
var unarmed : Weapon = load("res://unit_resources/items/weapons/unarmed.tres").duplicate() ##Default value for any unarmed unit, overwritten by Natural if Natural assigned
##Overrides unarmed as default when nothing is equipped if given a Weapon
@export var natural : Natural

@export_category("Conditions")
##Afflicted status conditions, do not change unless you have a good reason for a unit to begin play with specified condition.
@export var status : Dictionary = {"Acted":false, "Sleep":false}
var sParam : Dictionary = {}

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _animPlayer: AnimationPlayer = %AnimationPlayer:
	set(value):
		_animPlayer = value
		_animPlayer.play("idle")
@onready var _sprite_fx: SpriteFXHandler = %SpriteFxHandler
@onready var _pathFollow: PathFollow2D = $PathFollow2D
@onready var lifeBar = $PathFollow2D/Sprite/HPbar
@onready var map :GameMap
#endregion
#non-exported unit Paramters
#region vetted variables
#var roster_locked:= true
var deployment :Enums.DEPLOYMENT:
	set(value):
		if FACTION_ID == Enums.FACTION_ID.PLAYER:
			PlayerData.order_in_roster(unit_id,value,deployment)
			PlayerData.rosterData[unit_id].deployment = value
			deployment = value

var alive:= true
var on_chest:=false
var current_life:int = 1
var unitAuras := {}
var remaining_move:int = 0
#de/buffs applied to unit
var active_buffs :Dictionary[String,Dictionary]= {}
var active_debuffs :Dictionary[String,Dictionary]= {}
var active_item_effects := []
var active_auras := {}
#combination of base stats and buffs
var active_stats :Dictionary= {}
#Call for pre-formualted combat stats
var combatData := {"Dmg": 0, "Hit": 0, "Graze": 0, "Barrier": 0, "BarPrc": 0, "Crit": 0, "Luck": 0, "Resist": 0, "EffHit":0, "DRes": 0, "Type":Enums.DAMAGE_TYPE.PHYS, "CanMiss": true}
#art asset paths
var artPaths:Dictionary = {"Sprite":"","Prt":"","FullPrt":""}
var persistant_data : Dictionary
var killer : Unit
#queueing
var life_updated:bool = false
#endregion
#unit base data

var firstLoad := false
var tick = 1

#var forced : bool = false

var needDeath := false
var deathFlag := false

var terrainTags: Dictionary = {"BaseType": "", "ModType": "", "BaseId": "", "ModId": "", "Locked": false}
var postSequenceFlags := {"Bars":false, "Death":false}



#equip variables
#var natural  : Dictionary = {"ID": "NONE", "Equip": false, "Dur": -1, "Broken": false}
#var unarmed := {"ID": "NONE", "Equip": false, "Dur": -1, "Broken": false}
var tempSet = false



var isAmbushing := false

#base stats of the unit
var baseCombat := {}
#aura owned by unit


#Unique NPC/Enemy params
var isElite : bool = false

#Danmaku
var danmakuTypes := {}
var masterOf : String

## Coordinates of the current cell the cursor moved to.
var cell := Vector2i.ZERO:
	set(value):
		#print("fuck")
		cell = map.cell_clamp(value)
var lastGlbPosition := Vector2.ZERO
var originCell

# Toggles the "selected" animation on the unit.
var isSelected := false:
	set(value): #Buggy, causes idling when hovering unit after selecting and choosing movement
		isSelected = value
		if isSelected:
			_animPlayer.play("selected")
			#print(unit_id,":", _animPlayer.current_animation,":","Selected")
		elif status.Acted == false:
			_animPlayer.play("idle")
			#print(unit_id,":", _animPlayer.current_animation,"Selected")
		elif status.Acted == true:
			_animPlayer.play("disabled")
			#print(unit_id,":", _animPlayer.current_animation,"Selected")

#Animation Variables
var isWalking := false
var isShoved := false
var isTossed := false
var hp_changed := 0
var comp_changed := 0
var cDir := ""
var cAnim := ""
var pathPaused := false
##Animation States
##HERE Not complete, will return to later
var animation_state:=[
	"idle",
	"acted"
]

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


#region spec/role set functions
func _generate_base_stats():
	#Currently doesn't show possible stat totals when simulate_leveling is true
	if SPEC_ID and ROLE_ID:
		var keys = Enums.ROLE_ID.keys()
		var rolekey = keys[ROLE_ID]
		var newStats :Dictionary= PlayerData.get_unit_stats(SPEC_ID,ROLE_ID).duplicate()
		#print(newStats.Stats)
		base_stats = newStats.Stats
		base_growth = newStats.Growths
		base_caps = newStats.Caps
		move_type = newStats.MoveType
		max_inv = newStats.MaxInv
		weapon_prof = newStats.WeaponProf
		base_prof = weapon_prof
		_set_art_paths()
		#print(base_stats)
		_update_totals()
		_add_features(newStats.Skills, newStats.Passives)
		_update_features()
		set_equipped()
		#print("unit sidebar Updated")
		notify_property_list_changed()

func _update_features():
	skills.clear()
	passives.clear()
	
	for skill in base_skills:
		if personal_skills.has(skill): continue
		else: skills.append(skill)
		
	for level in personal_leveled_skills:
		if unit_level >= level: personal_skills.append(personal_leveled_skills[level])
		
	skills = skills + personal_skills + bonus_skills
	
	for passive in base_passives:
		if personal_passives.has(passive): continue
		else: passives.append(passive)
	
	for level in personal_leveled_passives:
		if unit_level >= level: personal_passives.append(personal_leveled_passives[level])
		
	passives = passives + personal_passives + bonus_passives
	check_passives()


func _update_totals():
	if SPEC_ID and ROLE_ID:
		#total_growth = Dictionary(base_growth[stat] + mod_growth[stat],Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_FLOAT,"",null)
		for stat in base_stats:
			#print(level_stats)
			total_stats[stat] = base_stats[stat] + mod_stats[stat] + level_stats[stat]
			total_growth[stat] = snappedf(base_growth[stat] + mod_growth[stat], 0.01)
			#print(total_growth[stat])
			total_caps[stat] = base_caps[stat] + mod_caps[stat]
		#print(total_stats)
		#print("unit totals Updated")


func _clear_simulations():
	level_stats = {
					"Move": 0, 
					"Life": 0,
					"Comp": 0,
					"Pwr": 0, 
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0,
					}


func _add_features(new_skills:Array, new_passives:Array) -> void:
	if !SPEC_ID or !ROLE_ID: return
	base_skills.clear()
	for skill in new_skills:
		if skill is not Skill and FileAccess.file_exists(skill): skill = load(skill)
		else: continue
		base_skills.append(skill)
	for passive in new_passives:
		if passive is not Passive and FileAccess.file_exists(passive): passive = load(passive)
		else: continue
		base_passives.append(passive)
	#print("unit features Updated")


func _add_new_leveled_features(level_results:Dictionary): 
	var newPassives:Array = level_results.NewPassives
	var newSkills:Array = level_results.NewSkills
	for passive in newPassives:
		bonus_passives[unit_level] = passive
	for skill in newSkills:
		bonus_skills[unit_level] = skill


func set_unit_id():
	if !unit_id and not Engine.is_editor_hint(): unit_id = PlayerData.generate_yk_id()
	unit_id = unit_id.to_snake_case()


func _set_unit_name():
	var stringId:String = "%s_name_%s"
	if unique_art: 
		stringId = stringId % ["unit",unit_id.to_snake_case()]
		unit_name = StringGetter.get_string(stringId)
		#print(unit_name)
	else:
		var role :StringName= Enums.ROLE_ID.keys()[ROLE_ID].to_snake_case()
		var spec :StringName= Enums.SPEC_ID.keys()[SPEC_ID].to_snake_case()
		var specId := stringId % ["species",spec]
		var roleId := stringId % ["role",role]
		unit_name = "%s %s" % [StringGetter.get_string(specId), StringGetter.get_string(roleId)]


func _initialize_parameters() -> void:
	var data :Dictionary = PlayerData.unitData
	#Previously generated Ids relied on unitData to know it was unique. Now it won't find these Ids there
	#There needs to be a redirection here
	#either the ID is generated at the time of checking for persistant data, then adding itself if none exists
	#or there needs to be a new method for tracking generated IDs
	#if !unit_id and not Engine.is_editor_hint(): unit_id = PlayerData.generate_id()
	update_stats()
	if simulate_leveling: _simulate_levels()
	active_stats["CurLife"] = active_stats.Life
	active_stats["CurComp"] = active_stats.Comp
	update_life_bar()
	#print(unit_id," Parameters Initialized")


func _simulate_levels():
	var loops:int = 0
	var results : Dictionary
	if unit_level > 1 and simulate_leveling:
		simulate_leveling = false
		loops = unit_level - 1
		unit_level = 1
		results = PlayerData.level_up(self, loops)
		_add_new_leveled_features(results)
		update_stats()
	else: return
#endregion


func _ready() -> void:
	var hitBox = $PathFollow2D/Sprite/UnitArea
	_generate_base_stats()
	_initialize_parameters()
	set_equipped()
	_load_sprites()
	hitBox.set_master(self)
	hitBox.area_entered.connect(self._on_aura_entered)
	hitBox.area_exited.connect(self._on_aura_exited)
	_animPlayer.play("idle")
	#Create the curve resource here because creating it in the editor prevents moving the unit
	_signals()
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
		_set_unit_name()
	_set_faction_group(FACTION_ID)
	unit_ready.emit(self)


func _signals():
	_sprite_fx.fx_ends.connect(self._on_fx_end)


func _process(delta: float) -> void:
	if !map: return
	elif tick == 0:
		var coord = $PathFollow2D/Cell
		coord.set_text(str(cell))
		tick = 1
	else:
		tick -= 1
	
	#swapped above needDeath, may break something. Return below if need be.
	if !pathPaused: _process_motion(delta)
	
	if needDeath:
		return


#region animation handling
func _on_fx_end(_fx_name:String):
	#if life_updated: 
		#update_life_bar()
	#else: animation_complete.emit(self)
	#Currently life bar updating just gets triggered and uses the sequence system, which is outdated.
	#It also only has ending the turn in mind, outdated thinking
	#For now healing items won't update the life bar, but will be added when reapproaching this 'sequence' system
	animation_complete.emit(self)


#region persistant data handling
func save_parameters() -> Dictionary:
	var RC:= ResourceConverter.new()
	var inventoryConvert := RC.resources_to_save_data(inventory)
	var naturalConvert :Dictionary = {}
	if natural: naturalConvert = natural.convert_to_save_data()
	var bonusSkills := RC.resources_to_save_data(bonus_skills)
	var personalSkills := RC.resources_to_save_data(personal_skills)
	var bonusPassives := RC.resources_to_save_data(bonus_passives)
	var personalPassives := RC.resources_to_save_data(personal_passives)
	var activeBuffs := RC.effects_to_save_data(active_buffs)
	var activeDebuffs := RC.effects_to_save_data(active_debuffs)
	var data :Dictionary ={
		"unit_id" = unit_id,
		"killer"= killer,
		#"deployment" = deployment,
		#"map" = map,
		"cell" = cell,
		"FACTION_ID" = FACTION_ID,
		"unit_level" = unit_level,
		"simulate_leveling" = simulate_leveling,
		"unit_exp" = unit_exp,
		"disabled" = disabled,
		"base_growth" = base_growth,
		"base_stats" = base_stats,
		"base_caps" = base_caps,
		"level_stats" = level_stats,
		"mod_growth" = mod_growth,
		"mod_stats" = mod_stats,
		"mod_caps" = mod_caps,
		#"skills" = skills,
		#"base_skills" = base_skills,
		"personal_skills" = personalSkills,
		"bonus_skills" = bonusSkills,
		#"passives" = passives,
		#"base_passives" = base_passives,
		"personal_passives" = personalPassives,
		"bonus_passives" = bonusPassives,
		"status" = status,
		#"active_auras" = active_auras, #Not good to do it this way. Need to put a check in _ready() to see if they are within any auras when loaded in
		#"active_item_effects" = active_item_effects,
		"active_buffs" = activeBuffs,
		"active_debuffs" = activeDebuffs,
		"current_life" = active_stats.CurLife,
		"current_comp" = active_stats.CurComp,
		"natural" = naturalConvert,
		"inventory" = inventoryConvert,
		"SPEC_ID" = SPEC_ID,
		"ROLE_ID" = ROLE_ID,
		"move_type" = move_type,
	}
	return data


##Replaces unit's initial data, returns false if dead, true if alive
func pre_load(unit_data:Dictionary) -> bool:
	#deployment = unit_data.deployment
	#if !alive: return false
	killer = unit_data.get("killer")
	disabled = unit_data.disabled
	unit_id = unit_data.unit_id
	FACTION_ID = int(unit_data.FACTION_ID)
	SPEC_ID = int(unit_data.SPEC_ID)
	ROLE_ID = int(unit_data.ROLE_ID)
	#move_type = unit_data.move_type
	unit_level = int(unit_data.unit_level)
	simulate_leveling = unit_data.simulate_leveling
	unit_exp = int(unit_data.unit_exp)
	mod_growth= Dictionary(unit_data.mod_growth,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_FLOAT,"",null)
	mod_stats= Dictionary(unit_data.mod_stats,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_INT,"",null)
	mod_caps= Dictionary(unit_data.mod_caps,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_INT,"",null)
	base_growth= Dictionary(unit_data.base_growth,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_INT,"",null)
	base_stats= Dictionary(unit_data.base_stats,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_INT,"",null)
	level_stats= Dictionary(unit_data.level_stats,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_INT,"",null)
	base_caps= Dictionary(unit_data.base_caps,Variant.Type.TYPE_STRING_NAME,"",null,Variant.Type.TYPE_INT,"",null)
	if unit_data.natural:
		_load_natural(unit_data.natural)
	_load_inventory(unit_data.inventory)
	#skills = unit_data.skills
	#base_skills = unit_data.base_skills
	_load_features(unit_data.personal_skills, personal_skills)
	_load_features(unit_data.bonus_skills, bonus_skills)
	#passives = unit_data
	#base_passives = unit_data.base_passives
	_load_features(unit_data.personal_passives, personal_passives)
	_load_features(unit_data.bonus_passives, bonus_passives)
	return true


##Run after unit is ready to set values. set_cell:True relocates the unit, used for suspended saves.
func post_load(unit_data:Dictionary, set_cell:bool=false)->void:
	var convCell: Vector2i
	active_stats.CurLife = int(unit_data.current_life)
	active_stats.CurComp = int(unit_data.current_comp)
	status = unit_data.status
	#active_item_effects = unit_data.active_item_effects
	_load_buff_effects(unit_data.active_buffs,active_buffs)
	_load_buff_effects(unit_data.active_debuffs,active_debuffs)
	if set_cell:
		convCell = str_to_var("Vector2i" + unit_data.cell) as Vector2i
		relocate_unit(convCell)


func _load_inventory(resources:Dictionary):
	var RC:= ResourceConverter.new()
	inventory.clear()
	inventory = RC.inventory_to_resource(resources)


func _load_buff_effects(effects:Dictionary, destination:Dictionary):
	var RC:=ResourceConverter.new()
	destination=RC.buff_effects_to_resource(effects)


func _load_natural(natural_data:Dictionary):
	var RC:=ResourceConverter.new()
	RC.natural_to_resource(natural_data)


func _load_features(features:Dictionary, destination:Array):
	var RC:= ResourceConverter.new()
	destination.assign(RC.features_to_resource(features))
#endregion

func initialize_cell(new_cell:Vector2i = Vector2i.ZERO):
	if !new_cell: cell = map.local_to_map(position)
	else: cell = new_cell
	originCell = cell
	relocate_unit(cell)
	update_terrain_data()


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
func walk_along(path: PackedVector2Array, track_remaining:bool=false) -> void:
#	#print("walk along")
	if track_remaining: remaining_move = path.size()-total_stats.Move
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


func relocate_unit(location:Vector2i, gridUpdate := true):
	var oldCell := Vector2i(cell)
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
	#print(unit_id,":", _animPlayer.current_animation,"Revert")


func toggle_path_pause():
	pathPaused = !pathPaused


func return_original():
	position = map.map_to_local(originCell)
	cell = originCell
	#print(originCell, cell)
	return cell


#keep track of active de/buffs during gameplay, seperate from actual stats
func set_buff(effect:Effect):
	var type := effect.type
	var buffs
	var effectId:= effect.id
	match type:
		Enums.EFFECT_TYPE.BUFF: buffs = active_buffs
		Enums.EFFECT_TYPE.DEBUFF: buffs = active_debuffs
	if effect == null:
		print("No effect found")
		return
	if effect.stack:
		effectId = _increment_unique_id(buffs,effect.id)
	if effect.duration_type == Enums.DURATION_TYPE.PERMANENT:
		apply_permanent_stat_mod(effect.sub_type,effect.value)
	else:
		buffs[effectId] = _generate_buff_entry(effect)
	update_stats()


func _generate_buff_entry(effect:Effect)->Dictionary:
	var entry:={"Effect":effect,"Duration":effect.duration}
	return entry


func _increment_unique_id(storage:Dictionary,id:String)->String:
	var i := 0
	var newId:= id + str(i)
	while storage.has(newId):
			i += 1
			newId = id + str(i)
	return newId


func apply_permanent_stat_mod(stat,value)->void:
	var statKeys : Array = Enums.CORE_STAT.keys()
	if stat is int: stat = statKeys[stat]
	if stat is not String:
		printerr("stat type or value mistmatch: stat must be an appropriate String or Enums.CORE_STAT value")
		return
	mod_stats[stat] += value


func remove_buff(effect_id:String):
	if active_buffs.has(effect_id):
		active_buffs.erase(effect_id)
	if active_debuffs.has(effect_id):
		active_debuffs.erase(effect_id)
	update_stats()
	
	
##tracks duration of effects, then removes them when reaching 0.
func status_duration_tick(duration:Enums.DURATION_TYPE)->void:
	var keys = active_buffs.keys()
	for i in range(0,1):
		if i == 1: keys = active_debuffs.keys()
		for effect in keys:
			if active_buffs[effect].Effect.duration_type != duration: continue
			if active_buffs[effect].Duration > 0: active_buffs[effect].Duration -= 1
			if active_buffs[effect].Duration == 0: remove_buff(effect)
	
	for key in status: #Why is status conditions so fucking convoluted????
			if status[key] and sParam.has(key) and sParam[key].DurationType != duration: continue
			if status[key] and sParam.has(key) and sParam[key].Duration > 0:
				sParam[key].Duration -= 1
			if status[key] and sParam.has(key) and sParam[key].Duration <= 0:
				status[key] = false
				sParam.erase(key)
	#%Cell2.set_text(str(status.Sleep))
	update_stats()


func _set_art_paths():
	var roleKeys : Array = Enums.ROLE_ID.keys()
	var role : String = roleKeys[ROLE_ID].to_snake_case()
	var directory: String
	if unique_art:
		directory = unit_id.to_snake_case()
		#print("Unique Art Set")
	else:
		var specKeys : Array = Enums.SPEC_ID.keys()
		directory = specKeys[SPEC_ID].to_snake_case()
		#print("Generic Art Set")
	artPaths["Sprite"] = "res://sprites/character/%s/%s_sprite.png" % [directory, role]
	#print(artPaths.Sprite)
	artPaths["Prt"] = "res://sprites/character/%s/%s_portrait.png" % [directory, role]
	artPaths["FullPrt"] = "res://sprites/character/%s/%s_portrait_full.png" % [directory, role]
	if Engine.is_editor_hint(): _load_sprites()


func _load_sprites():
	#print(artPaths.Sprite)
	if _sprite: _sprite.refresh_self()
	#_animPlayer.play("idle")
	#print("MODULATION:",get_self_modulate())
	#print(unit_id,":", _animPlayer.current_animation,"Load Sprite")


func get_condition() -> Dictionary: #maybe expand this in the future, for now that's all
	var c: Dictionary = {}
	c["Hp%"] = (active_stats.CurLife / active_stats.Life) * 100
	c["Comp"] = active_stats.CurComp
	c["Status"] = status.duplicate(true)
	return c

func can_act() -> bool:
	if active_stats.CurLife <= 0 or status.Sleep or get_equipped_weapon() == unarmed:
		return false
	return true


#region Passive Functions
func check_passives() ->void:
	var auras :Array[Aura]= []
	if !passives: return
	for p in passives:
		if p == null: continue
		match p.type:
			Enums.PASSIVE_TYPE.AURA:
				auras.append(_assign_auras(p))
			Enums.PASSIVE_TYPE.SUB_WEAPON:
				_add_sub_weap(p.sub_weapon)
				_update_natural(p)
	if auras: validate_auras(auras)


func can_canto()->bool:
	if PlayerData.canto_triggered and has_passive(Enums.PASSIVE_TYPE.CANTO) and remaining_move>0: return true
	return false


func has_passive(passive_type:Enums.PASSIVE_TYPE)->bool:
	for p in passives:
		if p == null:continue
		if p.type == passive_type: return true
	return false

func can_pick()->bool:
	for p in passives:
		if p == null:continue
		if p.type == Enums.PASSIVE_TYPE.LOCKPICK: return true
	return false
#endregion

##Non-permanent Skills Function
func validate_skills(): #The fuck am I trying to do here???
	var valid = []
	for s in skills:
		match s.target:
			Enums.EFFECT_TARGET.EQUIPPED: pass
				
	validate_auras(valid)


##Validate skills from effects
func validate_active_effect_skills():
	bonus_skills.clear()
	for effect in active_item_effects:
		if effect.type == Enums.EFFECT_TYPE.ADD_SKILL:
			_resolve_bonus_skill(effect)
	_update_features()


func _resolve_bonus_skill(effect: Effect) -> void:
	if personal_skills.has(effect.skill): return
	else: 
		bonus_skills.append(effect.skill)


func _add_sub_weap(subType):
	var st = Enums.WEAPON_SUB.keys()[subType].to_pascal_case()
	#print(st)
	weapon_prof[st] = true



func _assign_auras(passive:Passive) -> Aura:
	var aura : Aura
	match passive.rule_type:
		Enums.RULE_TYPE.MORPH: aura = passive[Enums.TIME.keys()[Global.time_of_day].to_lower()]
		Enums.RULE_TYPE.TIME: 
			if passive.rule == Global.time_of_day: aura = passive.aura
		_: aura = passive.aura
	if !unitAuras.has(aura):load_aura(aura)
	return aura


func check_time_prot() -> bool:
	var validTime
	#Global.time_of_day
	for p in passives:
		match p.type:
			Enums.PASSIVE_TYPE.NIGHT_PROT:
				validTime = Enums.TIME.NIGHT
			Enums.PASSIVE_TYPE.DAY_PROT:
				validTime = Enums.TIME.DAY
			_: continue
		if p.sub_rule == SPEC_ID and Global.time_of_day == validTime:
			return true
	return false


func search_passive_id(type):
	var highest = 0
	var found = false
	for p in passives:
		if p.type == type and p.value > highest:
			highest = p.value
			found = p
	return found


##Aura Functions
func validate_auras(valid:Array[Aura]):
	for a in unitAuras:
		if !valid.has(a):
			remove_aura(a)


func remove_aura(a:Aura):
	if unitAuras.has(a):
		unitAuras[a].queue_free()
		unitAuras.erase(a)


func load_aura(aura:Aura):
	if unitAuras.has(aura):
		return
	var auraArea :AuraArea= load("res://scenes/aura_collision.tscn").instantiate()
	var pathFollow = $PathFollow2D
	
	pathFollow.add_child(auraArea)
	auraArea.call_deferred("set_aura",self, aura)
	unitAuras[aura] = auraArea
	
	
func get_visual_aura_range() -> int:
	var highest := 0
	for p in unitAuras:
		var a = p.aura
		if a.range > highest:
			highest = a.range
	return highest
		

func _on_aura_entered(area):
	#print("Aura Entered: ", area)
	if !area.aura:
		return
	
	match area.aura.target_team:
		Enums.TARGET_TEAM.ALLY:
			if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and FACTION_ID == Enums.FACTION_ID.NPC:
				pass
			elif area.master.FACTION_ID != FACTION_ID:
				return
		Enums.TARGET_TEAM.ENEMY:
			if area.master.FACTION_ID == FACTION_ID:
				return
	
	if area.aura.target == Enums.EFFECT_TARGET.SELF:
		return
	elif !active_auras.has(area):
		active_auras[area] = area.aura.effects.duplicate()
	update_stats()


func _on_aura_exited(area):
	#print("Aura Exited: ", area)
	if active_auras.has(area):
		active_auras.erase(area)
		#print("Active Aura Effects: ", active_auras)
	update_stats()

func _on_self_aura_entered(area, ownArea):
	#print("on_self_aura_entered: ", area.master)
	match ownArea.aura.target_team:
		Enums.TARGET_TEAM.ALLY:
			if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and FACTION_ID == Enums.FACTION_ID.NPC:
				pass
			elif area.master.FACTION_ID != FACTION_ID:
				return
		Enums.TARGET_TEAM.ENEMY:
			if area.master.FACTION_ID == FACTION_ID:
				return
	
	if ownArea.aura.target == Enums.EFFECT_TARGET.SELF:
		if !active_auras.has(ownArea):
			active_auras[ownArea] = ownArea.aura.effects.duplicate()
		else: 
			for effect in ownArea.aura.effects:
				if effect.stack:
					active_auras[ownArea].append(effect)
	
	
	update_stats()
	#print("Active Aura Effects: ", active_auras)
		

func _on_self_aura_exited(area, ownArea):
	#print("on_self_aura_exited: ", area.master)
	if active_auras.has(ownArea) and active_auras[ownArea].size() > 0:
		active_auras[ownArea].pop_back()
	if active_auras.has(ownArea) and active_auras[ownArea].size() <= 0:
		active_auras.erase(ownArea)
	print("Active Aura Effects: ", active_auras)
	update_stats()


#region Equipment functions
##searches for first valid weapon if false, otherwise unequips current and equips the passed Item
func set_equipped(item : Item = null, is_temp := false) -> void:
	var alreadyEquipped:bool = false
	for weapon in inventory:
		if weapon is Weapon and weapon.equipped: alreadyEquipped = true
	if item == null and natural and natural.equipped:
		return
	elif item == null:
		if alreadyEquipped: return
		item = _find_first_valid()
	elif !check_valid_equip(item) and item != unarmed and item != natural: 
		return
	if item is Weapon:
		_equip_weapon(item, is_temp)
	if item is Accessory:
		_equip_acc(item)
	update_stats()


##returns the currently equipped weapon within inventory. Returns generic "unarmed", or unit's Natural weapon if there is none.
func get_equipped_weapon() -> Weapon:
	for item in inventory:
		if item is not Weapon:
			continue
		if item.equipped: return item
	if natural: return natural
	else: return unarmed


##returns the currently equipped accessories. Return false if none.
func get_equipped_accs() -> Array[Accessory]:
	var equipped:= []
	for item : Accessory in inventory:
		if item is not Accessory:
			continue
		if item.equipped: equipped.append(item)
	return equipped


##Equips the given weapon, and unequips whatever was already equipped. if isTemp, it sets it as a temporary equip and remembers it's true equip.
func _equip_weapon(weapon : Weapon, is_temp := false) -> void:
	var oldEquip : Array[Weapon]
	var original : Weapon
	var replaced : Weapon
	for item in inventory:
		if item is not Weapon: continue
		elif item.equipped and item == weapon: return
		elif item.temp_remove: original = item
		elif item.equipped:
			oldEquip.append(item)
	
	if !oldEquip.is_empty():
		replaced = oldEquip.pop_front()
		if is_temp and !original: replaced.temp_remove = is_temp
		unequip(replaced)
	weapon.equipped = true
	if !is_temp and inventory.has(weapon):
		var i := inventory.find(weapon)
		var storage :Item = inventory.pop_at(i)
		inventory.push_front(storage)
	if !is_temp and original: original.temp_remove = false
	_add_equip_effects(weapon)


##Equips the given Accessory, if this would go over Accessory limit, unequips the first equipped accessory to make room
func _equip_acc(acc : Accessory) -> void:
	var limit : int = 2 ##Replace with a unit parameter later
	var count : int = 0
	var equipped : Array[Item] = []
	for item in inventory:
		if item is not Accessory: continue
		elif item.equipped:
			equipped.append(item)
			count += 1
	while count >= limit:
		var remove : Item = equipped.pop_back()
		unequip(remove)
		count -= 1
	acc.equipped = true
	_add_equip_effects(acc)


##unequips the given item, removing it's effects if any. if as_command is true, it acts as the unequip command and assigns unarmed/natural if there are no weapons equipped after unequipping.
func unequip(item:Item, as_command:=false) -> void:
	item.equipped = false
	_remove_equip_effects(item)
	if !as_command: return
	for weapon : Weapon in inventory:
		if weapon is Weapon and weapon.equipped:
			return
	if natural: _equip_weapon(natural)
	else: _equip_weapon(unarmed)
	update_stats()


##returns the first valid weapon of a unit, if none are found, returns unarmed. If unit has natural, it has priority.
func _find_first_valid() -> Weapon:
	if natural: return natural
	for i : Weapon in inventory:
		if i is Weapon and check_valid_equip(i):
			return i
	return unarmed


##Validates if an Item can be equipped by unit.
func check_valid_equip(item : Item) -> bool:
	var iCat = item.category
	var subCat = item.sub_group
	if item is Weapon or item is Consumable:
			if is_proficient(iCat, subCat) and !item.is_broken:
				return true
	elif item is Accessory: return is_rule_met(item.rule_type, item.sub_rule)
	return false


##check if unit can use weapon's type
func is_proficient(i_cat : Enums.WEAPON_CATEGORY, sub_cat : Enums.WEAPON_SUB) -> bool:
	#Update for Unit Resource
	var catKeys = Enums.WEAPON_CATEGORY.keys()
	var subKeys = Enums.WEAPON_SUB.keys()
	if sub_cat == Enums.WEAPON_SUB.NONE and i_cat == Enums.WEAPON_CATEGORY.NONE: return true
	elif i_cat == Enums.WEAPON_CATEGORY.ITEM: return false
	elif i_cat == Enums.WEAPON_CATEGORY.ACC: return true
	elif sub_cat != Enums.WEAPON_SUB.NONE and weapon_prof[subKeys[sub_cat].to_pascal_case()]: return true
	elif weapon_prof[catKeys[i_cat].to_pascal_case()]: return true
	return false


##Checks if unit meets the given rule types returns true or false
func is_rule_met(rule_type:Enums.RULE_TYPE, sub_type:Enums.SUB_RULE) -> bool:
	#check if unit meets rules given
	return true

##Restores the temporarily unequipped weapon
func restore_equip() -> void:
	for weapon :Item in inventory:
		if weapon is Weapon and weapon.temp_remove:
			weapon.temp_remove = false
			set_equipped(weapon)
			break


func _add_equip_effects(item:Item):
	if !item.effects.is_empty():
		for effect in item.effects:
			if effect.target == Enums.EFFECT_TARGET.EQUIPPED:
				_add_effect(effect)
	#print(active_item_effects)


func _remove_equip_effects(item):
	if item.get("effects"):
		for effect in item.effects:
			var i = active_item_effects.find(effect)
			active_item_effects.remove_at(i)
	#print(active_item_effects)


func _add_effect(effect):
	active_item_effects.append(effect)


func _remove_effect(effect):
	var i = active_item_effects.find(effect)
	active_item_effects.remove_at(i)
#endregion

#region reach functions
func get_reach() -> Dictionary:
	var reach = {"Max":-999, "Min":999}
	var wep = get_weapon_reach()
	var aug = {"Max":-999, "Min":999}
	var skill = {"Max":-999, "Min":999}
	for s in skills:
		if s.augment: 
			var r = get_aug_reach(s)
			aug.Min = mini(r.Min, aug.Min)
			aug.Max = maxi(r.Max, aug.Max)
		elif s.max_reach > 0:
			var r = get_skill_reach(s)
			skill.Min = mini(r.Min, skill.Min)
			skill.Max = maxi(r.Max, skill.Max)
	reach.Min = mini(skill.Min, reach.Min)
	reach.Max = maxi(skill.Max, reach.Max)
	reach.Min = mini(aug.Min, reach.Min)
	reach.Max = maxi(aug.Max, reach.Max)
	return reach


##Returns reach = {"Max":int, "Min":int} of given currently equipped weapon
func get_weapon_reach() -> Dictionary:
	var reach = {"Max":-999, "Min":999}
	for weapon: Item in inventory:
			if weapon is not Weapon and weapon is not Ofuda: 
				continue
			elif !check_valid_equip(weapon): 
				continue
			reach.Min = mini(weapon.min_reach, reach.Min)
			reach.Max = maxi(weapon.max_reach, reach.Max)
	if natural:
		reach.Min = mini(natural.min_reach, reach.Min)
		reach.Max = maxi(natural.max_reach, reach.Max)
	return reach


##Returns reach = {"Max":int, "Min":int} of given skillId
func get_skill_reach(skill : Skill) -> Dictionary:
	var reach = {"Max":-999, "Min":999}
	reach.Min = skill.min_reach
	reach.Max = skill.max_reach
	#Insert passive check for skill range bonuses here
	return reach


##Returns reach = {"Max":int, "Min":int} of given augment type skillId
func get_aug_reach(skill : Skill) -> Dictionary:
	var reach = {"Max":-999, "Min":999}
	if skill.min_reach == 0 or skill.max_reach == 0:
		for weapon:Item in inventory:
			if weapon is not Weapon and weapon is not Ofuda: continue
			if !check_valid_equip(weapon): continue
			elif weapon.category != skill.weapon_category and weapon.sub_group != skill.weapon_category: continue
			reach.Min = mini(weapon.min_reach, reach.Min)
			reach.Max = maxi(weapon.max_reach, reach.Max)
		if natural:
			reach.Min = mini(natural.min_reach, reach.Min)
			reach.Max = maxi(natural.max_reach, reach.Max)
	else:
		reach.Min = skill.min_reach
		reach.Max = skill.max_reach
	reach.Min += skill.bonus_min_range
	reach.Max += skill.bonus_min_range
	return reach
#endregion

func has_valid_aug_weapon(skill : Skill) -> bool:
	var isValid := false
	var skillRange = range(skill.min_reach, skill.max_reach + 1)
	var hasReach : bool
	var hasType : bool
	for weapon : Weapon in inventory:
		if weapon is not Weapon or !check_valid_equip(weapon): continue
		hasReach = false
		hasType = false
		
		if skill.max_reach == 0 and skill.min_reach == 0: hasReach = true
		elif skillRange.has(weapon.min_reach) or skillRange.has(weapon.max_reach): hasReach = true
		
		if skill.weapon_category == Enums.WEAPON_CATEGORY.ANY: hasType = true
		elif weapon.category == skill.weapon_category or weapon.sub_group == skill.sub_group: hasType = true
			
		if hasReach and hasType:
			isValid = true
			break
	return isValid

#region item use functions
func use_item(_item : Item) -> void:
	_animPlayer.play("use_item")
	

#func end_item_use():
	#_animPlayer.play("idle")



func receive_item(item:Item)->void:
	var id :String = item.get_main_effect_id()
	_sprite_fx.play_item_fx(id)
	update_life_bar()



##Item only considered broken at 0 durability!!! If reduc value would put an item below 0, it is clamped to 0 and will break.
func reduce_durability(item : Item, reduc : int = 1) -> void:
	var maxDur = item.max_dur
	print("Durability reduction for: ", item.id)
	if !item.breakable:
		print("Weapon is unbreakable")
		return
	item.dur = clampi(item.dur-reduc, 0, maxDur)
	print("Durability reduced to: ", item.dur)
	if item.dur > 0: return
	elif item.expendable: 
		call_deferred("delete_item", item)
		print("Queued item Deletion")
	else: item.is_broken = true
	if item.equipped:
		print("Item Broken, unequipping")
		unequip(item, true)


func delete_item(item : Item):
	var i : int = inventory.find(item)
	if item.equipped:
		unequip(item, true)
	inventory.pop_at(i)
#endregion


func _update_natural(passive) -> void:
	var natId : String
	if passive.sub_weapon != Enums.WEAPON_SUB.NATURAL: return
	else: natId = passive.string_value
	#print(natId)
	if natural==null and natId:
		natural = _get_natural_weapon(natId)
	
	if natural==null: return
	elif !natural.is_scaling: return
	
	#move to Natural wrapper
	var scaleType = passive.string_value
	var dmgScale :int= 0
	var hitScale :int= 0
	var barrierScale :int= 0
	var tier : int = unit_level
	
	match scaleType: 
		"NaturalMartial": 
			dmgScale = 2 + ceili(unit_level/4)
			hitScale = 65 + ceili(unit_level)
			barrierScale = 2 + ceili(unit_level/6)
	
	match tier:
		40: tier = 6
		tier when tier > 35: tier = 5
		tier when tier > 25: tier = 4
		tier when tier > 15: tier = 3
		tier when tier > 5: tier = 2
		_: tier = 1
	
	natural.dmg = natural.properties.dmg + dmgScale
	natural.hit = natural.properties.hit + hitScale
	natural.barrier = natural.properties.barrier + barrierScale
	natural.id = natural.properties.id + str(tier)


func _get_natural_weapon(natId:String)->Natural:
	var natRes : NaturalResource
	var newNat : Natural
	var natPath : String = "res://unit_resources/items/weapons/%s.tres"
	if natId: natPath = natPath % [natId]
	#print(natPath)
	if ResourceLoader.exists(natPath):
		natRes = load(natPath)
		newNat = Natural.new()
		newNat.stats = natRes
	else: print("Unit/_get_update_natural: invalid natural weapon path")
	return newNat


func get_multi_swing():
	var swings : int = 0
	for effect in active_item_effects:
		if effect.type == Enums.EFFECT_TYPE.MULTI_SWING and effect.value > swings:
			swings = effect.value
	if swings == 0:
		return false
	else:
		return swings


func get_multi_round():
	var rounds : int = 0
	for effect in active_item_effects:
		if effect.type == Enums.EFFECT_TYPE.MULTI_ROUND and effect.value > rounds:
			rounds = effect.value
	if rounds == 0:
		return false
	else:
		return rounds


func get_crit_dmg_effects():
	var effects : Dictionary = {"CritDmg": false, "CritMulti": false}
	var highest := 0
	var dmgStack := [0, 0]
	
	for effect in active_item_effects:
		if effect.type == Enums.EFFECT_TYPE.CRIT_BUFF and effect["CritDmg"]:
			dmgStack[0] += effect["CritDmg"][0]
			dmgStack[1] += effect["CritDmg"][1]
			effects.CritDmg = dmgStack
		if effect.type == Enums.EFFECT_TYPE.CRIT_BUFF and effect["CritMulti"] and effect["CritMulti"] > highest:
			highest = effect["CritMulti"]
			effects.crit_multi = highest
			
	return effects


func update_combatdata():
	#no catch for empty inv!!!!! HERE Wait, isn't there one? setting it to Null, and then having null translate to "NONE" when all null instances could just be "NONE" is retarded. Fix this, you god damned retard.
	var tBonus = update_terrain_bonus()
	var wep :Weapon = get_equipped_weapon()
	combatData.Type = wep.damage_type
	if wep.damage_type == Enums.DAMAGE_TYPE.PHYS:
		combatData.Dmg = wep.dmg + active_stats.Pwr + tBonus.PwrBonus
	elif wep.damage_type == Enums.DAMAGE_TYPE.MAG:
		combatData.Dmg = wep.dmg + active_stats.Mag + tBonus.MagBonus
	elif wep.damage_type == Enums.DAMAGE_TYPE.TRUE:
		combatData.Dmg = wep.dmg
	combatData.Hit = active_stats.Eleg * 2 + (wep.hit + active_stats.Cha + tBonus.HitBonus)
	combatData.Graze = active_stats.Cele * 2 + active_stats.Cha + tBonus.GrzBonus
	combatData.Barrier = wep.barrier
	combatData.BarPrc = (active_stats.Eleg/2) + (active_stats.Def/2) + wep.barrier_chance + tBonus.DefBonus
	combatData.Crit = active_stats.Eleg + wep.crit
	combatData.Luck = active_stats.Cha
	combatData.CompRes = (active_stats.Cha / 2) + (active_stats.Eleg / 2)
	combatData.CompRes = clampi(combatData.CompRes, -200, 75)
	combatData.CompBonus = active_stats.Cha / 4
	combatData.MagBase = active_stats.Mag
	combatData.PwrBase = active_stats.Pwr
	combatData.HitBase = active_stats.Eleg * 2 + active_stats.Cha
	combatData.CritBase = active_stats.Eleg
	combatData.Resist = active_stats.Cha * 2
	combatData.EffHit = active_stats.Cha
	combatData.DRes = {Enums.DAMAGE_TYPE.PHYS: active_stats.Def, Enums.DAMAGE_TYPE.MAG: active_stats.Mag, Enums.DAMAGE_TYPE.TRUE: 0}
	combatData.CanMiss = true
	if status.Sleep:
		combatData.Graze = 0
		combatData.BarPrc = 0
	baseCombat = combatData.duplicate()
	
func get_skill_combat_stats(skill:SlotWrapper, augmented := false):
	var stats = combatData.duplicate()
	var dmgStat := 0
	var attack : SlotWrapper
	var typeLord : Enums.DAMAGE_TYPE
	if augmented: 
		attack = get_equipped_weapon()
	else: attack = skill
	
	if augmented and skill.dmg_type: typeLord = skill.dmg_type
	else: typeLord = attack.dmg_type
	
	match typeLord:
		Enums.DAMAGE_TYPE.PHYS: dmgStat = stats.PwrBase
		Enums.DAMAGE_TYPE.MAG: dmgStat = stats.MagBase
		Enums.DAMAGE_TYPE.TRUE: dmgStat = 0
		
	if !skill.can_dmg:
		stats.Dmg = false
	elif augmented:
		stats.Dmg = dmgStat + attack.dmg + skill.dmg
	else:
		stats.Dmg = dmgStat + attack.dmg

	stats.CanMiss = skill.can_miss
	
	if augmented:
		stats.Hit = stats.HitBase + attack.hit + skill.hit
	else:
		stats.Hit = stats.HitBase + attack.hit
	
	if !skill.crit and skill.crit != 0:
		stats.Crit = false
	elif augmented: 
		stats.Crit = stats.CritBase + attack.crit + skill.crit
	else: 
		stats.Crit = stats.CritBase + attack.crit
	return stats


func update_stats(): #GO BACK AND FINISH ACTIVE DEBUFFS AFTER THIS
	var effSort := []
	var time := Global.time_of_day
	var timeMod : Dictionary = PlayerData.timeModData[SPEC_ID][time]
	var statKeys := total_stats.keys()
	var buffTotal := {}
	var baseUpdated := false
	var combatUpdated := false
	var modifiedStats :Dictionary= active_stats
	var baseValues :Dictionary
	var subKeys := Enums.SUB_TYPE.keys()
	_update_totals()
	baseValues = total_stats
	check_passives()
	validate_active_effect_skills()
	
	if baseValues == null or active_stats == null or lifeBar == null:
		return
	
	#lifeBar.value = active_stats.CurLife
	#if active_stats["CurLife"] <= 0:
		#run_death()
		#return
	#if active_stats.CurComp <= 0:
		#pass #comp check!
	#######
	
	while !combatUpdated:
		buffTotal.clear()
		if baseUpdated:
			statKeys = combatData.keys()
			modifiedStats = combatData
			#This updates active_stats, and leaves base stats alone.
			#It does not do the same for combatData, it directly buffs it with no seperation.
			baseValues = combatData
			
		for stat in statKeys:
			stat = stat.to_pascal_case()
			buffTotal[stat] = 0
			if timeMod.has(stat) and check_time_prot():
				buffTotal[stat] += clampi(timeMod[stat], 0, 999999)
			elif timeMod.get(stat):
				buffTotal[stat] += timeMod[stat]
		
		for aura in active_auras:
			for effect in active_auras[aura]:
				var mod = effect
				var stat = subKeys[mod.sub_type].to_pascal_case()
				if buffTotal.has(stat): buffTotal[stat] += mod.value
		
		for buff in active_buffs:
			var subType:int=active_buffs[buff].Effect.sub_type
			var stat = subKeys[subType].to_pascal_case()
			if buffTotal.has(stat): buffTotal[stat] += active_buffs[buff].Effect.value
			
		for debuff in active_debuffs:
			var subType:int=active_debuffs[debuff].Effect.sub_type
			var stat = subKeys[subType].to_pascal_case()
			if buffTotal.has(stat): buffTotal[stat] += active_debuffs[debuff].Effect.value
			
		for effect in active_item_effects:
			if effect.type == Enums.EFFECT_TYPE.BUFF or effect.type == Enums.EFFECT_TYPE.DEBUFF:
				effSort.append(effect)
					
		for effect in effSort:
			var stat = subKeys[effect.sub_type].to_pascal_case()
			if effect.Target == Enums.EFFECT_TARGET.EQUIPPED:
				if buffTotal.has(stat): buffTotal[stat] += effect.value
		
		for stat in statKeys:
			if !buffTotal.has(stat):
				continue
			match stat:
				"DRes": 
					#print(stat)
					#print(buffTotal)
					#print(modifiedStats["DRes"])
					modifiedStats["DRes"][Enums.DAMAGE_TYPE.PHYS] += buffTotal[stat]
					modifiedStats["DRes"][Enums.DAMAGE_TYPE.MAG] += buffTotal[stat]
				"PhysDef": modifiedStats["DRes"][Enums.DAMAGE_TYPE.PHYS] += buffTotal[stat]
				"MagDef": modifiedStats["DRes"][Enums.DAMAGE_TYPE.MAG] += buffTotal[stat]
				"CanMiss": continue
				_: modifiedStats[stat] = clampi(baseValues[stat] + buffTotal[stat],0,255)
		
		
		if timeMod.MoveType: #HERE need sprite swap for fly/foot movement changes
			modifiedStats["move_type"] = timeMod.MoveType
		else: modifiedStats["move_type"] = move_type
			
		if !baseUpdated:
			update_combatdata()
			baseUpdated = true
		else:
			combatUpdated = true
		lifeBar.max_value = active_stats.Life
	update_sprite()
	
	if status.Sleep:
		active_stats.Move = 0


#func on_sequence_concluded():
	##check post-sequence event que?
	#update_life_bar()
	#check_death()
	##finally allow turn completion?


func danmaku_collision():
	update_life_bar()
	check_death()


func confirm_post_sequence_flags(flag)->bool:
	postSequenceFlags[flag] = true
	for f in postSequenceFlags:
		if !postSequenceFlags[f]:
			return false
	return true
	#_turn_complete()


func _turn_complete():
	postSequenceFlags.Bars = false
	postSequenceFlags.Death = false
	emit_signal("turn_complete", self)


func update_sprite():
	for condition in status:
		if status[condition]:
			if condition == "Sleep" or condition == "Acted":
				_animPlayer.play("disabled")
				#print(unit_id,":", _animPlayer.current_animation,"Update Sprite")
				return
	if !isWalking and !isShoved and !needDeath and !isSelected:
		_animPlayer.play("idle")
		#print(unit_id,":", _animPlayer.current_animation,"Update Sprite")
		
		
func check_death():
	if active_stats["CurLife"] <= 0:
		run_death()
		return true
	else:
		return false
		#confirm_post_sequence_flags("Death")


func check_break():
	bars_updated.emit(self)
	#animation_complete.emit(self)


func update_life_bar():
	var tween = get_tree().create_tween()
	if hp_changed < 0:
		play_animation("Hit")
		hp_changed = 0
	elif hp_changed > 0:
		hp_changed = 0
	tween.finished.connect(self._life_tween_finished)
	tween.tween_property($PathFollow2D/Sprite/HPbar, "value", active_stats.CurLife, 0.5)


func process_bars():
	update_life_bar()


func _life_tween_finished():
	if !check_death(): update_composure_bar()
	#confirm_post_sequence_flags("Bars")


func update_composure_bar():
	if active_stats.CurComp <= 0:
		pass #comp check!
	_comp_tween_finished()


func _comp_tween_finished():
	revert_animation()
	check_break()


func pick_door(door:DoorTile):
	
	_animPlayer.play("pick")
	await animation_complete
	door.unlock()


func apply_dmg(dmg : int, source : Unit = null):
	active_stats.CurLife -= dmg
	active_stats.CurLife = clampi(active_stats.CurLife, 0, active_stats.Life)
	if active_stats.CurLife == 0:
		if source: killer = source
		deathFlag = true
	if dmg > 0 and status.Sleep:
		cure_status("Sleep")
	if dmg > 0:
		hp_changed = 0 - dmg
	#return active_stats.CurLife


func apply_heal(heal := 0):
	if heal > 0: 
		hp_changed = heal
		active_stats.CurLife += heal
		active_stats.CurLife = clampi(active_stats.CurLife, 0, active_stats.Life)



func apply_composure(comp := 0):
	if comp>0 or comp<0: 
		comp_changed = comp
		active_stats.CurComp -= comp
		active_stats.CurComp = clampi(active_stats.CurComp, 0, active_stats.Comp)


func has_enough_comp(cost:int) -> bool:
	var isValid := false
	if cost <= active_stats.CurComp: isValid = true
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
	var s : String = statusKeys[effect.sub_type].to_pascal_case()
	status[s] = true
	if sParam.has(s) and !sParam[s].curable:
		sParam[s].duration = effect.duration
	else:
		sParam[s] = {"Duration":effect.duration, "Curable":effect.curable, "DurationType":effect.duration_type}
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
			#print(unit_id,":", _animPlayer.current_animation,"Set Acted")
		true: 
			if one_time_leash and leash > -1: leash = -1
			_animPlayer.play("disabled")
			status_duration_tick(Enums.DURATION_TYPE.TURN)
			#print(unit_id,":", _animPlayer.current_animation,"Set Acted")

#Turn Signals
func _on_turn_changed():
	update_stats()
	
	
func _on_new_round(_to):
	status_duration_tick(Enums.DURATION_TYPE.ROUND)


#func _on_turn_changed():
	#status_duration_tick(Enums.DURATION_TYPE.TURN)
	
#DEATH
func run_death():
	#if FACTION_ID != FACTION_ID.PLAYER:
		#unitData.erase(unit_id)
#	emit_signal("imdead", self)
	SignalTower.unit_death.emit(self)
	fade_out(1.0)


func fade_out(duration: float):
	needDeath = true
	deployment = Enums.DEPLOYMENT.GRAVEYARD
	_animPlayer.play("death")
	await get_tree().create_timer(duration).timeout
	$PathFollow2D/Sprite/HPbar.visible = false
	#confirm_post_sequence_flags("Death")
	death_done.emit(self)
	bars_updated.emit(self)


func update_terrain_data():
	terrainTags = map.get_terrain_tags(cell)


func update_terrain_bonus() -> Dictionary:
#	print(combatData.Graze)
	var tVal := {"GrzBonus": 0, "DefBonus": 0, "PwrBonus": 0, "MagBonus": 0, "HitBonus": 0,}
	var terrainData = PlayerData.terrainData
	if !is_active or move_type == Enums.MOVE_TYPE.FLY: return tVal
	
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


func _on_animation_player_animation_finished(animName):
	match animName:
		"pick":
			revert_animation()
			animation_complete.emit(self)
		"use_item":
			revert_animation()
			animation_complete.emit(self)


func add_exp(action, _target = null): ##Adds exp if a unit is a place, as well as returning 'true', returns 'false' if not a player unit.
	if FACTION_ID != Enums.FACTION_ID.PLAYER:
		return false
	var xpVal := 0
	var results
	var oldStats :Dictionary
	var oldLevel := unit_level
	#var targetLevel
	var oldExp := unit_exp
	var expSteps := []
	var portrait :String= artPaths.Prt
	var lvlLoops := 0
	var levelUpReport := {}
	for stat in base_stats.keys():
		oldStats[stat] = active_stats[stat]
	#if target != null:
		#targetLevel = target.unit_level
#	print(unit_exp)
	match action:
		"Kill": xpVal = 150
		"Support": xpVal = 60
		"Generic": xpVal = 60
	unit_exp += xpVal
	print("[%s]:Adding EXP(%s/%s)" % [unit_id,action,xpVal])
#	print(unit_exp)
	if unit_exp <= 100:
		expSteps.append(unit_exp) 
		
	if unit_exp >= 100 and unit_level < 20:
		var expBracket = unit_exp
		while expBracket > 100:
			expSteps.append(100)
			expBracket -= 100
			
			if expBracket < 100:
				expSteps.append(expBracket)
		
		while unit_exp > 100:	
			unit_exp = unit_exp - 100
			lvlLoops += 1
			
		results = PlayerData.level_up(self, lvlLoops).duplicate()
		levelUpReport["Results"] = results.StatGains
		levelUpReport["NewSkills"]=results.NewSkills
		levelUpReport["NewPassives"]=results.NewPassives
		levelUpReport["Levels"] = lvlLoops
		levelUpReport["OldStats"] = oldStats
		levelUpReport.OldStats["LVL"] = oldLevel
#		print(unitData)
	exp_gained.emit(oldExp, expSteps, levelUpReport, portrait, unit_name)
	return true


func map_start_init():
	originCell = map.local_to_map(position) #BUG GY
	#print(originCell)
	

#region faction/group handling
func _set_faction_group(faction:Enums.FACTION_ID)->void:
	var fString:=""
	remove_from_group("ENEMY")
	remove_from_group("NPC")
	remove_from_group("PLAYER")
	match faction:
		Enums.FACTION_ID.PLAYER: 
			fString = "PLAYER"
		Enums.FACTION_ID.ENEMY: 
			fString = "ENEMY"
		Enums.FACTION_ID.NPC: 
			fString = "NPC"
	add_to_group(fString)
