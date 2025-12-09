# EquipmentHelper.gd
# Handles all equipping, unequipping, validation, weapon finding, accessory limits,temporary equips, and item effect integration.
class_name EquipmentHelper
extends RefCounted

var unit : Unit

func _init(u: Unit) -> void:
	unit = u



# PUBLIC ENTRY POINTS
func set_equipped(item: Item = null, is_temp := false) -> void:
	# Determine if we're equipping a weapon, accessory, or auto-equip first valid.
	if item == null:
		# If natural is equipped already, nothing to change.
		if unit.natural and unit.natural.equipped:
			return

		# If a weapon is already equipped, keep it.
		if _has_equipped_weapon():
			return

		# Otherwise find a valid weapon OR fallback to unarmed.
		item = _find_first_valid_weapon()

	if item is Weapon:
		_equip_weapon(item, is_temp)
	elif item is Accessory:
		_equip_accessory(item)

	unit.update_stats()


func unequip(item: Item, as_command := false) -> void:
	item.equipped = false
	_remove_item_effects(item)

	# *as_command* means: user intentionally unequipped; we must assign fallback weapon.
	if not as_command:
		return

	# Try to find another weapon to auto-equip.
	if _has_equipped_weapon():
		return

	if unit.natural:
		_equip_weapon(unit.natural)
	else:
		_equip_weapon(unit.unarmed)

	unit.update_stats()


func restore_temp_weapon() -> void:
	# Restores the weapon that was temporarily unequipped during a preview.
	for item in unit.inventory:
		if item is Weapon and item.temp_remove:
			item.temp_remove = false
			set_equipped(item)
			return



# INTERNAL IMPLEMENTATION
func _has_equipped_weapon() -> bool:
	for item in unit.inventory:
		if item is Weapon and item.equipped:
			return true
	return false


func _find_first_valid_weapon() -> Weapon:
	# Natural has priority.
	if unit.natural and check_valid_equip(unit.natural):
		return unit.natural

	for item in unit.inventory:
		if item is Weapon and check_valid_equip(item):
			return item

	return unit.unarmed


func _equip_weapon(weapon: Weapon, is_temp: bool=false) -> void:
	var old_equip : Weapon
	var original_temp : Weapon

	# 1. Detect currently equipped or temp-removed existing weapon
	for item in unit.inventory:
		if item is Weapon:
			if item.equipped and item == weapon:
				return   # Already equipped.
			if item.temp_remove:
				original_temp = item
			elif item.equipped:
				old_equip = item

	# 2. Unequip current weapon if any
	if old_equip:
		if is_temp and not original_temp:
			old_equip.temp_remove = true
		unequip(old_equip)

	# 3. Equip new weapon
	weapon.equipped = true

	# TEMP-EQUIP: do not reorder inventory!
	if not is_temp and unit.inventory.has(weapon):
		var i = unit.inventory.find(weapon)
		var stored_item = unit.inventory.pop_at(i)
		unit.inventory.push_front(stored_item)

	# Clear temp_remove if applying a real equip
	if not is_temp and original_temp:
		original_temp.temp_remove = false

	_add_item_effects(weapon)


func _equip_accessory(acc: Accessory) -> void:
	# You currently use a hard-coded limit of 2 accessories.
	var limit := 2
	var equipped := []

	# Collect equipped accessories
	for i in unit.inventory:
		if i is Accessory and i.equipped:
			equipped.append(i)

	# Remove old ones if exceeding the limit  
	while equipped.size() >= limit:
		var removed = equipped.pop_back()
		unequip(removed)

	acc.equipped = true
	_add_item_effects(acc)



# ITEM EFFECTS
func _add_item_effects(item: Item) -> void:
	if not item.effects.is_empty():
		for effect in item.effects:
			if effect.target == Enums.EFFECT_TARGET.EQUIPPED:
				unit.active_item_effects.append(effect)


func _remove_item_effects(item: Item) -> void:
	if item.effects:
		for effect in item.effects:
			var idx = unit.active_item_effects.find(effect)
			if idx >= 0:
				unit.active_item_effects.remove_at(idx)



# VALIDATION RULES
func check_valid_equip(item: Item) -> bool:
	var iCat = item.category
	var subCat = item.sub_group

	if item is Weapon or item is Consumable:
		return is_proficient(iCat, subCat) and not item.is_broken

	if item is Accessory:
		return is_rule_met(item.rule_type, item.sub_rule)

	return false


func is_proficient(i_cat: Enums.WEAPON_CATEGORY, sub_cat: Enums.WEAPON_SUB) -> bool:
	var catKeys = Enums.WEAPON_CATEGORY.keys()
	var subKeys = Enums.WEAPON_SUB.keys()

	if sub_cat == Enums.WEAPON_SUB.NONE and i_cat == Enums.WEAPON_CATEGORY.NONE:
		return true

	if i_cat == Enums.WEAPON_CATEGORY.ITEM:
		return false

	if i_cat == Enums.WEAPON_CATEGORY.ACC:
		return true

	# sub-group proficiency
	if sub_cat != Enums.WEAPON_SUB.NONE:
		var subName = subKeys[sub_cat].to_pascal_case()
		if unit.weapon_prof[subName]:
			return true

	# category proficiency
	var catName = catKeys[i_cat].to_pascal_case()
	return unit.weapon_prof[catName]


func is_rule_met(rule_type: Enums.RULE_TYPE, sub_type: Enums.SUB_RULE) -> bool:
	# You can expand this later — currently accessories always pass.
	return true
