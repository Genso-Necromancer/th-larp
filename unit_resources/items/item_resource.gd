@tool
extends UnitResource
class_name ItemResource


@export_category("Usability")
## Marks the item as Unique in tooltips. This flag alone does not restrict it to a named character.
@export var personal : bool = false
## Minimum unit level required to equip/use this item.
@export var level : int = 0
## Allows using this item as an action from the inventory.
@export var use : bool = false
## Allows this item to occupy an equipment slot, subject to proficiency and other requirements.
@export var equippable : bool = true
## Allows durability to decrease. Disable for items that never wear out.
@export var breakable : bool = true
## Deletes the item at zero durability. If false, it remains as a broken item.
@export var expendable : bool = true
## Allows this item to be transferred through inventory trading.
@export var trade : bool = true
## Maximum durability/uses; new item copies start with this amount.
@export var max_dur : int = 1
## Equipped weight contributes to Cele loss: max(0, total equipped weight - Pwr). Zero adds no weight.
@export var weight : int = 0:
	set(value):
		weight = clampi(value, 0, 999)
## Main proficiency family. STICK means polearm; accessory subclasses provide their own slot/proficiency rules.
@export var category : Enums.WEAPON_CATEGORY = Enums.WEAPON_CATEGORY.NONE
## Additional weapon subtype, such as KNIFE or BARRIER. NONE means no subtype.
@export var sub_group : Enums.WEAPON_SUB = Enums.WEAPON_SUB.NONE
@export_category("Effects")
## Effects carried by this item. Use target EQUIPPED for benefits that apply while equipped.
@export var effects : Array[Effect] = []

func get_resource_path()->String:
	var path:String = "" % id
	return path
