extends Resource
class_name Personality

var units :float= 0.25

enum PRIORITIES {
		NONE, ##None
		OBJECTIVE, 
		OFFENSE, 
		PLAYS, 
		DEFENSE, 
		SURVIVAL, 
		RECOVERY, 
		SPECIAL
} 
@export_group("Strategy Priority Order")
@export var first : PRIORITIES:
	set(value):
		print(str(value))
		_validate_choice(value)
		first = value
		notify_property_list_changed.call_deferred()
@export var second : PRIORITIES:
	set(value):
		_validate_choice(value)
		second = value
		notify_property_list_changed.call_deferred()
@export var third : PRIORITIES:
	set(value):
		_validate_choice(value)
		third = value
		notify_property_list_changed.call_deferred()
@export var fourth : PRIORITIES:
	set(value):
		_validate_choice(value)
		fourth = value
		notify_property_list_changed.call_deferred()
@export var fifth : PRIORITIES:
	set(value):
		_validate_choice(value)
		fifth = value
		notify_property_list_changed.call_deferred()
@export var sixth : PRIORITIES:
	set(value):
		_validate_choice(value)
		sixth = value
		notify_property_list_changed.call_deferred()
@export var seventh : PRIORITIES:
	set(value):
		_validate_choice(value)
		seventh = value
		notify_property_list_changed.call_deferred()

@export_group("Priority Weights")
@export var terrain :float= 1
@export var finishOffUnits :float= 0.25
@export var dmgWeight :float= 0.25
@export var accWeight :float= 0.25
@export var barrierChance :float= 1.2
@export var survival :float= 1.1
@export var waitWeight :float= 0.12
@export var survThresh :float= 0.5
@export var accScale :float= 2.2
@export var safeBonus:float= 1.4
@export_group("Misc. Parameters")
@export var maxDepth = 3 ##Not currently used
@export var minimumValue : float = 0.5 ##minimum action value a priority needs to cut off actions 



func _validate_choice(value:PRIORITIES):
	var tiers : Array[PRIORITIES] = [first,second,third,fourth,fifth,sixth,seventh]
	print(str(value))
	for p in tiers:
		print(str(p))
		if value == p and value != PRIORITIES.NONE:
			p == PRIORITIES.NONE
