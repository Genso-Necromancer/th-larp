# StatsBlock.gd
class_name StatsBlock
extends RefCounted

var unit : Unit

func _init(u: Unit) -> void:
	unit = u


func update_stats():
	# 1. Recompute base stats (base + mods + level_stats)
	var base_stats = _compute_base_totals()
	unit.base_stats_final = base_stats  # Store for UI
	
	# 2. mod groups
	var time_mods  = _compute_time_modifiers()
	var aura_mods  = _compute_aura_modifiers()
	var buff_mods  = _compute_buff_modifiers()
	var ui_buff_mods = _compute_buff_modifiers_for_ui()
	var item_mods  = _compute_item_modifiers()

	# Groups for UI
	unit.stat_mod_breakdown = {
		"time": time_mods,
		"aura": aura_mods,
		"buffs": ui_buff_mods,
		"items": item_mods,
	}


	# 3. Merge into final stats
	var final_stats = base_stats.duplicate(true)
	_apply_mod_group(final_stats, time_mods)
	_apply_mod_group(final_stats, aura_mods)
	#print("aura_mods: %s" % [aura_mods])
	_apply_mod_group(final_stats, buff_mods)
	#_apply_mod_group(final_stats, item_mods)

	_apply_status_locks(final_stats)
	_clamp_final_stats(final_stats)
	unit.active_stats = final_stats

	# 4. Compute combat values (base & final)
	var base_combat = _compute_combat_stats(base_stats)
	print("base_stats: %s" % [base_combat])
	var finalCombat = _compute_combat_stats(final_stats)
	_apply_mod_group(finalCombat, time_mods)
	_apply_mod_group(finalCombat, buff_mods)
	_apply_mod_group(finalCombat, aura_mods)
	print("final_stats: %s" % [finalCombat])
	unit.base_combat = base_combat
	unit.combat_data = finalCombat

	# 5. Compute combat breakdown
	unit.combat_bonus_breakdown = _combat_difference(base_combat, finalCombat)

	# Optional sprite update hook
	if unit.has_method("update_sprite"):
		unit.update_sprite()

#region private funcs
#Base
func _compute_base_totals() -> Dictionary:
	var result := {}
	for stat in unit.base_stats.keys():
		result[stat] = (
		unit.base_stats.get(stat, 0) 
		+ unit.mod_stats.get(stat, 0) 
		+ unit.level_stats.get(stat, 0)
		)
	return result
#Mods
func _compute_time_modifiers() -> Dictionary:
	var mods := {}
	var time = Global.time_of_day
	var data = PlayerData.timeModData[unit.SPEC_ID][time]

	if data == null: return mods

	var immune = unit.check_time_prot()

	for key in data.keys():
		if immune:
			mods[key] = max(0, data[key])
		else:
			mods[key] = data[key]
	
	return mods

func _compute_aura_modifiers() -> Dictionary:
	return unit.aura_controller.get_stat_modifiers()

func _compute_buff_modifiers() -> Dictionary:
	return unit.buff_controller.get_modifiers()

func _compute_buff_modifiers_for_ui() -> Dictionary:
	var all :Dictionary= unit.buff_controller.get_modifiers()
	var mods := {}
	for id in all.keys():
		if all[id].source == Enums.EFFECT_SOURCE.BUFF:
			var s = all[id].stat_name
			mods[s] = mods.get(s, 0) + all[id].value
	return mods

func _compute_item_modifiers() -> Dictionary:
	var mods := {}
	var subKeys = Enums.SUB_TYPE.keys()

	for effect in unit.equipment_helper.equipped_effects:
		if effect.type == Enums.EFFECT_TYPE.BUFF or effect.type == Enums.EFFECT_TYPE.DEBUFF:
			var stat_name = subKeys[effect.sub_type].to_pascal_case()
			mods[stat_name] = mods.get(stat_name, 0) + effect.value
	return mods

#Mod Merge
func _apply_mod_group(target, group):
	for key in group:
		#if key == "DRes" and target.has(key): _apply_dres_values(target, group)
		if target.has(key):
			target[key] += group[key]

#func _apply_dres_values(target:Dictionary, group:Dictionary):
	#for res in target.DRes:
		#if group.DRes.keys().has(res):
			#target.DRes[res] += group.DRes[res]

func _apply_status_locks(stats: Dictionary) -> void:
	if unit.status.Sleep:
		stats["Move"] = 0

func _clamp_final_stats(stats:Dictionary) -> void:
	for stat in stats:
		stats[stat] = clampi(stats[stat],0,999)

func _compute_combat_stats(stats: Dictionary) -> Dictionary:
	var wep : Weapon = unit.get_equipped_weapon()
	var t  : Dictionary = unit.get_terrain_bonus()
	var c := {
		"Type": wep.damage_type,
		"Dmg": 0,
		"Hit": 0,
		"Graze": 0,
		"Barrier": wep.barrier,
		"BarPrc": 0,
		"Crit": 0,
		"Luck": stats.Cha,
		"CompRes": clampi((stats.Cha / 2) + (stats.Eleg / 2), -200, 75),
		"CompBonus": stats.Cha / 4,
		"PwrBase": stats.Pwr,
		"MagBase": stats.Mag,
		"HitBase": (stats.Eleg * 2) + stats.Cha,
		"CritBase": stats.Eleg,
		"Resist": stats.Cha * 2,
		"EffHit": stats.Cha,
		"DRes": 0,
		"CanMiss": true,
	}
	
	match wep.damage_type:
		Enums.DAMAGE_TYPE.PHYS:
			c.Dmg = wep.dmg + stats.Pwr + t.PwrBonus
		Enums.DAMAGE_TYPE.MAG:
			c.Dmg = wep.dmg + stats.Mag + t.MagBonus
		Enums.DAMAGE_TYPE.TRUE:
			c.Dmg = wep.dmg
	c.Hit = c.HitBase + wep.hit + t.HitBonus
	c.Graze = (stats.Cele * 2) + stats.Cha + t.GrzBonus
	c.BarPrc = (stats.Eleg/2) + (stats.Def/2) + wep.barrier_chance + t.DefBonus
	c.Crit = c.CritBase + wep.crit

	if unit.status.Sleep:
		c.Graze = 0
		c.BarPrc = 0
	return c

func _combat_difference(base: Dictionary, final: Dictionary) -> Dictionary:
	var diff := {}
	for key in base.keys():
		if typeof(base[key]) == TYPE_INT or typeof(base[key]) == TYPE_FLOAT:
			diff[key] = final[key] - base[key]
		else:
			# Complex values like DRes may need custom handling later
			diff[key] = null
	return diff
#endregion
