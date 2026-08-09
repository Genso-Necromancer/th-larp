# AuraController.gd
class_name AuraController
extends RefCounted

var unit : Unit

# Auras OWNED by this unit
# Key = Aura resource
# Val = AuraArea instance
var owned_auras : Dictionary[Aura, AuraArea] = {}

# Auras CURRENTLY AFFECTING this unit
# Key = AuraArea instance
var active_areas : Dictionary[AuraArea, bool] = {}
# self buffing auras
var self_aura_triggers : Dictionary = {}

func _init(u : Unit) -> void:
	unit = u


# -------------------------------------------------
# OWNED AURAS (from passives)
# -------------------------------------------------
func validate_auras(valid : Array[Aura]) -> void:
	for aura in owned_auras.keys():
		if not valid.has(aura):
			remove_aura(aura)

	for aura in valid:
		load_aura(aura)


func load_aura(aura : Aura) -> void:
	if owned_auras.has(aura):
		return

	var area : AuraArea = load("res://scenes/aura_collision.tscn").instantiate()
	unit.get_node("PathFollow2D").add_child(area)
	area.call_deferred("set_aura", unit, aura)
	owned_auras[aura] = area


func remove_aura(aura : Aura) -> void:
	if not owned_auras.has(aura):
		return

	var area := owned_auras[aura]
	if is_instance_valid(area):
		area.queue_free()
	owned_auras.erase(aura)
	_clear_nonstack_aura(aura)


func get_visual_aura_range() -> int:
	var highest := 0
	for aura in owned_auras.keys():
		highest = max(highest, aura.range)
	return highest


# -------------------------------------------------
# ACTIVE AURAS (collision driven)
# -------------------------------------------------
func on_aura_enter(area : AuraArea) -> void:
	active_areas[area] = true

func on_aura_trigger_enter(aura:Aura,source:Unit)->void:
	for effect:Effect in aura.effects:
		if effect.stack:
			unit.buff_controller.apply_effect(effect, Enums.EFFECT_SOURCE.AURA, source)
			continue
		var triggers := _get_nonstack_aura_triggers(aura, effect)
		if triggers.has(source):
			continue
		var was_empty := triggers.is_empty()
		triggers[source] = true
		if was_empty:
			unit.buff_controller.apply_effect(effect, Enums.EFFECT_SOURCE.AURA)

func on_aura_exit(area : AuraArea) -> void:
	active_areas.erase(area)

func on_aura_trigger_exit(aura: Aura, source: Unit) -> void:
	for effect:Effect in aura.effects:
		if effect.stack:
			unit.buff_controller.remove_effect(effect, source)
			continue
		var triggers := _get_nonstack_aura_triggers(aura, effect)
		if not triggers.has(source):
			continue
		triggers.erase(source)
		if triggers.is_empty():
			unit.buff_controller.remove_effect(effect)
			_clear_nonstack_aura_triggers(aura, effect)


# -------------------------------------------------
# STAT CONTRIBUTION
# -------------------------------------------------
func get_stat_modifiers() -> Dictionary:
	var mods := {}
	var sub_keys := Enums.SUB_TYPE.keys()

	for area in active_areas.keys():
		var aura :Aura= area.aura
		for effect in aura.effects:
			var stat :String= sub_keys[effect.sub_type].to_pascal_case()
			mods[stat] = mods.get(stat, 0) + effect.value
	return mods

func _apply_self_aura_stack(aura: Aura) -> void:
	for effect in aura.effects:
		if effect.stack:
			unit.buff_controller.add_stack(effect)
		else:
			unit.buff_controller.apply_or_refresh(effect)

func _remove_self_aura_stack(aura: Aura) -> void:
	for effect in aura.effects:
		if effect.stack:
			unit.buff_controller.remove_stack(effect)


func _get_nonstack_aura_triggers(aura: Aura, effect: Effect) -> Dictionary:
	if not self_aura_triggers.has(aura):
		self_aura_triggers[aura] = {}
	var aura_triggers: Dictionary = self_aura_triggers[aura]
	if not aura_triggers.has(effect):
		aura_triggers[effect] = {}
	return aura_triggers[effect]


func _clear_nonstack_aura_triggers(aura: Aura, effect: Effect) -> void:
	if not self_aura_triggers.has(aura):
		return
	var aura_triggers: Dictionary = self_aura_triggers[aura]
	aura_triggers.erase(effect)
	if aura_triggers.is_empty():
		self_aura_triggers.erase(aura)


func _clear_nonstack_aura(aura: Aura) -> void:
	if not self_aura_triggers.has(aura):
		return
	var aura_triggers: Dictionary = self_aura_triggers[aura]
	for effect: Effect in aura_triggers.keys():
		unit.buff_controller.remove_effect(effect)
	self_aura_triggers.erase(aura)
