@tool
extends SlotWrapper
##inheritance only, inherits from SlotWrapper, do not use directly. Instead use Weapon, Natural, Consumable or Accessory.
class_name Item
signal durability_reduced(item)

@export_group("Item Parameters")
@export var equipped := false
@export var dropped := false
@export var is_broken := false
var temp_remove : bool = false
var max_dur : int = 1
var trade := true
var dur : int = 1:
	set(value):
		dur = clampi(value,0,max_dur)
		emit_changed()
		emit_signal("durability_reduced",self)
var level :int = 1
var personal := false
var breakable := true
var expendable := true
var equippable := true
var use := false
var category : Enums.WEAPON_CATEGORY = Enums.WEAPON_CATEGORY.NONE
var sub_group : Enums.WEAPON_SUB = Enums.WEAPON_SUB.NONE
var effects : Array[Effect] = []
var rule_type : Enums.RULE_TYPE = Enums.RULE_TYPE.NONE ##Determins requirements for equipping. Specifically Species and Role
var sub_rule

func _init(resource : ItemResource = load("res://unit_resources/items/weapons/unarmed_resource.tres")) -> void:
	super(resource)
	if properties == null: return
	max_dur = properties.max_dur
	dur = properties.max_dur
	breakable = properties.breakable
	expendable = properties.expendable
	equippable = properties.equippable
	level = properties.level
	personal = properties.personal
	use = properties.use
	category = properties.category
	sub_group = properties.sub_group
	effects = properties.effects
	trade = properties.trade
	rule_type = properties.rule_type
	sub_rule = properties.sub_rule
