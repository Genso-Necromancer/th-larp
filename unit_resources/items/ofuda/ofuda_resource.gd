@tool
extends ConsumableResource
class_name OfudaResource


## Composure spent to use this Ofuda, in addition to consuming a use.
@export var cost : int
## Enables the action's Hit roll. Disabling it does not bypass an effect's separate proc roll.
@export var can_miss : bool = true
## Allows the action's direct damage to critically hit.
@export var can_crit : bool = false
## Allows direct damage from Dmg. Disable for support-only Ofuda; attached effects still resolve.
@export var can_dmg : bool = false
## Base action Hit, combined with the user's natural Hit when accuracy is rolled.
@export var hit : int = 0
## Might for direct damage. Healing and other effects use their own Value.
@export var dmg : int = 0
## Bonus critical-hit chance in percentage points.
@export var crit : int = 0
## Damage calculation for direct damage. Independent of the types/subtypes of attached effects.
@export var damage_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE

func get_resource_path()->String:
	var path:String = "res://unit_resources/items/ofuda/%s.tres" % id
	
	return path
