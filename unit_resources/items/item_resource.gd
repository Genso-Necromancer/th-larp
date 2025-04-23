@tool
extends UnitResource
class_name ItemResource


@export_category("Usability")
@export var personal : bool = false
@export var level : int = 0
@export var use : bool = false
@export var equippable : bool = true
@export var breakable : bool = true
@export var expendable : bool = true
@export var trade : bool = true
@export var max_dur : int = 1
@export var category : Enums.WEAPON_CATEGORY = Enums.WEAPON_CATEGORY.NONE
@export var sub_group : Enums.WEAPON_SUB = Enums.WEAPON_SUB.NONE
@export_category("Effects")
@export var effects : Array[Effect] = []
