extends UnitResource
class_name Aura

@export var range : int
@export var is_self := false
@export var target_team : Enums.TARGET_TEAM = Enums.TARGET_TEAM.NONE
@export var target : Enums.EFFECT_TARGET = Enums.EFFECT_TARGET.NONE
@export var effects : Array[Effect] = []
