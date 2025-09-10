extends Node2D
class_name InteractableTile

@export var map:GameMap
@export var faction_id:Enums.FACTION_ID = Enums.FACTION_ID.ENEMY
@export var enabled := true
#@export var ai_hint
var cell := Vector2i.ZERO:
	set(value):
		if map: cell = map.cell_clamp(value)


func _process(_delta):
	if Engine.is_editor_hint() and map and map.local_to_map(position) != cell:
		cell = map.local_to_map(position)


func _ready():
	if map: cell = map.local_to_map(position)
	

func get_save_data()->Dictionary:
	var data:Dictionary={}
	return data
