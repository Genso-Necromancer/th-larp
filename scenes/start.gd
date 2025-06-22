extends Control
signal load_scene(scene)
signal map_picked
signal loadMapManager
@onready var sceneMenu = $VBoxContainer/SceneMenu
@onready var loadBtn = $VBoxContainer/LoadButton
var itemId = null
#@onready var yaBoy = $"."

func _ready():
	var popUp = sceneMenu.get_popup()
	popUp.index_pressed.connect(self.on_index_pressed)
	


func on_index_pressed(index):
	var popUp = sceneMenu.get_popup()
	itemId = popUp.get_item_id(index)
	sceneMenu.set_text(str(popUp.get_item_text(index)))

func _on_load_button_pressed():
	match itemId:
		0: 
			var map = "res://scenes/maps/seize_test.tscn"
			emit_signal("loadMapManager", map)
			emit_signal("map_picked")
		1: 
			var map = "res://scenes/maps/killunit_test.tscn"
			emit_signal("loadMapManager", map)
			emit_signal("map_picked")
