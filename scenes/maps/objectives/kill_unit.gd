extends Objective
class_name KillUnit


@export var completion_type:COMPLETION_TYPE = COMPLETION_TYPE.ALL ##If all criteria, or if any of the criteria must be met to be considered "complete"
@export var hit_list_unit_ids : Array[String] ##IDs of units to be tracked if killed for completion

var hit_list : Dictionary[String,bool] = {}

func _ready():
	super()
	_connect_unit_death_signal()
	fill_list()


func ready_tracker():
	_connect_unit_death_signal()
	fill_list()


func _connect_unit_death_signal() -> void:
	if !SignalTower.unit_death.is_connected(self._on_unit_death):
		SignalTower.unit_death.connect(self._on_unit_death)


func fill_list():
	hit_list.clear()
	for id in hit_list_unit_ids:
		hit_list[id.to_snake_case()] = false
	emit_changed()


func _on_unit_death(unit):
	var unit_id := _get_unit_id(unit)
	if hit_list.has(unit_id):
		hit_list[unit_id] = true
		emit_changed()
	_check_complete(hit_list,completion_type)


func _get_unit_id(unit) -> String:
	if unit is Unit:
		return String(unit.unit_id).to_snake_case()
	return String(unit).to_snake_case()


func get_display_text(map = null) -> String:
	var custom_text := super.get_display_text(map)
	if not custom_text.is_empty():
		return custom_text
	var names := _get_target_names()
	if names.is_empty():
		return "Defeat the target" if condition_type == CONDITION_TYPES.WINNING else "Protect your allies"
	var target_text := _join_names(names)
	if condition_type == CONDITION_TYPES.WINNING:
		return "Defeat %s" % [target_text]
	return "Do not allow %s to fall" % [target_text]


func _get_target_names() -> Array[String]:
	var names: Array[String] = []
	for unit_id in hit_list_unit_ids:
		names.append(_get_unit_name(unit_id))
	return names


func _get_unit_name(unit_id: String) -> String:
	var string_id := "unit_name_%s" % [unit_id.to_snake_case()]
	var text := StringGetter.get_string(string_id)
	return unit_id if text == string_id else text


func _join_names(names: Array[String]) -> String:
	if names.size() == 1:
		return names[0]
	if names.size() == 2:
		return "%s or %s" % [names[0], names[1]] if completion_type == COMPLETION_TYPE.ANY else "%s and %s" % [names[0], names[1]]
	var joined := ""
	for index in range(names.size()):
		if index > 0:
			joined += ", "
		if index == names.size() - 1:
			joined += "or " if completion_type == COMPLETION_TYPE.ANY else "and "
		joined += names[index]
	return joined
