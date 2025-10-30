extends Resource
class_name Objective
signal completed(objective:Objective)

enum CONDITION_TYPES {LOSING, WINNING}
enum COMPLETION_TYPE {ALL,ANY}
@export var condition_type : CONDITION_TYPES = CONDITION_TYPES.LOSING ##Decides if meeting it's conditions completes the objective or loses the game.
var complete := false
var active := false

func _ready(): pass


func _on_time_changed(_time:float): pass


func _on_unit_death(_unit_id:String): pass


func _on_seize(_cell:Vector2i): pass


func _check_complete(list:Dictionary, completion_type:COMPLETION_TYPE):
	match completion_type:
		COMPLETION_TYPE.ALL: 
			if !list.values().has(false):
				complete = true
		COMPLETION_TYPE.ANY: 
			if list.values().has(true):
				complete = true
	if complete:
		emit_changed()
		completed.emit(self)
