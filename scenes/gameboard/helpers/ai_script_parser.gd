extends Node
class_name AiScriptParser
##feed instructions from the AI to this class, and it will parse the actions GameBoard needs to take
##Intended to be used in tandem with GameBoard class via signals


enum AI_STEPS {STAND_BY,PROCESSING,START,EVALUATE,PROCESS_TURN,SELECT_UNIT,MOVE_UNIT}
var ai_step:AI_STEPS = AI_STEPS.STAND_BY
var check_step:bool = false
var instruct:Dictionary

func _process(_delta):
	if check_step: _parse_step()
	


func set_instruct(ai_instruct:Dictionary):
	instruct = ai_instruct

func _parse_step():
	match ai_step:
		AI_STEPS.STAND_BY:pass
