# AuraController.gd
class_name AuraController
extends RefCounted

var unit : Unit

# Auras this unit EMITS (from passives, etc.)
# Key = Aura resource, Value = spawned AuraArea node
var owned_areas : Dictionary[Aura,AuraArea] = {} # Dictionary[Aura, AuraArea]

# Auras currently AFFECTING this unit
# Key = AuraArea instance, Value = Array[Effect] currently applied from that area
var active_effects : Dictionary[AuraArea,Array] = {} # Dictionary[AuraArea, Array[Effect]]

func _init(u: Unit) -> void:
	unit = u


# ==========================================================
# OWNED AURAS (emitters) — moved from Unit.gd
# ==========================================================

func validate_auras(valid: Array[Aura]) -> void:
	# Remove any owned aura not in valid list
	var to_remove : Array[Aura] = []
	for a in owned_areas.keys():
		if not valid.has(a):
			to_remove.append(a)

	for a in to_remove:
		remove_owned_aura(a)


func load_owned_aura(aura: Aura) -> void:
	if aura == null:
		return
	if owned_areas.has(aura):
		return

	var aura_area : AuraArea = load("res://scenes/aura_collision.tscn").instantiate()
	var path_follow := unit.get_node_or_null("PathFollow2D")
	if path_follow == null:
		printerr("AuraController.load_owned_aura: Unit missing PathFollow2D")
		return

	path_follow.add_child(aura_area)
	aura_area.call_deferred("set_aura", unit, aura)
	owned_areas[aura] = aura_area


func remove_owned_aura(aura: Aura) -> void:
	if not owned_areas.has(aura):
		return

	var area: AuraArea = owned_areas[aura]
	if is_instance_valid(area):
		area.queue_free()
	owned_areas.erase(aura)


func get_visual_aura_range() -> int:
	var highest := 0
	for a in owned_areas.keys():
		if a and a.range > highest:
			highest = a.range
	return highest


# ==========================================================
# AFFECTED AURAS (receivers) — signal-driven
# ==========================================================

func on_aura_entered(area: AuraArea) -> void:
	#print("%s entered %s's aura [%s]" % [unit,area.master,area])
	if area == null or area.aura == null:
		return

	# Team filtering (preserves your existing logic)
	match area.aura.target_team:
		Enums.TARGET_TEAM.ALLY:
			if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and unit.FACTION_ID == Enums.FACTION_ID.NPC:
				pass
			elif area.master.FACTION_ID != unit.FACTION_ID:
				return

		Enums.TARGET_TEAM.ENEMY:
			if area.master.FACTION_ID == unit.FACTION_ID:
				return

	# SELF-only auras handled in on_self_aura_enter
	if area.aura.target == Enums.EFFECT_TARGET.SELF:
		return

	if not active_effects.has(area):
		active_effects[area] = area.aura.effects.duplicate(true)

	_request_stat_update()


func on_aura_exited(area: AuraArea) -> void:
	print("%s exited aura [%s]" % [unit,area])
	if active_effects.has(area):
		active_effects.erase(area)
		_request_stat_update()


func on_self_aura_enter(area: AuraArea) -> void:
	print("%s entered aura [%s]" % [unit,area])
	if area == null or area.aura == null:
		return

	match area.aura.target_team:
		Enums.TARGET_TEAM.ALLY:
			if area.master.FACTION_ID != Enums.FACTION_ID.ENEMY and unit.FACTION_ID == Enums.FACTION_ID.NPC:
				pass
			elif area.master.FACTION_ID != unit.FACTION_ID:
				return

		Enums.TARGET_TEAM.ENEMY:
			if area.master.FACTION_ID == unit.FACTION_ID:
				return

	if area.aura.target != Enums.EFFECT_TARGET.SELF:
		return

	if not active_effects.has(area):
		active_effects[area] = area.aura.effects.duplicate(true)
	else:
		# Preserve your stacking behavior: only append stackable effects
		for effect in area.aura.effects:
			if effect.stack:
				active_effects[area].append(effect)

	_request_stat_update()


func on_self_aura_exit(area: AuraArea) -> void:
	#print("%s exited aura [%s]" % [unit,area])
	if not active_effects.has(area):
		return

	# Mirror your old logic: pop one stack, delete when empty
	if active_effects[area].size() > 1:
		active_effects[area].pop_back()
	else:
		active_effects.erase(area)

	_request_stat_update()


# ==========================================================
# StatBlock integration
# ==========================================================

func get_stat_modifiers() -> Dictionary:
	var mods := {}
	var sub_keys :Array[String]
	sub_keys.assign(Enums.SUB_TYPE.keys())
	
	for area in active_effects.keys():
		for effect in active_effects[area]:
			var stat_name := sub_keys[effect.sub_type].to_pascal_case()
			mods[stat_name] = mods.get(stat_name, 0) + effect.value
	#print(mods)
	return mods


# ==========================================================
# Utilities
# ==========================================================

func clear_active_effects() -> void:
	active_effects.clear()
	_request_stat_update()


func _request_stat_update() -> void:
	# Prefer your existing pipeline
	if unit.has_method("update_stats"):
		unit.update_stats()
	elif unit.has("stats_block"):
		unit.stats_block.update_stats()
