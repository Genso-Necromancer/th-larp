# status_data.gd
extends Resource
class_name StatusData

## Status identifier used to look up this status.
@export var id : String = ""
## Allows this status to be removed by curing.
@export var curable : bool = true
## Starting duration, measured in Duration Type ticks.
@export var default_duration : int = 0
## Whether duration is measured in turns, rounds, or another supported lifetime.
@export var duration_type : Enums.DURATION_TYPE
## Effects associated with this status.
@export var effects : Array[Effect] = []
