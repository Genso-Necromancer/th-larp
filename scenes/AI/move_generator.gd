extends Node
class_name MoveGenerator

## Generates moves for a given unit
var actions:Dictionary[String,bool]={"Move":false,"Act":false,"Canto":false,"Trade":false,"TimeWarp":false}


func generate_moves(state:BoardState)->Array[Turn]:
	var moves:Array[Turn]=[]
	return moves
