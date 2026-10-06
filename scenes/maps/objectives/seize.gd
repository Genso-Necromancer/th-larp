extends Objective
class_name Seize

##Number of required seize events to complete.[br]
##WARNING: do not exceed the number of seize tiles placed

@export var seize_tile_layer:NodePath ##Ensure you select the corresponding Seize Layer, or things won't go how you expect.
@export var completion_type:COMPLETION_TYPE = COMPLETION_TYPE.ALL ##If all criteria, or if any of the criteria must be met to be considered "complete"
var seize_tracker:Dictionary[Vector2i,bool]={}

func _ready():
	super()
	SignalTower.action_seize.connect(self._on_seize)


func ready_tracker(map_layer:SeizeLayer):
	if !map_layer: 
		printerr("[%s]seize_tile_layer does not lead to a SeizeLayer" % ["Seize Objective"])
		return
	var seizeTiles : Array[Vector2i] = map_layer.get_used_cells()
	for tile in seizeTiles:
		seize_tracker[tile] = false
		emit_changed()


func _on_seize(cell:Vector2i):
	if seize_tracker.has(cell):
		seize_tracker[cell] = true
		emit_changed()
	_check_complete(seize_tracker,completion_type)


func get_display_text(map = null) -> String:
	var custom_text := super.get_display_text(map)
	if not custom_text.is_empty():
		return custom_text
	var seize_count := _get_seize_count(map)
	if seize_count == 1:
		return "Seize the Objective"
	if completion_type == COMPLETION_TYPE.ANY:
		return "Seize an objective"
	return "Seize all objectives"


func _get_seize_count(map = null) -> int:
	if map != null and seize_tile_layer != NodePath(""):
		var layer = map.get_node_or_null(seize_tile_layer)
		if layer != null and layer.has_method("get_used_cells"):
			return layer.get_used_cells().size()
	return seize_tracker.size()
