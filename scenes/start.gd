extends Control
signal load_scene(scene)
signal unloadMe
signal loadMapManager
@onready var sceneMenu = $VBoxContainer/SceneMenu
@onready var loadBtn = $VBoxContainer/LoadButton
var itemId = null
var popUp
var firstLaunch = true
#@onready var yaBoy = $"."

func _ready():
	if firstLaunch:
		var main :MainNode= get_parent()
		GameState.change_state(self, GameState.gState.START)
		#GameState.newSlave = yaBoy
		#GameState.state = GameState.gState.START
		popUp = sceneMenu.get_popup()
		popUp.index_pressed.connect(self.on_index_pressed)
		self.loadMapManager.connect(main.on_load_map_manager)
		self.unloadMe.connect(main.unload_me)
		firstLaunch = false


func on_index_pressed(index):
	itemId = popUp.get_item_id(index)
	sceneMenu.set_text(str(popUp.get_item_text(index)))

func _on_load_button_pressed():
	match itemId:
		0: 
			var map = "res://scenes/maps/seize_test.tscn"
			emit_signal("loadMapManager", map)
			emit_signal("unloadMe", self)
		1: 
			var map = "res://scenes/maps/killunit_test.tscn"
			emit_signal("loadMapManager", map)
			emit_signal("unloadMe", self)
