# Unit.gd
# The refactored node. Keeps all exports for designer workflow but delegates logic to UnitData.
@tool
class_name Unit2
extends Path2D

signal walk_finished
signal exp_handled
signal death_done(unit)
signal unit_relocated
signal exp_gained
signal leveled_up
signal post_complete
signal turn_complete(unit)
signal effect_complete
signal unit_ready(unit)
signal item_targeting(item, unit)
signal item_activated(item, unit, target)
signal animation_complete(unit)
signal bars_updated(unit)

enum AI_TYPE {
	NONE,
	DEFENDER,
	OFFENDER,
	SUPPORT,
	BOSS
}
# ----------------------------
# Editor-exposed fields (kept for designers)
# ----------------------------
@export var unit_id := ""
@export var disabled := false:
	get:
		return disabled
	set(v):
		disabled = v
		set_process(!v)
@export var recruited := false
@export var unit_name := ""
@export var FACTION_ID : int = 0
@export var SPEC_ID :Enums.SPEC_ID
@export var ROLE_ID :Enums.ROLE_ID
@export var move_type :Enums.MOVE_TYPE

@export var is_active := true
@export var isBoss : bool = false
@export var isMidBoss : bool = false
@export var archetype :AI_TYPE
@export var leash : int = -1
@export var one_time_leash: bool = false

@export var moveSpeed := 200.0
@export var shoveSpeed := 350.0
@export var tossSpeed := 350.0

# Stat exports (preserve the exact shape designers expect)
@export var base_growth: Dictionary = {"Move":0.0,"Life":0.0,"Comp":0.0,"Pwr":0.0,"Mag":0.0,"Eleg":0.0,"Cele":0.0,"Def":0.0,"Cha":0.0}
@export var base_stats: Dictionary = {"Move":0,"Life":1,"Comp":0,"Pwr":0,"Mag":0,"Eleg":0,"Cele":0,"Def":0,"Cha":0}
@export var base_caps: Dictionary = {"Move":0,"Life":0,"Comp":0,"Pwr":0,"Mag":0,"Eleg":0,"Cele":0,"Def":0,"Cha":0}
@export var mod_growth: Dictionary = {}
@export var mod_stats: Dictionary = {}
@export var mod_caps: Dictionary = {}

@export var total_growth: Dictionary = {}
@export var total_stats: Dictionary = {}
@export var total_caps: Dictionary = {}

# Inventory & equipment (designer-friendly)
@export var inventory: Array = []
@export var natural :Natural
@export var weapon_prof: Dictionary = {"Blade":false,"Blunt":false,"Stick":false,"Book":false,"Gohei":false,"Ofuda":false,"Bow":false,"Gun":false,"Sub":false}
@export var max_inv: int = 0

# Skills & passives (Designer-facing)
@export var personal_skills: Array[Skill] = []
@export var personal_passives: Array[Passive] = []
@export var base_skills: Array[Skill] = []
@export var base_passives: Array[Passive] = []
@export var bonus_skills: Array[Skill] = []
@export var bonus_passives: Array[Passive] = []
@export var skills: Array[Skill] = []
@export var passives: Array[Passive] = []
@export var leveled_skills :Dictionary[int,Skill]= {}
@export var leveled_passives :Dictionary[int,Passive]= {}

# Conditions & runtime inspector-only data (we keep them exported to preserve current UX)
@export var status: Dictionary = {"Acted": false, "Sleep": false}
@export var active_buffs: Dictionary = {}
@export var active_debuffs: Dictionary = {}
@export var active_auras := {}
@export var active_item_effects := []

# Visual nodes (onready)
@onready var _sprite := $PathFollow2D/Sprite
@onready var _animPlayer := $PathFollow2D/AnimationPlayer
@onready var lifeBar := $PathFollow2D/Sprite/HPbar
@onready var _pathFollow := $PathFollow2D

# The pure-data model
var data: UnitData = UnitData.new()

# ----------------------------
# Node lifecycle
# ----------------------------
func _ready() -> void:
	# Build UnitData from this exported data
	data.build_from_node(self)
	# Connect signals, initialize visuals, play idle
	_animPlayer.play("idle")
	# Sync visuals with data
	_update_visuals_from_data(true)
	unit_ready.emit(self)
	# If you rely on the old on_unit_relocated signal, keep it connected
	unit_relocated.connect(_on_unit_relocated)
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
		#_set_unit_name()

func _process(delta: float) -> void:
	if disabled: return
	# movement/animation processing still handled in node for visuals
	# animations and path-follow operate unchanged
	_process_motion(delta)

# ----------------------------
# Visual helpers & small compatibility shims
# ----------------------------
func _update_visuals_from_data(force := false) -> void:
	# Update life bar etc from data
	var life_max := data.stats.get("Life")
	var cur := data.active_stats.get("CurLife", data.stats.get("Life"))
	if lifeBar:
		lifeBar.max_value = life_max
		lifeBar.value = cur
	emit_signal("bars_updated", self)

func apply_dmg(dmg: int, source: Unit = null) -> void:
	# Forward to data then update visuals & emit signals similar to old implementation
	data.apply_damage(dmg, source.data)
	_update_visuals_from_data()
	# play hit animation if damage > 0
	if dmg > 0:
		_animPlayer.play("Hit")
	# handle death visually if needed
	if data.active_stats.get("CurLife", 0) <= 0:
		_play_death_sequence(source)

func apply_heal(heal := 0) -> void:
	data.apply_heal(heal)
	_update_visuals_from_data()
	if heal > 0:
		_animPlayer.play("heal")

func _play_death_sequence(killer: Unit = null) -> void:
	_animPlayer.play("death")
	await get_tree().create_timer(0.9).timeout
	$PathFollow2D/Sprite/HPbar.visible = false
	death_done.emit(self)
	# Let GameState / CombatManager handle unit removal / deployment changes

func set_equipped(item) -> void:
	# Designers may pass Resource or id; delegate to data
	data.set_equipped(item)
	recompute_and_refresh()

func restore_equip() -> void:
	# operate on runtime inventory
	for it in data.inventory:
		if typeof(it) == TYPE_DICTIONARY and it.get("temp_remove", false):
			it["temp_remove"] = false
			data.recompute_all()
			recompute_and_refresh()
			break

func recompute_and_refresh():
	data.recompute_all()
	_update_visuals_from_data()

# ----------------------------
# Movement - kept in node (visual)
# ----------------------------
var isWalking := false

func walk_along(path: PackedVector2Array, track_remaining: bool=false) -> void:
	if track_remaining:
		# old behaviour preserved for inspectors referencing total_stats
		data.active_stats["RemainingMove"] = path.size() - data.stats.get("Move")
	# build curve points and play animation
	if path.is_empty(): return
	curve.clear_points()
	curve.add_point(Vector2.ZERO)
	for p in path:
		curve.add_point(get_parent().map_to_local(p) - position)
	# set end cell in data
	data.cell = path[-1]
	isWalking = true
	_animPlayer.play("walk")

func _process_motion(delta: float) -> void:
	# copy your previous motion handling but use data.cell for position finalization
	if isWalking:
		_pathFollow.progress += moveSpeed * delta
		if _pathFollow.progress_ratio >= 1.0:
			_pathFollow.progress = 0.00001
			isWalking = false
			emit_signal("walk_finished")
			emit_signal("unit_relocated", null, data.cell, self)

# ----------------------------
# Status & buffs — forward to data and update visuals
# ----------------------------
func set_status(effect) -> void:
	# accept Resource or dictionary
	data.set_status_from_effect(effect)
	recompute_and_refresh()
	# spawn status FX if designer resources present (original code spawned animated sprite)
	# TODO: if you have fx resources, instantiate here

func cure_status(cure_type, ignore_curable = false) -> void:
	# support both enum and string keys
	# keep old API by translating cure_type if needed then call data
	# For simplicity: accept strings (existing calls appear to provide string names sometimes)
	if typeof(cure_type) == TYPE_INT:
		# translate using Enums if necessary (left as TODO)
		pass
	# direct data modification
	for key in data.statuses.keys():
		# simple cure: remove
		data.statuses.erase(key)
	recompute_and_refresh()

# ----------------------------
# Save/load bridge (calls data serialization)
# ----------------------------
func save_parameters() -> Dictionary:
	return data.to_dict()

func post_load(params: Dictionary, set_cell := false) -> void:
	# load into data, then relocate node if requested
	data.from_dict(params)
	if set_cell:
		var conv := str_to_var("Vector2i" + params.cell) as Vector2i
		data.cell = conv
		relocate_unit(conv)

func relocate_unit(location: Vector2i, gridUpdate := true) -> void:
	var old := cell
	position = get_parent().map_to_local(location)
	cell = location
	data.cell = location
	if gridUpdate:
		emit_signal("unit_relocated", old, location, self)

# ----------------------------
# Simple compatibility helpers kept for other code
# ----------------------------
func get_equipped_weapon():
	return data.get_equipped_weapon_runtime()

func get_reach():
	# delegate to data if you implement get_reach() there
	if data.has_method("get_reach"):
		return data.get_reach()
	return {"Min":1,"Max":1}

# ----------------------------
# Signals & event hook examples
# ----------------------------
func _on_unit_relocated():
	# update things that used to be triggered by relocation
	if data.has_method("compute_threats"):
		data.compute_threats()
