# status_data.gd
extends Resource
class_name StatusData

@export var id : String = ""
@export var curable : bool = true
@export var default_duration : int = 0
@export var duration_type : Enums.DURATION_TYPE
@export var effects : Array[Effect] = []
