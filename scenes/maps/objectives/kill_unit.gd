extends Objective
class_name KillUnit

##Array of enemy Units required to be defeated to be considered complete
@export var hit_list_paths : Array[NodePath]
var hit_list : Array[String] = []
