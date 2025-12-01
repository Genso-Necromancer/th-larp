# unit_data.gd
# Pure game model — no scene references. All logic here.
class_name UnitData
extends RefCounted

# Basic identity
var unit_id: String = ""
var unit_name: String = ""
var FACTION_ID:Enums.FACTION_ID
var SPEC_ID :Enums.SPEC_ID
var ROLE_ID :Enums.ROLE_ID

# Gameplay essentials
var unit_level: int = 1
var unit_exp: int = 0
var is_active: bool = true
var isBoss: bool = false
var isMidBoss: bool = false
var archetype#:AI_TYPE
var leash : int = -1
var one_time_leash : bool = false

# move/type
var move_type:Enums.MOVE_TYPE

# Stat system and caches
var stats: StatBlock = StatBlock.new()
var combat_profile: CombatProfile = CombatProfile.new()

# Inventory: array of RuntimeItem (dictionaries or RuntimeItem objects)
var inventory: Array = []
var natural :RuntimeItem
var unarmed :RuntimeItem= RuntimeItem.new().clone(load("res://unit_resources/items/weapons/unarmed.tres"))

# skills/passives stored as arrays of resource paths / ids
var personal_skills: Array = []
var personal_passives: Array = []
var base_skills: Array = []
var base_passives: Array = []
var bonus_skills: Array = []
var bonus_passives: Array = []
var skills: Array = []   # combined (for viewing)
var passives: Array = [] # combined

# Runtime effects
var active_buffs: Array = []
var active_debuffs: Array = []
var active_item_effects: Array = []
var active_auras: Array = []

# status data
var statuses: Dictionary = {}
var status_data: Dictionary = {}

# runtime combat/relevant
var active_stats: Dictionary = {} # convenience: stores CurLife, CurComp values (kept in sync)
var current_life: int = 1
var current_comp: int = 1

# misc
var terrain_tags: Dictionary = {}
var threats: Array = []
var originCell := Vector2i.ZERO
var cell := Vector2i.ZERO

# ------------ builder ------------
func build_from_node(node):
	# node is your Unit node with many @export fields. Copy them into UnitData.
	# This preserves inspector editing for designers while moving logic out.
	unit_id = node.unit_id
	unit_name = node.unit_name
	FACTION_ID = node.FACTION_ID
	SPEC_ID = node.SPEC_ID
	ROLE_ID = node.ROLE_ID
	unit_level = node.unit_level
	unit_exp = node.unit_exp
	is_active = node.is_active
	isBoss = node.isBoss
	isMidBoss = node.isMidBoss
	archetype = node.archetype
	leash = node.leash
	one_time_leash = node.one_time_leash
	move_type = node.move_type
	# stats/growth/caps exported on node — copy into StatBlock
	stats.base = node.base_stats.duplicate(true) if node.has("base_stats") else {}
	stats.growth = node.base_growth.duplicate(true) if node.has("base_growth") else {}
	stats.caps = node.base_caps.duplicate(true) if node.has("base_caps") else {}
	stats.mods = node.mod_stats.duplicate(true) if node.has("mod_stats") else {}
	stats.recalc()
	# inventory: convert exported resources into runtime items
	inventory.clear()
	if node.has("inventory"):
		for it in node.inventory:
			var ritem := RuntimeItem.new()
			if typeof(it) == TYPE_DICTIONARY:
				# already a runtime-like dict (rare), copy
				ritem.id = it.get("id","")
				ritem.dur = it.get("dur", -1)
				ritem.equipped = it.get("equipped", false)
				ritem.resource_path = it.get("resource_path","")
			else:
				# Common case: it is a Resource (EquipmentData). Wrap it.
				ritem.from_resource(it)
			inventory.append(ritem)
	# natural
	if node.has("natural") and node.natural:
		# natural might be a Resource or a Runtime entry. Wrap accordingly.
		var n :Natural= node.natural
		if typeof(n) == TYPE_OBJECT and n is Resource:
			var rnat := RuntimeItem.new()
			rnat.from_resource(n)
			natural = rnat
		#elif typeof(n) == TYPE_DICTIONARY:
			#natural = deep_copy_dict(n)
	# skills/passives
	personal_skills = node.personal_skills.duplicate(true) if node.has("personal_skills") else []
	personal_passives = node.personal_passives.duplicate(true) if node.has("personal_passives") else []
	base_skills = node.base_skills.duplicate(true) if node.has("base_skills") else []
	base_passives = node.base_passives.duplicate(true) if node.has("base_passives") else []
	_update_features_from_exports()
	# other runtime init
	terrain_tags = node.terrainTags.duplicate(true) if node.has("terrainTags") else {}
	cell = node.cell if node.has("cell") else Vector2i.ZERO
	originCell = cell
	# set current life/composure using total stats
	active_stats["CurLife"] = stats.totals.get("Life", stats.base.get("Life", 1))
	active_stats["CurComp"] = stats.totals.get("Comp", stats.base.get("Comp", 1))
	current_life = active_stats["CurLife"]
	current_comp = active_stats["CurComp"]
	# compute initial combat profile
	compute_combat_profile()

# ------------ utilities ------------
func deep_copy_dict(d:Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		var v = d[k]
		if typeof(v) == TYPE_DICTIONARY:
			out[k] = deep_copy_dict(v)
		elif typeof(v) == TYPE_ARRAY:
			out[k] = []
			for e in v:
				if typeof(e) == TYPE_DICTIONARY:
					out[k].append(deep_copy_dict(e))
				else:
					out[k].append(e)
		else:
			out[k] = v
	return out

# updates combined skill/passive lists (for inspector viewing parity)
func _update_features_from_exports():
	skills.clear()
	passives.clear()
	# base first (e.g. species/role)
	for s in base_skills:
		skills.append(s)
	for p in base_passives:
		passives.append(p)
	# personal and bonus
	for s in personal_skills:
		skills.append(s)
	for s in bonus_skills:
		skills.append(s)
	for p in personal_passives:
		passives.append(p)
	for p in bonus_passives:
		passives.append(p)

# ------------ stat/equipment API ------------
func equip_runtime_item_by_id(item_id: String) -> bool:
	for it in inventory:
		if it.id == item_id:
			for o in inventory:
				o.equipped = false
			it.equipped = true
			recompute_all()
			return true
	return false

func get_equipped_weapon_runtime():
	for it in inventory:
		if it.equipped:
			return it
	# natural / unarmed fallback
	if natural:
		return natural
	return unarmed

func set_equipped(item_resource) -> void:
	# Accepts Resource, id string, or runtime dict
	var id := ""
	if typeof(item_resource) == TYPE_STRING:
		id = item_resource
	elif typeof(item_resource) == TYPE_OBJECT and item_resource is Resource:
		# if a resource was passed, wrap and add if needed
		var r := RuntimeItem.new()
		r.from_resource(item_resource)
		id = r.id
		# add to inventory if not present
		var found := false
		for it in inventory:
			if it.id == r.id:
				found = true
				break
		if !found:
			inventory.append(r)
			#it = r
	else:
		# dict
		id = item_resource.get("id","")
	# try equip
	equip_runtime_item_by_id(id)

func unequip_runtime(item_id:String) -> void:
	for it in inventory:
		if it.id == item_id:
			it.equipped = false
	recompute_all()

# ------------ combat/profile ------------
func compute_combat_profile(terrain_bonus:Dictionary = {}) -> CombatProfile:
	# Convert internal stat block + equipped runtime weapon -> CombatProfile
	var cp := CombatProfile.new()
	# resolve static resource for equipped weapon if needed
	var wep_runtime := get_equipped_runtime_weapon()
	# try to load resource for weapon if resource_path present
	var wep_res :Weapon
	if wep_runtime and ResourceLoader.exists(wep_runtime.resource_path):
		# caller should implement ResourceManager.get_resource(path) if needed
		wep_res =  load(wep_runtime.resource_path)
	else:
		# fallback: attempt to resolve by id via game-specific loader (TODO)
		wep_res = null
	# fallback numeric fields if no resource available
	var dmg := wep_res.dmg
	var hit := wep_res.hit
	var barrier := wep_res.barrier
	var barrier_chance := wep_res.barrier_chance
	var d_type := wep_res.damage_type
	# compute using same formula as original but from statblock totals
	var Pwr :int= stats.totals.Pwr
	var Mag :int= stats.totals.Mag
	var Eleg :int= stats.totals.Eleg
	var Cele :int= stats.totals.Cele
	var Def :int= stats.totals.Def
	var Cha :int= stats.totals.Cha
	# Dmg
	if d_type == Enums.DAMAGE_TYPE.PHYS:
		cp.Dmg = dmg + Pwr + int(terrain_bonus.get("PwrBonus", 0))
	elif d_type == Enums.DAMAGE_TYPE.MAG:
		cp.Dmg = dmg + Mag + int(terrain_bonus.get("MagBonus", 0))
	else:
		cp.Dmg = dmg
	# Hit/Graze
	cp.Hit = (Eleg * 2) + (hit + Cha + int(terrain_bonus.get("HitBonus", 0)))
	cp.Graze = (Cele * 2) + Cha + int(terrain_bonus.get("GrzBonus", 0))
	cp.Barrier = barrier
	cp.BarPrc = int((Eleg/2) + int(Def/2) + barrier_chance + int(terrain_bonus.get("DefBonus", 0)))
	cp.Crit = Eleg + int(wep_res.crit)
	cp.Luck = Cha
	cp.CompRes = clampi(int(Cha/2 + Eleg/2), -200, 75)
	cp.CompBonus = int(Cha / 4)
	cp.MagBase = Mag
	cp.PwrBase = Pwr
	cp.HitBase = (Eleg * 2) + Cha
	cp.CritBase = Eleg
	cp.Resist = Cha * 2
	cp.EffHit = Cha
	cp.DRes = {Enums.DAMAGE_TYPE.PHYS: Def, Enums.DAMAGE_TYPE.MAG: Mag, Enums.DAMAGE_TYPE.TRUE: 0}
	cp.CanMiss = true
	cp.Type = d_type
	# Sleep status reduces graze and barrier chance
	if statuses.has("Sleep") and statuses["Sleep"].Duration > 0:
		cp.Graze = 0
		cp.BarPrc = 0
	combat_profile = cp
	return cp

func recompute_all():
	stats.recalc()
	compute_combat_profile()

# ------------ status / buffs ------------
func apply_damage(dmg:int, _source:UnitData = null) -> void:
	# Reduce current life, set death flag etc.
	current_life = active_stats.get("CurLife", stats.get("Life"))
	current_life = clampi(current_life - dmg, 0, stats.get("Life"))
	active_stats["CurLife"] = current_life
	if current_life <= 0:
		# death handling is done by UnitNode visuals; GameState/CombatManager should take action
		pass

func apply_heal(heal:int=0) -> void:
	current_life = active_stats.get("CurLife", stats.get("Life"))
	current_life = clampi(current_life + heal, 0, stats.get("Life"))
	active_stats["CurLife"] = current_life

func set_status_from_effect(effect_res: Resource) -> void:
	# effect_res expected to be StatusData or EffectData resource
	if effect_res == null: return
	var status_key :String= effect_res.name if effect_res.has("name") else effect_res.id
	statuses[status_key] = true
	status_data[status_key] = {"Duration": effect_res.default_duration if effect_res.has("default_duration") else effect_res.duration, "Curable": effect_res.curable if effect_res.has("curable") else true, "DurationType": effect_res.duration_type if effect_res.has("duration_type") else Enums.DURATION_TYPE.TURN}

# ------------ serialization & clone ------------
func clone() -> UnitData:
	var u := UnitData.new()
	# shallow copy primitives and deep copy complex
	u.unit_id = unit_id
	u.unit_name = unit_name
	u.FACTION_ID = FACTION_ID
	u.SPEC_ID = SPEC_ID
	u.ROLE_ID = ROLE_ID
	u.unit_level = unit_level
	u.unit_exp = unit_exp
	u.is_active = is_active
	u.isBoss = isBoss
	u.isMidBoss = isMidBoss
	u.archetype = archetype
	u.leash = leash
	u.one_time_leash = one_time_leash
	u.move_type = move_type
	u.stats = stats.clone()
	u.combat_profile = combat_profile.clone()
	u.inventory = []
	for it in inventory:
		if typeof(it) == TYPE_DICTIONARY: u.inventory.append(deep_copy_dict(it))
		else: u.inventory.append(it)
	if natural: u.natural = natural
	u.personal_skills = personal_skills.duplicate(true)
	u.personal_passives = personal_passives.duplicate(true)
	u.base_skills = base_skills.duplicate(true)
	u.base_passives = base_passives.duplicate(true)
	u.bonus_skills = bonus_skills.duplicate(true)
	u.bonus_passives = bonus_passives.duplicate(true)
	u.active_buffs = []
	for b in active_buffs: u.active_buffs.append(deep_copy_dict(b))
	u.active_debuffs = []
	for d in active_debuffs: u.active_debuffs.append(deep_copy_dict(d))
	u.statuses = statuses.duplicate(true)
	u.status_data = status_data.duplicate(true)
	u.active_stats = active_stats.duplicate(true)
	u.current_life = current_life
	u.current_comp = current_comp
	u.terrain_tags = terrain_tags.duplicate(true)
	u.cell = cell
	u.originCell = originCell
	return u

func to_dict() -> Dictionary:
	# Option C hybrid
	var inv_arr := []
	for it in inventory:
		if typeof(it) == TYPE_OBJECT and it is RuntimeItem:
			inv_arr.append({"id": it.id, "dur": it.dur, "equipped": it.equipped, "resource_path": it.resource_path})
		elif typeof(it) == TYPE_DICTIONARY:
			inv_arr.append(it.duplicate(true))
	return {
		"unit_id": unit_id,
		"unit_name": unit_name,
		"faction": FACTION_ID,
		"unit_level": unit_level,
		"unit_exp": unit_exp,
		"cell": str(cell),
		"stats": {"base": stats.base.duplicate(true), "growth": stats.growth.duplicate(true), "caps": stats.caps.duplicate(true), "mods": stats.mods.duplicate(true)},
		"inventory": inv_arr,
		"skills": personal_skills.duplicate(true),
		"passives": personal_passives.duplicate(true),
		"statuses": statuses.duplicate(true),
		"active_buffs": active_buffs.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	# minimal safe importer; caller ensures keys are correct
	unit_id = d.get("unit_id", unit_id)
	unit_name = d.get("unit_name", unit_name)
	FACTION_ID = d.get("faction", FACTION_ID)
	unit_level = d.get("unit_level", unit_level)
	unit_exp = d.get("unit_exp", unit_exp)
	var s :Dictionary= d.get("stats", {})
	if s:
		stats.base = s.get("base", {}).duplicate(true)
		stats.growth = s.get("growth", {}).duplicate(true)
		stats.caps = s.get("caps", {}).duplicate(true)
		stats.mods = s.get("mods", {}).duplicate(true)
		stats.recalc()
	inventory.clear()
	for it in d.get("inventory", []):
		inventory.append(it)
	personal_skills = d.get("skills", personal_skills).duplicate(true)
	personal_passives = d.get("passives", personal_passives).duplicate(true)
	statuses = d.get("statuses", statuses).duplicate(true)
	active_buffs = d.get("active_buffs", active_buffs).duplicate(true)
	recompute_all()

# ---------- convenience helpers ----------
func get_equipped_runtime_weapon() -> RuntimeItem:
	for it in inventory:
		if it.get("equipped", false):
			return it
	# fallback natural / unarmed
	if natural: return natural
	return unarmed

func equip_by_id(item_id:String) -> bool:
	for it in inventory:
		if it.id == item_id:
			# unequip others
			for o in inventory: o.equipped = false
			it.equipped = true
			recompute_all()
			return true
	return false
