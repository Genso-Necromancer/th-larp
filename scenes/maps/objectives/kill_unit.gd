extends Objective
class_name KillUnit


@export var completion_type:COMPLETION_TYPE = COMPLETION_TYPE.ALL ##If all criteria, or if any of the criteria must be met to be considered "complete"
@export var hit_list_unit_ids : Array[String] ##IDs of units to be tracked if killed for completion

var hit_list : Dictionary[String,bool] = {}

func _ready():
	super()
	SignalTower.unit_death.connect(self._on_unit_death)
	fill_list()


func fill_list():
	for id in hit_list_unit_ids:
		hit_list[id.to_snake_case()] = false
	emit_changed()


func _on_unit_death(unit_id:String):
	if hit_list.has(unit_id):
		hit_list[unit_id] = true
		emit_changed()
	_check_complete(hit_list,completion_type)
