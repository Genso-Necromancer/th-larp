@tool
extends ConsumableResource
class_name OfudaResource


@export var cost : int
@export var can_miss : bool = true
@export var can_crit : bool = false
@export var can_dmg : bool = false
@export var hit : int = 0
@export var dmg : int = 0
@export var crit : int = 0
@export var dmg_type : Enums.DAMAGE_TYPE = Enums.DAMAGE_TYPE.NONE
