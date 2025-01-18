extends Node2D

signal pop_up_requested
signal target_fx_requested
signal animation_complete
signal animation_start
signal animation_end

const TEXT_POP_PATH = preload("res://scenes/animations/combat/fx/gen/fx_pop_up.tscn")
const GRAZE_PATH = preload("res://scenes/animations/combat/fx/gen/fx_graze.tscn")
const PASSIVE_PATH = preload("res://scenes/animations/combat/fx/gen/passive_cut_in.tscn")
const SKILL_NAME_PATH = preload("res://scenes/animations/combat/fx/skill/fx_skill_name.tscn")
const ANIM_DATA = preload("res://character_data/anim_data/anim_data.gd")
#var animData = ANIM_DATA.WEAPON_ANIM

@onready var combatPlayer = $CombatPlayer

var ACTION_TYPE = Enums.ACTION_TYPE
var unit : Unit
var activeAnim : String = ""
var effectQueue := []
var dead := false
var isFlipped := false

var targetFxArray = []
var passiveQue = []
var targetFxQue = []
var effectQue = []
var weaponFx : FxPlayer
var skillFx : FxPlayer
var skillNameFx : SkillCutIn
var isHit = false

var grazeFx : FxPlayer
var popUp : PopText

func _ready():
	combatPlayer.play("Entry")
	combatPlayer.queue("Idle")
	
	
func set_unit(newUnit : Unit):
	unit = newUnit
	
	
func assign_action(hit, actionType, skillId = false):
	var sData = UnitData.skillData
	isHit = hit
	match actionType:
		ACTION_TYPE.WEAPON: _assign_attack_animation()
		ACTION_TYPE.FRIENDLY_SKILL: _assign_skill_animation(skillId)
		ACTION_TYPE.HOSTILE_SKILL: 
			if sData[skillId].Augment:
				_assign_attack_animation()
			else:
				_assign_skill_animation(skillId)


func assign_defend(isHit, dmg, crit, graze):
	var chest = $CombatSkeleton/ChestFx
	if crit and graze:
		_add_graze_fx()
		_add_crit_fx()
		var grazePop = TEXT_POP_PATH.instantiate()
		grazePop.set_value(dmg)
		grazePop.set_stylized_string("critical_graze")
		chest.add_child(grazePop)
		popUp = grazePop
	elif graze:
		var grazePop = TEXT_POP_PATH.instantiate()
		_add_graze_fx()
		grazePop.set_value(dmg)
		grazePop.set_stylized_string("graze")
		chest.add_child(grazePop)
		popUp = grazePop
	elif crit:
		var dmgPop = TEXT_POP_PATH.instantiate()
		_add_crit_fx()
		dmgPop.set_value(dmg)
		dmgPop.set_stylized_string("crit")
		chest.add_child(dmgPop)
		popUp = dmgPop
	elif isHit:
		var dmgPop = TEXT_POP_PATH.instantiate()
		dmgPop.set_value(dmg)
		dmgPop.set_stylized_string("damage")
		chest.add_child(dmgPop)
		popUp = dmgPop
	else:
		var dmgPop = TEXT_POP_PATH.instantiate()
		dmgPop.set_stylized_string("dodge")
		chest.add_child(dmgPop)
		popUp = dmgPop
	if isFlipped:
		popUp.set_scale(Vector2(-1,1))
	activeAnim = "Defend"
	
	
func _assign_attack_animation():
	var iData =  UnitData.itemData
	var weapon = unit.get_equipped_weapon()
	var variant : String = iData[weapon.ID].Category.to_pascal_case()
	var default := "Attack"
	var list = combatPlayer.get_animation_list()
	var animation := "Attack_%s" % [variant]
	
	if list.has(animation):
		activeAnim = animation
	else:
		activeAnim = default
	add_weapon_fx(weapon.ID)
	
	
		
func _assign_skill_animation(skillId):
	var variant : String = skillId.to_pascal_case()
	var default := "Cast"
	var list = combatPlayer.get_animation_list()
	var animation := "Cast_%s" % [variant]
	
	if list.has(animation):
		activeAnim = animation
	else:
		activeAnim = default
		
	combatPlayer.play(activeAnim)
	
	
func set_if_death(isDead):
	dead = isDead
	

func reset_action():
	activeAnim = "Idle"
	combatPlayer.play(activeAnim)

func reset_defense():
	if dead:
		activeAnim = "Death"
	else:
		activeAnim = "Idle"
	combatPlayer.play(activeAnim)
	
func reset_variables():
	weaponFx = null
	skillFx = null
	skillNameFx = null
	grazeFx = null
	popUp = null
	effectQue = []
	targetFxArray = []
	passiveQue = []
	targetFxQue = []


#func play_animation_queue():
	#var first = animationQue.pop_front()
	#combatPlayer.play(first)
	#for anim in animationQue:
		#combatPlayer.queue(anim)

func flip_animation():
	self.set_scale(Vector2(-1, 1))
	isFlipped = true

func play_animation():
	emit_signal("animation_start")
	combatPlayer.play(activeAnim)
	
func play_pop_up():
	if popUp:
		popUp.play_action()
	if grazeFx:
		grazeFx.play_action()
	
func play_target_fx():
	if targetFxQue.size() > 0:
		for targetFx in targetFxQue:
			targetFx.play_action()
	else:
		emit_signal("animation_end")


func add_skill_fx(skillId):
	var attackBone = $CombatSkeleton/AttackFx
	var skillFxPath
	#var skillAnim = ANIM_DATA.get_skill_anim()
	skillNameFx = SKILL_NAME_PATH.instantiate()
	var bone = $CombatSkeleton/SkillNameFx
	
	skillNameFx.set_skill_style(skillId)
	bone.add_child(skillNameFx)
		
	if ANIM_DATA.SKILL_ANIM.has(skillId):
		if isHit:
			var fxGroup = {"TargetFx": ANIM_DATA.SKILL_ANIM[skillId].TargetFx, 
			"FxBone": ANIM_DATA.SKILL_ANIM[skillId].FxBone}
			targetFxArray.append(fxGroup)
		
		skillFxPath = ANIM_DATA.SKILL_ANIM[skillId].SkillFx
		skillFx = load(skillFxPath).instantiate()
	else:
		if isHit:
			var fxGroup = {"TargetFx": "res://scenes/animations/combat/fx/weapon/fx_target_knife.tscn", 
			"FxBone": "Head"}
			targetFxArray.append(fxGroup)
		
		skillFx = load("res://scenes/animations/combat/fx/weapon/fx_self_knife.tscn").instantiate()
		

	#if isFlipped:
		#skillNameFx.flip_text()
		#skillFx.set_scale(Vector2(-1,1))
	skillFx.connect_signal(self)
	attackBone.add_child(skillFx)
	
	
func add_weapon_fx(weaponId):
	var attackBone = $CombatSkeleton/AttackFx
	var weaponFxPath

	
	if ANIM_DATA.WEAPON_ANIM.has(weaponId):
		if isHit:
			var fxGroup = {"TargetFx": ANIM_DATA.WEAPON_ANIM[weaponId].TargetFx, 
			"FxBone": ANIM_DATA.WEAPON_ANIM[weaponId].FxBone}
			targetFxArray.append(fxGroup)
		weaponFxPath = ANIM_DATA.WEAPON_ANIM[weaponId].WeaponFx
		weaponFx = load(weaponFxPath).instantiate()
		
	else:
		if isHit:
			var fxGroup = {"TargetFx": "res://scenes/animations/combat/fx/weapon/fx_target_knife.tscn", 
			"FxBone": "Head"}
			targetFxArray.append(fxGroup)
		
		weaponFx = load("res://scenes/animations/combat/fx/weapon/fx_self_knife.tscn").instantiate()
		
		
		

	#if isFlipped:
		#weaponFx.set_scale(Vector2(-1,1))
	if !skillFx:
		weaponFx.connect_signal(self)
	attackBone.add_child(weaponFx)
	
func add_target_fx(targetFxs:Array):
	var bone 
	for fx in targetFxs:
		var targetFx = load(fx.TargetFx).instantiate()
		#if isFlipped:
			#targetFx.set_scale(Vector2(-1,1))
		match fx.FxBone:
			"Target": bone = $CombatSkeleton/TargetFx
			"Head": bone = $CombatSkeleton/HeadFx
			"Chest": bone = $CombatSkeleton/ChestFx
		bone.add_child(targetFx)
		targetFxQue.append(targetFx)
	if targetFxQue.size() > 0:
		targetFxQue[-1].connect_signal(self)
	
func add_passive_cut_in(passiveArray):
	for passiveId in passiveArray:
		var passiveCutIn = PASSIVE_PATH.instantiate()
		var container = $PassiveCutInContainer
		if isFlipped:
				passiveCutIn.flip_text()
		passiveCutIn.set_passive_style(passiveId)
		passiveQue.append(passiveCutIn)
		container.add_child(passiveCutIn)
	if passiveQue.size() > 0:
		passiveQue[-1].connect_signal(self)


func _add_graze_fx():
	var chest = $CombatSkeleton/ChestFx
	grazeFx = GRAZE_PATH.instantiate()
	chest.add_child(grazeFx)
	
	
func _add_crit_fx():
	pass
	
func queue_instant_cut_in(instants):
	pass
	
func load_effect_result(effect : Dictionary):
	var bone = $CombatSkeleton/HeadFx
	var effectText = TEXT_POP_PATH.instantiate()
	effectText.set_effect_result(effect)
	effectQue.append(effectText)
	bone.add_child(effectText)

func stop_all():
	combatPlayer.stop()
	if popUp:
		popUp.end_all()
		

func _on_cut_in_finished(_anim_name):
	emit_signal("animation_end")


func _on_fx_animation_finished(_anim_name):
	emit_signal("animation_end")
	

func _on_pop_up_finished(_anim_name):
	emit_signal("animation_end")

func play_passive_que():
	var tween = get_tree().create_tween()
	var delay = 0.1
	if passiveQue.size() > 0:
		emit_signal("animation_start")
	for passive in passiveQue:
		tween.tween_callback(_tween_play.bind(passive)).set_delay(delay)
		delay += 0.3

func play_effects_que():
	var tween = get_tree().create_tween()
	var delay = 0.1
	if effectQue.size() > 0:
		emit_signal("animation_start")
		effectQue[-1].connect_signal(self)
	for effect in effectQue:
		tween.tween_callback(_tween_play.bind(effect)).set_delay(delay)
		delay += 0.3

func skip_animations():
	emit_signal("animation_complete", true)
		
		
func _tween_play(player):
	player.play_action()
		
	
##Animation call functions
func target_pop_up_request():
	emit_signal("pop_up_requested", unit)
	
	
func target_fx_request():
	emit_signal("target_fx_requested", unit)
	
	
func play_self_fx():
	if skillFx:
		skillNameFx.play_action()
		skillFx.play_action()
	elif weaponFx:
		weaponFx.play_action()
	
