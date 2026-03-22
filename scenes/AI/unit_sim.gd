extends Node
##Used to simulate units within the AI's thinking process
class_name UnitSim

var id:String
var team:Enums.FACTION_ID
var spec:Enums.SPEC_ID
var cell:Vector2i
var current_life:int
var comp:int
var total_stats:Dictionary
var active_stats:Dictionary
#var total_stats:Dictionary[StringName,int]
#var active_stats:Dictionary[StringName,int]
#Specific Typing removed for now as other scripts lack the typing and Godot does not play nice between the two, even if valid
var status:Dictionary
var status_data:Dictionary
var weapon:Dictionary
var inventory:Dictionary
var natural:Dictionary
var skills:Dictionary
var passives:Dictionary
var auras
var threats:Array
var move_type:Enums.MOVE_TYPE
var terrain_tags:Dictionary
var combat_data:Dictionary
var weapon_reach:Dictionary # {"Min": int, "Max": int} optional
var equipped_effects: Array[Dictionary] = [] # list of Effect.convert_to_data() dicts (+ optional instance fields)


func clone() -> UnitSim:
	var c = UnitSim.new()
	c.id = id
	c.team = team
	c.spec = spec
	c.cell = cell
	c.current_life = current_life
	c.comp = comp
	c.total_stats = total_stats.duplicate(true)
	c.active_stats = active_stats.duplicate(true)
	c.status = status.duplicate(true)
	c.status_data = status_data.duplicate(true)
	c.passives = passives.duplicate()
	c.skills = skills.duplicate()
	c.inventory = inventory.duplicate(true)
	c.weapon = weapon.duplicate(true)
	c.natural = natural.duplicate(true)
	c.threats = threats.duplicate()
	c.move_type = move_type
	c.terrain_tags = terrain_tags.duplicate(true)
	c.combat_data = combat_data.duplicate(true)
	c.weapon_reach = weapon_reach.duplicate(true) # optional but very helpful
	c.equipped_effects = equipped_effects.duplicate(true)
	return c

#Appliers
func apply_dmg(amount: int) -> void:
	if amount <= 0:
		return
	current_life = max(0, current_life - amount)
	# Optional: mirror simple “wake on damage” behavior in sim, if you track statuses:
	# if status.get("Sleep", false): status["Sleep"] = false

func apply_heal(amount: int, max_life: int = 9999) -> void:
	if amount <= 0:
		return
	current_life = min(max_life, current_life + amount)

#Status
func is_alive() -> bool:
	return current_life > 0

func has_status(key) -> bool:
	# Supports both String and StringName keys
	if status == null:
		return false
	if status.has(key):
		return bool(status[key])
	# Common fallback if some systems stored StringName
	if typeof(key) == TYPE_STRING and status.has(StringName(key)):
		return bool(status[StringName(key)])
	return false

func can_act() -> bool:
	if not is_alive():
		return false

	# PASS A: common “cannot act” flags
	# Adjust keys to match what you actually store (e.g. "Acted", "Sleep", etc.)
	if has_status("Acted"):
		return false
	if has_status("Sleep"):
		return false

	return true

#Passives
func iter_passives() -> Array:
	var out: Array = []
	if passives == null:
		return out

	if passives is Dictionary:
		for k in passives.keys():
			var p = passives[k]
			if p != null:
				out.append(p)

	return out

func has_passive_type(p_type: int) -> bool:
	for p in iter_passives():
		if p is Dictionary and int(p.type) == p_type:
			return true
	return false


func get_best_passive_proc(p_type: int, default_proc := 0) -> int:
	var best := default_proc
	for p in iter_passives():
		if p is Dictionary and int(p.type) == p_type:
			best = maxi(best, int(p.proc))
	return best


func _source_value(source, key: String, default_value = null):
	if source == null:
		return default_value
	if typeof(source) == TYPE_DICTIONARY:
		return source.get(key, default_value)
	return source.get(key) if source.get(key) != null else default_value


func _source_bool(source, key: String, default_value := false) -> bool:
	var value = _source_value(source, key, default_value)
	return bool(value)


func get_skill_combat_stats(special, augmented := false) -> Dictionary:
	var stats := combat_data.duplicate(true)
	var dmg_stat := 0
	var attack = get_equipped_weapon() if augmented else special
	var skill_dmg_type = _source_value(special, "dmg_type", null)
	var type_lord = skill_dmg_type if augmented and skill_dmg_type else _source_value(attack, "dmg_type", Enums.DAMAGE_TYPE.PHYS)
	stats["Type"] = int(type_lord)

	match int(type_lord):
		Enums.DAMAGE_TYPE.PHYS:
			dmg_stat = int(stats.get("PwrBase", 0))
		Enums.DAMAGE_TYPE.MAG:
			dmg_stat = int(stats.get("MagBase", 0))
		Enums.DAMAGE_TYPE.TRUE:
			dmg_stat = 0

	stats["CanDmg"] = _source_bool(special, "can_dmg", true)
	if not bool(stats["CanDmg"]):
		stats["Dmg"] = 0
	elif augmented:
		stats["Dmg"] = dmg_stat + int(_source_value(attack, "dmg", 0)) + int(_source_value(special, "dmg", 0))
	else:
		stats["Dmg"] = dmg_stat + int(_source_value(attack, "dmg", 0))

	stats["CanMiss"] = _source_bool(special, "can_miss", true)

	if augmented:
		stats["Hit"] = int(stats.get("HitBase", 0)) + int(_source_value(attack, "hit", 0)) + int(_source_value(special, "hit", 0))
	else:
		stats["Hit"] = int(stats.get("HitBase", 0)) + int(_source_value(attack, "hit", 0))

	var skill_crit = _source_value(special, "crit", null)
	stats["CanCrit"] = _source_bool(special, "can_crit", true)
	if not bool(stats["CanCrit"]):
		stats["Crit"] = 0
	elif skill_crit == null:
		stats["Crit"] = 0
	elif augmented:
		stats["Crit"] = int(stats.get("CritBase", 0)) + int(_source_value(attack, "crit", 0)) + int(skill_crit)
	else:
		stats["Crit"] = int(stats.get("CritBase", 0)) + int(_source_value(attack, "crit", 0))

	return stats

#Look ups
func get_equipped_weapon()->Dictionary: return weapon

func get_multi_swing():
	var swings := 0

	for ed in equipped_effects:
		if typeof(ed) != TYPE_DICTIONARY:
			continue

		var etype := int(ed.get("type", -1))
		if etype != Enums.EFFECT_TYPE.MULTI_SWING:
			continue

		# Prefer multi_swing field; fall back to value for older content
		var v := int(ed.get("multi_swing", 0))
		if v <= 0:
			v = int(ed.get("value", 0))

		if v > swings:
			swings = v

	return false if swings <= 0 else swings
