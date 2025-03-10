extends Control
signal loadScene
signal unloadMe
signal loadMapManager
@onready var sceneMenu = $VBoxContainer/SceneMenu
@onready var loadBtn = $VBoxContainer/LoadButton
var itemId = null
var popUp
var firstLaunch = true
@onready var yaBoy = $"."

func _ready():
	if firstLaunch:
		var main = get_parent()
		GameState.newSlave = [yaBoy]
		GameState.state = GameState.gState.START
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
			var map = preload("res://scenes/maps/TestMap0.tscn")
			emit_signal("loadMapManager", map)
			emit_signal("unloadMe", yaBoy)
