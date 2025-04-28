extends Node2D

@export_file("*_event.json") var json_event
var test_dic : Dictionary = {}
var test_array : Array = []


func _ready():
	var parser = JasonParser.new()
	var event : Array = parser.parse_json(json_event)
