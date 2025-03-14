@tool
extends Node2D
class_name UnitSpawner

@export var spawnGroup : PackedScene ##Assign Spawn Group with units attatched
var timeMethod: String:
	get:
		return timeMethod
	set(value):
		timeMethod = value
		print(timeMethod)
var timeHours: int = 0 ##use the 24hour clock retard



func _ready():
	self.visible = false


func get_spawn_points():
	var eventGrid = $EventGrid
	return eventGrid.get_used_cells()

func get_group():
	var group = spawnGroup.instantiate()
	add_child(group)
	return group

func _get_property_list():
	var properties = []
	
	properties.append({
		"name" : "timeMethod",
		"type" : TYPE_STRING,
		"hint" : PROPERTY_HINT_ENUM,
		"hint_string" : "Time Passed,Time of Day",
		})
	
	properties.append({
		"name": "timeHours",
		"type" : TYPE_INT,
		"hint" : PROPERTY_HINT_RANGE,
		"hint_string" : "0,24,min,max"
	})
	
	return properties
