@tool
extends Feature
class_name Skill


## Modifies a compatible weapon attack. Hit, Dmg, and Crit become signed bonuses instead of standalone values.
@export var augment : bool = false
## Marks this skill as a spell for Silence and other magic checks. Damage Type still chooses Pwr or Mag.
@export var magical : bool = false:
	set(value):
		magical = value
		if not magical:
			element = Enums.SPELL_ELEMENT.NONE
		notify_property_list_changed()
## Element of this magical skill. Hidden and reset to NONE when Magical is disabled.
var element : Enums.SPELL_ELEMENT = Enums.SPELL_ELEMENT.NONE
## Which units the skill may target: self, allies, enemies, or another supported target mode.
@export var target : Enums.SKILL_TARGET = Enums.SKILL_TARGET.NONE
## Enables the attack's Hit roll. Disabling it does not guarantee attached effect proc rolls.
@export var can_miss : bool = true
## Allows this skill's direct damage to critically hit.
@export var can_crit : bool = true
## Allows direct attack damage. Disable for effect-only skills; attached effects still resolve.
@export var can_dmg : bool = true
## Nearest target distance. For augments, 0 uses compatible weapon reach; nonzero values also constrain eligible weapons.
@export var min_reach : int = 0
## Farthest target distance. For augments, 0 uses compatible weapon reach; nonzero values also constrain eligible weapons.
@export var max_reach : int = 0
## Composure cost of using this skill.
@export var cost : int = 0
@export_category("Augment Skill Parameters")
## Weapon family required by an augment. ANY accepts any otherwise compatible weapon.
@export var weapon_category : Enums.WEAPON_CATEGORY = Enums.WEAPON_CATEGORY.ANY
## Additional weapon subtype required by an augment. NONE leaves subtype unrestricted.
@export var sub_group : Enums.WEAPON_SUB = Enums.WEAPON_SUB.NONE
## Signed adjustment to an augment's minimum target range, after resolving its base reach.
@export var bonus_min_range : int = 0
## Signed adjustment to an augment's maximum target range, after resolving its base reach.
@export var bonus_max_range : int = 0
@export_category("Skill Parameters")
## Base Hit for a standalone skill; signed Hit modifier for an augment.
@export var hit : int = 0
## Might for a standalone skill; signed weapon-damage modifier for an augment. Zero Might can still deal stat-based damage.
@export var dmg : int = 0
## Critical chance in percentage points; added to the weapon's Crit for an augment.
@export var crit : int = 0
## Minimum extra critical damage. Added to the weapon's minimum for an augment.
@export_range(0,99,1.0) var crit_min:int= 0
## Maximum extra critical damage. Added to the weapon's maximum for an augment.
@export_range(0,99,1.0) var crit_max:int= 0
## Direct damage type: PHYS uses Pwr, MAG uses Mag. Independent of Magical and Element.
@export var dmg_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE
@export_category("Effects")
## Effects applied by the skill. Each effect independently controls its target, hit requirement, proc, and duration.
@export var effects : Array[Effect] = []

func _get_property_list():
	var properties = super._get_property_list()
	if magical:
		properties.append({
			"name": "element",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _enum_to_string(Enums.SPELL_ELEMENT)
		})
	return properties

func get_resource_path()->String:
	var path:String = "res://unit_resources/features/skills/%s.gd" % id
	return path


func _get_values()->Dictionary:
	var values:Dictionary = super._get_values()
	values["augment"] = bool(augment)
	values["magical"] = bool(magical)
	values["element"] = element if magical else Enums.SPELL_ELEMENT.NONE
	values["target"] = target
	values["can_miss"] = bool(can_miss)
	values["can_crit"] = bool(can_crit)
	values["can_dmg"] = bool(can_dmg)
	values["min_reach"] = min_reach
	values["max_reach"] = max_reach
	values["cost"] = cost
	values["weapon_category"] = weapon_category
	values["sub_group"] = sub_group
	values["bonus_min_range"] = bonus_min_range
	values["bonus_max_range"] = bonus_max_range
	values["hit"] = hit
	values["dmg"] = dmg
	values["crit"] = crit
	values["crit_min"] = crit_min
	values["crit_max"] = crit_max
	values["dmg_type"] = dmg_type
	values["effects"] = effects
	return values
