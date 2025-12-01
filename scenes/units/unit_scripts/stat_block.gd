# stat_block.gd
class_name StatBlock
extends RefCounted

# Stats use Pascal-case keys consistent with your original code: "Move","Life","Pwr","Mag","Eleg","Cele","Def","Cha","Comp"
var base: Dictionary[StringName,int] = {}
var growth: Dictionary[StringName,float] = {}
var caps: Dictionary[StringName,int] = {}

# Permanent modifiers (equipment, passives); stored as flat adds to stat keys
var mods: Dictionary[StringName,int] = {}

# Temporary buffs/debuffs (effect id -> {sub_type, value, duration})
var temporary_mods: Array[Dictionary] = []

# Cached computed totals
var totals: Dictionary[StringName,int] = {}

func _init():
	pass

func clone() -> StatBlock:
	var s := StatBlock.new()
	s.base = base.duplicate(true)
	s.growth = growth.duplicate(true)
	s.caps = caps.duplicate(true)
	s.mods = mods.duplicate(true)
	s.temporary_mods = []
	for m in temporary_mods: s.temporary_mods.append(m.duplicate(true))
	s.recalc()
	return s

func recalc(only_keys: Array = []) -> void:
	# Recompute totals from base + mods + temporary_mods, respecting caps
	var keys:Array
	# If only_keys is provided, recompute only those; otherwise recompute all base keys
	if only_keys.size() > 0: keys = only_keys
	else: keys = base.keys()
	for k in keys:
		var base_val :int= base.get(k, 0)
		var mod_val :int= mods.get(k, 0)
		var temp_val := 0
		for t in temporary_mods:
			# expected t: {"stat": "Pwr", "value": 2}
			if t.stat == k:
				temp_val += int(t.value)
		var val := base_val + mod_val + temp_val
		# Enforce cap if present
		if caps.has(k):
			val = clamp(val, -9999, caps[k])
		else:
			val = clamp(val, -9999, val)
		totals[k] = val

func get_stat(stat:StringName) -> int:
	if totals.has(stat):
		return totals[stat]
	# fallback compute
	recalc([stat])
	return totals.get(stat, 0)

func add_mod(stat:StringName, value:int) -> void:
	mods[stat] = mods.get(stat, 0) + value
	recalc([stat])

func add_temporary(stat:StringName, value:int, duration:int, duration_type:Enums.DURATION_TYPE, id:String = "") -> void:
	temporary_mods.append({"stat":stat,"value":int(value),"duration":int(duration),"duration_type":duration_type,"id":id})

func tick_temporary_by_duration(duration_type:Enums.DURATION_TYPE) -> void:
	# Decrement durations and remove expired temporary mods. Caller decides mapping from effect to stat.
	for i in range(temporary_mods.size()-1, -1, -1):
		var t = temporary_mods[i]
		if t.duration_type != duration_type: continue
		t.duration -= 1
		if t.duration <= 0: temporary_mods.remove_at(i)
	recalc()

func clear_temporary() -> void:
	temporary_mods.clear()
	recalc()
