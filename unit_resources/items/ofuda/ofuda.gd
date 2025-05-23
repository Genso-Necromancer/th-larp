@tool
extends Consumable
class_name Ofuda

var cost : int
var hit : int
var can_miss : bool
var can_dmg : bool
var can_crit : bool
var dmg : int = 0
var crit : int = 0
var dmg_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE

func _init(resource : ItemResource = stats) -> void:
	if resource == null: return
	elif stats == null: stats = resource
	super(resource)
	if properties == null: return
	cost = properties.cost
	hit = properties.hit
	can_miss = properties.can_miss
	can_dmg = properties.can_dmg
	can_crit = properties.can_crit
	dmg = properties.dmg
	crit = properties.crit
	dmg_type = properties.dmg_type
