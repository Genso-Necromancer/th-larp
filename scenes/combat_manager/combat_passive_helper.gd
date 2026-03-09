extends RefCounted
class_name CombatPassiveHelper

# Minimal, combat-facing interpretation of passives.
# It does NOT mutate UnitSim; it only answers questions.

const PASSIVE_TYPE := Enums.PASSIVE_TYPE

# Assumes UnitSim.passives is either:
#  A) Dictionary[id -> PassiveResource]
#  B) Dictionary[id -> Dictionary save_data] where save_data includes "type" / "proc" / etc
# If your structure differs, adjust _iter_passives() and _read_* helpers.

func has_passive(unit: UnitSim, p_type: int) -> bool:
	return get_passive(unit, p_type) != null

func get_passive(unit: UnitSim, p_type: int):
	if unit == null:
		return null
	for p :Passive in _iter_passives(unit):
		if _read_type(p) == p_type:
			return p
	return null

func get_proc(unit: UnitSim, p_type: int, default_proc := 0) -> int:
	var p = get_passive(unit, p_type)
	if p == null:
		return default_proc
	return int(_read_proc(p, default_proc))

func can_counter(unit: UnitSim) -> bool:
	return has_passive(unit, PASSIVE_TYPE.COUNTER) or has_passive(unit, PASSIVE_TYPE.VENGEANCE)

# COUNTER: static proc stored on the passive (per your notes).
func counter_proc_chance(unit: UnitSim) -> int:
	return clampi(get_proc(unit, PASSIVE_TYPE.COUNTER, 0), 0, 1000)

# VENGEANCE: (passive.proc) + (damage_taken / 2)  (per your notes)
func vengeance_proc_chance(unit: UnitSim, damage_taken_this_round: int) -> int:
	var base := get_proc(unit, PASSIVE_TYPE.VENGEANCE, 0)
	var bonus := int(floor(float(maxi(damage_taken_this_round, 0)) / 2.0))
	return clampi(base + bonus, 0, 1000)

func has_vantage(unit: UnitSim) -> bool:
	return has_passive(unit, PASSIVE_TYPE.VANTAGE)

func has_fated(unit: UnitSim) -> bool:
	return has_passive(unit, PASSIVE_TYPE.FATED)

func has_deathmatch(unit: UnitSim) -> bool:
	# Your old code used get_multi_round() which likely checks MULTI_ROUND effects/passives.
	# If deathmatch is implemented as a passive, this is the place to interpret it.
	# For now we just look for MULTI_ROUND passive type if you have one; else false.
	return has_passive(unit, PASSIVE_TYPE.FATED) == false and false # placeholder safe default

# -----------------------
# Internal reading helpers
# -----------------------

func _iter_passives(unit: UnitSim) -> Array:
	if unit == null:
		return []
	var ps = unit.passives
	if ps == null:
		return []

	var out: Array = []
	if ps is Array:
		out = ps
	elif ps is Dictionary:
		for k in ps.keys():
			out.append(ps[k])
	return out

func _read_type(passive) -> int:
	# PassiveResource instance?
	if passive != null and typeof(passive) == TYPE_OBJECT:
		if passive.get("type"):
			return int(passive.type)

	# Save-data dictionary?
	if passive is Dictionary:
		if passive.has("type"):
			return int(passive["type"])

	return PASSIVE_TYPE.NONE

func _read_proc(passive, default_proc := 0) -> int:
	if passive != null and typeof(passive) == TYPE_OBJECT:
		if passive.get("proc"):
			return int(passive.proc)
	if passive is Dictionary and passive.has("proc"):
		return int(passive["proc"])
	return default_proc
