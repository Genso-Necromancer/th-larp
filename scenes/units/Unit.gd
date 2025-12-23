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
@export var _move_type:Enums.MOVE_TYPE
var move_type:Enums.MOVE_TYPE = _move_type
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
var sParam:Dictionary= {}
var status_data : Dictionary = {}

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
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
var current_comp:int = 1

var remaining_move:int = 0
#de/buffs applied to unit
#var active_buffs :Dictionary[String,Dictionary]= {}
#var active_debuffs :Dictionary[String,Dictionary]= {}
##var active_item_effects := []

#Stats and derivatives
var base_stats_final:Dictionary
var stat_mod_breakdown:Dictionary
var active_stats :={}
var combat_bonus_breakdown:Dictionary
#Call for pre-formualted combat stats
var base_combat := {}
var combat_data := {"Dmg": 0, "Hit": 0, "Graze": 0, "Barrier": 0, "BarPrc": 0, "Crit": 0, "Luck": 0, "Resist": 0, "EffHit":0, "DRes": 0, "Type":Enums.DAMAGE_TYPE.PHYS, "CanMiss": true}
#art asset paths
@onready var _anim_player: AnimationPlayer = %AnimationPlayer:
	set(value):
		_anim_player = value
		_anim_player.play("idle")
var artPaths:Dictionary = {"Sprite":"","Prt":"","FullPrt":""}
var persistant_data : Dictionary
var killer : Unit
#queueing
var life_updated:bool = false
#AI support
var threats:Array=[]

#endregion
#unit base data

var firstLoad := false
var tick = 1
var needDeath := false
var deathFlag := false

var terrainTags: Dictionary = {"BaseType": "", "ModType": "", "BaseId": "", "ModId": "", "Locked": false}
var postSequenceFlags := {"Bars":false, "Death":false}



#equip variables
#var natural  : Dictionary = {"ID": "NONE", "Equip": false, "Dur": -1, "Broken": false}
#var unarmed := {"ID": "NONE", "Equip": false, "Dur": -1, "Broken": false}
var tempSet = false
var isAmbushing := false

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
			_anim_player.play("selected")
			#print(unit_id,":", _anim_player.current_animation,":","Selected")
		elif status.Acted == false:
			_anim_player.play("idle")
			#print(unit_id,":", _anim_player.current_animation,"Selected")
		elif status.Acted == true:
			_anim_player.play("disabled")
			#print(unit_id,":", _anim_player.current_animation,"Selected")
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

#Unit Modules
var stats_block : StatsBlock
var equipment_helper: EquipmentHelper
var buff_controller: BuffController
var status_controller : StatusController
var aura_controller : AuraController

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
	stats_block.update_stats()
	if simulate_leveling: _simulate_levels()
	current_life = active_stats.Life
	current_comp = active_stats.Comp
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
		stats_block.update_stats()
	else: return
#endregion

func _init():
	#New Modularization code
	stats_block = StatsBlock.new(self)
	buff_controller = BuffController.new(self)
	equipment_helper = EquipmentHelper.new(self)
	status_controller = StatusController.new(self)
	aura_controller = AuraController.new(self)

func _ready() -> void:
	var hitBox = $PathFollow2D/Sprite/UnitArea
	_generate_base_stats()
	_initialize_parameters()
	set_equipped()
	_load_sprites()
	hitBox.set_master(self)
	hitBox.area_entered.connect(self.on_aura_entered)
	hitBox.area_exited.connect(self.on_aura_exited)
	unit_relocated.connect(self._on_unit_relocated)
	_anim_player.play("idle")
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
	var saveParam = data_to_dict()
	return saveParam


func data_to_dict()->Dictionary:
	var RC:= ResourceConverter.new()
	var inventoryConvert := RC.resources_to_save_data(inventory)
	var naturalConvert :Dictionary = {}
	if natural: naturalConvert = natural.convert_to_save_data()
	var bonusSkills := RC.resources_to_save_data(bonus_skills)
	var personalSkills := RC.resources_to_save_data(personal_skills)
	var bonusPassives := RC.resources_to_save_data(bonus_passives)
	var personalPassives := RC.resources_to_save_data(personal_passives)
	var activeBuffs := RC.effects_to_save_data(buff_controller.active_buffs)
	var activeDebuffs := RC.effects_to_save_data(buff_controller.active_debuffs)
	var combatDup:Dictionary
	combatDup = combat_data.duplicate(true)
	var dict :Dictionary ={
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
		"skills" = skills,
		"base_skills" = base_skills,
		"personal_skills" = personalSkills,
		"bonus_skills" = bonusSkills,
		"passives" = passives,
		"base_passives" = base_passives,
		"personal_passives" = personalPassives,
		"bonus_passives" = bonusPassives,
		"status" = status,
		#"active_auras" = active_auras, #Not good to do it this way. Need to put a check in _ready() to see if they are within any auras when loaded in
		"active_item_effects" = equipment_helper.equipped_effects,
		"active_buffs" = activeBuffs,
		"active_debuffs" = activeDebuffs,
		"current_life" = current_life,
		"current_comp" = current_comp,
		"combat_data" = combat_data,
		"natural" = naturalConvert,
		"inventory" = inventoryConvert,
		"SPEC_ID" = SPEC_ID,
		"ROLE_ID" = ROLE_ID,
		"move_type" = move_type,
	}
	return dict

func to_sim() -> UnitSim:
	var sim = UnitSim.new()
	var RC:= ResourceConverter.new()
	var bonusSkills := RC.resources_to_save_data(bonus_skills)
	var personalSkills := RC.resources_to_save_data(personal_skills)
	var bonusPassives := RC.resources_to_save_data(bonus_passives)
	var personalPassives := RC.resources_to_save_data(personal_passives)
	var activeBuffs := RC.effects_to_save_data(buff_controller.active_buffs)
	var activeDebuffs := RC.effects_to_save_data(buff_controller.active_debuffs)
	sim.id = unit_id
	sim.team = FACTION_ID
	sim.cell = cell
	sim.hp = current_life
	sim.comp = current_comp
	sim.total_stats = total_stats.duplicate(true)
	sim.active_stats = active_stats.duplicate(true)
	sim.status = status.duplicate(true)
	sim.status_data = status_data.duplicate(true)
	sim.passives = RC.resources_to_save_data(passives).duplicate(true)
	sim.skills = RC.resources_to_save_data(skills).duplicate(true)
	sim.inventory = RC.resources_to_save_data(inventory).duplicate(true)
	sim.weapon = get_equipped_weapon().convert_to_save_data().duplicate(true)
	if natural: sim.natural = natural.convert_to_save_data().duplicate(true)
	sim.threats = threats.duplicate()
	sim.move_type = move_type
	sim.terrain_tags = terrainTags.duplicate(true)
	return sim


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
	current_life = int(unit_data.current_life)
	current_comp = int(unit_data.current_comp)
	status = unit_data.status
	#active_item_effects = unit_data.active_item_effects
	_load_buff_effects(unit_data.active_buffs,buff_controller.active_buffs)
	_load_buff_effects(unit_data.active_debuffs,buff_controller.active_debuffs)
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
	
	
		_anim_player.play(str(directions[direction_id]))
		
		
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
	lastAnim = _anim_player.current_animation
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
	
	lastAnim = _anim_player.current_animation
	
	if cell > location:
		_anim_player.play("shoved_left")
	else:
		_anim_player.play("shoved_right")
	
	#print("Shoved: ", _anim_player.current_animation)
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
	lastAnim = _anim_player.current_animation
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
	lastAnim = _anim_player.current_animation
	_anim_player.play(anim)


func revert_animation():
	if _anim_player.current_animation == lastAnim:
		return
	#print(lastAnim, " surely I will return to idle")
	_anim_player.play(lastAnim)
	#print(unit_id,":", _anim_player.current_animation,"Revert")


func toggle_path_pause():
	pathPaused = !pathPaused


func return_original():
	position = map.map_to_local(originCell)
	cell = originCell
	#print(originCell, cell)
	return cell


#region buff functions
func set_buff(effect: Effect) -> void:
	buff_controller.apply_effect(effect)

func remove_buff(effect: Effect) -> void:
	buff_controller.remove_effect(effect)

func tick_buffs(duration_type: Enums.DURATION_TYPE) -> void:
	buff_controller.tick(duration_type)
#endregion


#region status functions
func set_status(effect: Effect) -> void:
	status_controller.apply_from_effect(effect)


func cure_status(cure_type: Enums.SUB_TYPE, ignoreCurable := false) -> void:
	status_controller.cure_status(cure_type, ignoreCurable)


func status_duration_tick(duration: Enums.DURATION_TYPE) -> void:
	status_controller.tick(duration)


func check_status(condition: String) -> bool:
	return status_controller.has_status(condition)
#endregion

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
	#_anim_player.play("idle")
	#print("MODULATION:",get_self_modulate())
	#print(unit_id,":", _anim_player.current_animation,"Load Sprite")


func get_condition() -> Dictionary: #maybe expand this in the future, for now that's all
	var c: Dictionary = {}
	c["Hp%"] = (current_life / active_stats.Life) * 100
	c["Comp"] = current_comp
	c["Status"] = status.duplicate(true)
	return c

func can_act() -> bool:
	if current_life <= 0 or status.Sleep or get_equipped_weapon() == unarmed:
		return false
	return true


#region Passive Functions
func check_passives() -> void:
	if passives.is_empty():
		aura_controller.validate_auras([])
		return

	var valid_auras : Array[Aura] = []

	for p in passives:
		if p == null:
			continue

		match p.type:
			Enums.PASSIVE_TYPE.AURA:
				var aura := _resolve_passive_aura(p)
				if aura:
					valid_auras.append(aura)
					aura_controller.load_owned_aura(aura)
			Enums.PASSIVE_TYPE.SUB_WEAPON:
				_add_sub_weap(p.sub_weapon)
				_update_natural(p)

func _resolve_passive_aura(passive: Passive) -> Aura:
	match passive.rule_type:
		Enums.RULE_TYPE.MORPH:
			return passive[Enums.TIME.keys()[Global.time_of_day].to_lower()]

		Enums.RULE_TYPE.TIME:
			if passive.rule == Global.time_of_day:
				return passive.aura
			return null

		_:
			return passive.aura

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
	for effect in equipment_helper.equipped_effects:
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
	if !aura_controller.active_auras.has(aura):load_aura(aura)
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


#region Aura Functions
func validate_auras(auras:Array[Aura]):
	aura_controller.validate_auras(auras)


func remove_aura(a:Aura):
	aura_controller.remove_owned_aura(a)


func load_aura(aura:Aura):
	aura_controller.load_owned_aura(aura)


func get_visual_aura_range() -> int:
	return aura_controller.get_visual_aura_range()
	
#endregion

#region aura signals

#func _on_self_aura_entered(area:AuraArea,):
	#aura_controller.on_self_aura_enter(area)
#
#func _on_self_aura_exited(area:AuraArea,):
	#aura_controller.on_self_aura_exit(area)


#func _on_self_aura_entered(area:AuraArea):
	##print("on_self_aura_entered: ", area.master)
	#if not is_aura_applicable(area): return
	#
	#if area.aura.target == Enums.EFFECT_TARGET.SELF:
		#aura_controller.on_aura_enter(area)
		##if !active_auras.has(area):
			##active_auras[area] = area.aura.effects.duplicate()
		##else: 
			##for effect in area.aura.effects:
				##if effect.stack:
					##active_auras[area].append(effect)
	#
	#
	#stats_block.update_stats()
	##print("Active Aura Effects: ", active_auras)
		#
#
#func _on_self_aura_exited(area:AuraArea):
	##print("on_self_aura_exited: ", area.master)
	#aura_controller.on_aura_enter(area)
	##print("Active Aura Effects: ", active_auras)
	#stats_block.update_stats()


func _on_aura_entered(area : AuraArea) -> void:
	if not is_aura_applicable(area): return
	aura_controller.on_aura_enter(area)
	if area.aura.target == Enums.EFFECT_TARGET.SELF:
		area.master.aura_controller.on_aura_trigger_enter(area.aura,self)
	update_stats()

func _on_aura_exited(area : AuraArea) -> void:
	aura_controller.on_aura_exit(area)
	if area.aura.target == Enums.EFFECT_TARGET.SELF:
		area.master.aura_controller.on_aura_trigger_exit(area.aura, self)
	update_stats()

func is_aura_applicable(area: AuraArea) -> bool:
	if area == null or area.aura == null:
		return false

	var aura := area.aura
	var source := area.master

	match aura.target_team:
		Enums.TARGET_TEAM.ALLY:
			# NPC ally edge case preserved
			if source.FACTION_ID != Enums.FACTION_ID.ENEMY and FACTION_ID == Enums.FACTION_ID.NPC:
				return true
			return source.FACTION_ID == FACTION_ID

		Enums.TARGET_TEAM.ENEMY:
			return source.FACTION_ID != FACTION_ID

		Enums.TARGET_TEAM.NONE:
			return true

	return false
#endregion



#func _on_aura_entered(area):
	##print("Aura Entered: ", area)
	#if !area.aura:
		#return
	#
	#match area.aura.target_team:
		#Enums.TARGET_TEAM.ALLY:
			#if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and FACTION_ID == Enums.FACTION_ID.NPC:
				#pass
			#elif area.master.FACTION_ID != FACTION_ID:
				#return
		#Enums.TARGET_TEAM.ENEMY:
			#if area.master.FACTION_ID == FACTION_ID:
				#return
	#
	#if area.aura.target == Enums.EFFECT_TARGET.SELF:
		#return
	#elif !active_auras.has(area):
		#active_auras[area] = area.aura.effects.duplicate()
	#stats_block.update_stats()
#
#
#func _on_aura_exited(area):
	##print("Aura Exited: ", area)
	#if active_auras.has(area):
		#active_auras.erase(area)
		##print("Active Aura Effects: ", active_auras)
	#stats_block.update_stats()
#



#region Equipment functions
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

##searches for first valid weapon if false, otherwise unequips current and equips the passed Item
func set_equipped(item: Item = null, is_temp := false) -> void:
	equipment_helper.set_equipped(item, is_temp)

func unequip(item: Item, as_command := false) -> void:
	equipment_helper.unequip(item, as_command)

func restore_equip() -> void:
	equipment_helper.restore_temp_weapon()

func check_valid_equip(item: Item) -> bool:
	return equipment_helper.check_valid_equip(item)

func is_proficient(cat, sub) -> bool:
	return equipment_helper.is_proficient(cat, sub)
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
	_anim_player.play("use_item")
	

#func end_item_use():
	#_anim_player.play("idle")



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
	for effect in equipment_helper.equipped_effects:
		if effect.type == Enums.EFFECT_TYPE.MULTI_SWING and effect.value > swings:
			swings = effect.value
	if swings == 0:
		return false
	else:
		return swings


func get_multi_round():
	var rounds : int = 0
	for effect in equipment_helper.equipped_effects:
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
	
	for effect in equipment_helper.equipped_effects:
		if effect.type == Enums.EFFECT_TYPE.CRIT_BUFF and effect["CritDmg"]:
			dmgStack[0] += effect["CritDmg"][0]
			dmgStack[1] += effect["CritDmg"][1]
			effects.CritDmg = dmgStack
		if effect.type == Enums.EFFECT_TYPE.CRIT_BUFF and effect["CritMulti"] and effect["CritMulti"] > highest:
			highest = effect["CritMulti"]
			effects.crit_multi = highest
			
	return effects


func get_skill_combat_stats(skill:SlotWrapper, augmented := false):
	var stats = combat_data.duplicate()
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


func update_stats():
	if stats_block: stats_block.update_stats()


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


func update_sprite() -> void:
	if !_anim_player: return
	for condition in status:
		if status[condition]:
			if condition == "Sleep" or condition == "Acted":
				_anim_player.play("disabled")
				#print(unit_id,":", _anim_player.current_animation,"Update Sprite")
				return
	if !isWalking and !isShoved and !needDeath and !isSelected:
		_anim_player.play("idle")
		#print(unit_id,":", _anim_player.current_animation,"Update Sprite")
		
		
func check_death():
	if current_life <= 0:
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
	tween.tween_property($PathFollow2D/Sprite/HPbar, "value", current_life, 0.5)


func process_bars():
	update_life_bar()


func _life_tween_finished():
	if !check_death(): update_composure_bar()
	#confirm_post_sequence_flags("Bars")


func update_composure_bar():
	if current_comp <= 0:
		pass #comp check!
	_comp_tween_finished()


func _comp_tween_finished():
	revert_animation()
	check_break()


func pick_door(door:DoorTile):
	
	_anim_player.play("pick")
	await animation_complete
	door.unlock()


func apply_dmg(dmg : int, source : Unit = null):
	current_life -= dmg
	current_life = clampi(current_life, 0, active_stats.Life)
	if current_life == 0:
		if source: killer = source
		deathFlag = true
	if dmg > 0:
		hp_changed = 0 - dmg
		
	status_controller.on_damage_taken(dmg)
	stats_block.update_stats()


func apply_heal(heal := 0):
	if heal > 0: 
		hp_changed = heal
		current_life += heal
		current_life = clampi(current_life, 0, active_stats.Life)
		stats_block.update_stats()



func apply_composure(comp := 0):
	if comp>0 or comp<0: 
		comp_changed = comp
		current_comp -= comp
		current_comp = clampi(current_comp, 0, active_stats.Comp)
		stats_block.update_stats()

func has_enough_comp(cost:int) -> bool:
	var isValid := false
	if cost <= current_comp: isValid = true
	return isValid

func set_acted(actState: bool):
	status_controller.set_acted(actState)

#Turn Signals
func _on_turn_changed():
	status_duration_tick(Enums.DURATION_TYPE.TURN)
	update_stats()
	
	
func _on_new_round(_to):
	status_duration_tick(Enums.DURATION_TYPE.ROUND)
	update_stats()
	
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
	_anim_player.play("death")
	await get_tree().create_timer(duration).timeout
	$PathFollow2D/Sprite/HPbar.visible = false
	#confirm_post_sequence_flags("Death")
	death_done.emit(self)
	bars_updated.emit(self)


func update_terrain_data():
	terrainTags = map.get_terrain_tags(cell)


func get_terrain_bonus() -> Dictionary:
	var tVal :={"GrzBonus": 0, "DefBonus": 0, "PwrBonus": 0, "MagBonus": 0, "HitBonus": 0,}
	if !is_active or move_type == Enums.MOVE_TYPE.FLY or !map: return tVal
	else: tVal = map.get_terrain_values(cell)
	return tVal


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

#region self signals
func _on_unit_relocated():
	update_threats()


#region ai helpers
func get_threats(set_cell:Vector2i=cell)->Array:
	var newThreats:=[]
	var aHex := AHexGrid2D.new(map)
	var range:= get_weapon_reach()
	var walkable := aHex.find_all_unit_paths(self,cell)
	newThreats = aHex.find_threat(walkable,range)
	return newThreats
#endregion

#region UI helpers
func get_stat(stat: String) -> int:
	return active_stats.get(stat, 0)

func get_base_stat(stat: String) -> int:
	return base_stats_final.get(stat, 0)

func get_stat_bonus(stat: String) -> int:
	return active_stats.get(stat, 0) - base_stats_final.get(stat, 0)

func get_stat_breakdown(stat: String) -> Dictionary:
	var result := {}

	for group in stat_mod_breakdown.keys():
		var mods = stat_mod_breakdown[group]
		if mods.has(stat):
			result[group] = mods[stat]

	return result

func get_combat_breakdown(key: String)->Dictionary:
	return {
		"base": base_combat.get(key),
		"bonus": combat_bonus_breakdown.get(key),
		"final": combat_data.get(key)
	}
#endregion

func update_threats(): threats = get_threats()
func get_simulated_threats(sim_cell:Vector2i)->Array: return get_threats(sim_cell)
