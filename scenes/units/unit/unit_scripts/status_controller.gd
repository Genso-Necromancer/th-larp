# StatusController.gd
class_name StatusController
extends RefCounted

var unit : Unit

# Internal storage:
# statuses[s_name] = {
#   "active": bool,
#   "stacks": int,
#   "duration": int,
#   "duration_type": Enums.DURATION_TYPE,
#   "curable": bool,
#   "config": Dictionary,
#   "fx": Node
# }
var statuses : Dictionary = {}

func _init(u: Unit) -> void:
	unit = u
	# Bootstrap from unit.status if it already has some flags
	if unit.status:
		for s_name in unit.status.keys():
			if unit.status[s_name]:
				# Basic default: no duration info yet
				statuses[s_name] = {
					"active": true,
					"stacks": 1,
					"duration": unit.sParam.get(s_name, {}).get("Duration", 0),
					"duration_type": unit.sParam.get(s_name, {}).get("DurationType", Enums.DURATION_TYPE.TURN),
					"curable": unit.sParam.get(s_name, {}).get("Curable", true),
					"config": _get_status_config(s_name),
					"fx": null,
				}


# ======================================================================
# PUBLIC API
# ======================================================================

# Effect-driven apply (like your old set_status(effect))
func apply_from_effect(effect: Effect) -> void:
	if effect == null:
		printerr("StatusController.apply_from_effect: null effect")
		return
	
	var status_keys : Array = Enums.SUB_TYPE.keys()
	var s_name : String = status_keys[effect.sub_type].to_pascal_case()
	if s_name == "All":
		# 'All' is only used for curing
		return
	
	_apply_status(s_name, effect.duration, effect.duration_type, effect.curable, true)
	unit.update_stats()


# For special cases where you want to directly toggle a status flag
# (e.g. Acted after a unit acts, without an Effect resource)
func set_status_flag(s_name: String, active: bool) -> void:
	var cfg = _get_status_config(s_name)
	if not statuses.has(s_name):
		statuses[s_name] = {
			"active": active,
			"stacks": 1,
			"duration": 0,
			"duration_type": cfg.default_duration_type,
			"curable": cfg.curable_default,
			"config": cfg,
			"fx": null,
		}
	else:
		statuses[s_name].active = active
	
	unit.status[s_name] = active
	
	# "Acted" has no FX, others should spawn / cleanup FX
	if active:
		if cfg.has_fx:
			_ensure_fx(s_name)
	else:
		_clear_status(s_name, false) # just turn it off
	
	unit.update_sprite()
	unit.update_stats()


# Turn/round ticking (replaces status_duration_tick)
func tick(duration_type: Enums.DURATION_TYPE) -> void:
	var to_clear : Array = []
	
	for s_name in statuses.keys():
		var data = statuses[s_name]
		if not data.active:
			continue
		if data.duration_type != duration_type:
			continue
		if data.duration <= 0:
			continue
		
		data.duration -= 1
		# Mirror into sParam for legacy compatibility
		if unit.sParam.has(s_name):
			unit.sParam[s_name].Duration = data.duration
		
		if data.duration <= 0:
			to_clear.append(s_name)
	
	for s_name in to_clear:
		_clear_status(s_name)
	
	if not to_clear.is_empty():
		unit.update_stats()
		unit.update_sprite()


# Cure by SUB_TYPE, matches your old cure_status(cureType)
func cure_status(sub_type: Enums.SUB_TYPE, ignore_curable := false) -> void:
	var keys : Array = Enums.SUB_TYPE.keys()
	var stype : String = keys[sub_type].to_pascal_case()
	
	if stype == "All":
		for s_name in statuses.keys():
			if s_name == "Acted":
				continue  # you explicitly excluded Acted from "All" cures
			if not statuses[s_name].active:
				continue
			if not ignore_curable and not statuses[s_name].curable:
				continue
			_clear_status(s_name)
	else:
		if not statuses.has(stype) or not statuses[stype].active:
			print("No status cured for:", stype)
			return
		
		if not ignore_curable and not statuses[stype].curable:
			print("Status [%s] is not curable" % [stype])
			return
		
		_clear_status(stype)
	
	unit.update_stats()
	unit.update_sprite()


func has_status(s_name: String) -> bool:
	return statuses.has(s_name) and statuses[s_name].active


# Hook from Unit.apply_dmg so Sleep can be broken on hit
func on_damage_taken(dmg: int) -> void:
	if dmg <= 0:
		return
	# Sleep wakes on damage
	if has_status("Sleep"):
		var cfg = _get_status_config("Sleep")
		if cfg.wakes_on_damage:
			_clear_status("Sleep")
			unit.update_stats()
			unit.update_sprite()


# Acted helper (special, no FX)
func set_acted(active: bool) -> void:
	set_status_flag("Acted", active)
	if active and unit.one_time_leash and unit.leash > -1:
		unit.leash = -1


# ======================================================================
# INTERNAL APPLY/CLEAR LOGIC
# ======================================================================

func _apply_status(s_name: String, duration: int, duration_type: Enums.DURATION_TYPE, curable: bool, stack_if_allowed: bool) -> void:
	var cfg = _get_status_config(s_name)
	
	if not statuses.has(s_name):
		statuses[s_name] = {
			"active": true,
			"stacks": 1,
			"duration": duration,
			"duration_type": duration_type,
			"curable": curable,
			"config": cfg,
			"fx": null,
		}
	else:
		var data = statuses[s_name]
		data.active = true
		
		if cfg.stackable and stack_if_allowed:
			# General rule: increase stacks up to max, refresh/extend duration
			data.stacks = min(data.stacks + 1, cfg.max_stacks)
			if cfg.refresh_on_stack:
				data.duration = duration
			else:
				data.duration += duration
		else:
			# Non-stackable: refresh duration
			data.duration = duration
			data.stacks = 1
		
		data.duration_type = duration_type
		data.curable = curable
	
	# Handle special logic like Chilled -> Frozen
	_handle_special_transitions(s_name)
	
	# Mirror flag + sParam for compatibility with old logic
	unit.status[s_name] = true
	unit.sParam[s_name] = {
		"Duration": statuses[s_name].duration,
		"Curable": statuses[s_name].curable,
		"DurationType": statuses[s_name].duration_type,
		"Stacks": statuses[s_name].stacks,
	}
	
	# FX handling
	if cfg.has_fx:
		_ensure_fx(s_name)


func _clear_status(s_name: String, remove_entry := true) -> void:
	if not statuses.has(s_name):
		return
	
	var data = statuses[s_name]
	data.active = false
	
	# Mirror to unit.status
	if unit.status.has(s_name):
		unit.status[s_name] = false
	
	# Clear sParam entry
	if unit.sParam.has(s_name):
		unit.sParam.erase(s_name)
	
	_clear_status_fx_node(s_name)
	
	if remove_entry:
		statuses.erase(s_name)


# ======================================================================
# STATUS DEFINITIONS / CONFIG
# ======================================================================

# This config lets us express your answers to Q1–Q5.
# You can expand this anytime without touching logic.
func _get_status_config(s_name: String) -> Dictionary:
	var cfg := {
		"stackable": false,
		"max_stacks": 1,
		"refresh_on_stack": true, # default: refresh duration on reapply
		"upgrade_to": null,       # e.g. Chilled -> Frozen
		"wakes_on_damage": false,
		"has_fx": true,
		"default_duration_type": Enums.DURATION_TYPE.TURN,
		"curable_default": true,
		"blocks_action": false,   # useful for AI/turn system later
	}
	
	match s_name:
		"Acted":
			cfg.has_fx = false
			cfg.blocks_action = true
			cfg.curable_default = true  # you want skills that 'give another action'
		"Sleep":
			cfg.wakes_on_damage = true
			cfg.blocks_action = true
		"Poison":
			cfg.stackable = true
			cfg.max_stacks = 10 # tweak as needed
			cfg.refresh_on_stack = false  # 'rolling' duration: stacking extends duration
		"Chilled":
			cfg.stackable = true
			cfg.max_stacks = 3
			cfg.refresh_on_stack = true
			cfg.upgrade_to = "Frozen"
		"Frozen":
			cfg.blocks_action = true
		"Uncomposed":
			# hook this later into composure/tension system
			pass
		"Dazed", "Berserk":
			# these will later affect AI / combat decisions
			pass
	
	return cfg


func _handle_special_transitions(s_name: String) -> void:
	# Only really needed right now for Chilled -> Frozen
	if s_name != "Chilled":
		return
	
	var data = statuses[s_name]
	var cfg = data.config
	
	if cfg.upgrade_to and data.stacks >= cfg.max_stacks:
		# Replace Chilled with Frozen
		_clear_status("Chilled")
		_apply_status(cfg.upgrade_to, data.duration, data.duration_type, data.curable, false)


# ======================================================================
# VISUAL FX HELPERS
# ======================================================================

func _ensure_fx(s_name: String) -> void:
	var data = statuses[s_name]
	var cfg = data.config
	if not cfg.has_fx:
		return
	
	# Don't recreate if it already exists
	if data.fx and is_instance_valid(data.fx):
		return
	
	var fx_path = "res://scenes/animations/status_effects/animated_sprite_%s.tscn"
	fx_path = fx_path % [s_name.to_snake_case()]
	
	if not ResourceLoader.exists(fx_path):
		# Missing FX resource is not fatal
		return
	
	var sprite = unit.get_node_or_null("PathFollow2D/Sprite")
	var hp = unit.get_node_or_null("PathFollow2D/Sprite/HPbar")
	if sprite == null or hp == null:
		return
	
	var fx_animation = load(fx_path).instantiate()
	if fx_animation:
		fx_animation.play(s_name)
		sprite.add_child(fx_animation)
		fx_animation.call_deferred("move_before", hp)
		data.fx = fx_animation


func _clear_status_fx_node(s_name: String) -> void:
	var data = statuses.get(s_name, null)
	if data and data.fx and is_instance_valid(data.fx):
		data.fx.queue_free()
		data.fx = null
	else:
		# Fallback to your old scan-by-animation-s_name behavior
		var sprite = unit.get_node_or_null("PathFollow2D/Sprite")
		if sprite:
			for kid in sprite.get_children():
				if kid is AnimatedSprite2D and kid.get_animation() == s_name.to_pascal_case():
					kid.queue_free()
