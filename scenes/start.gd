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
		var mainCon = get_parent()
		mainCon.newSlave = self
		mainCon.state = mainCon.GameState.START
		popUp = sceneMenu.get_popup()
		popUp.index_pressed.connect(self.on_index_pressed)
		self.loadMapManager.connect(mainCon.on_load_map_manager)
		self.unloadMe.connect(mainCon.unload_me)

		firstLaunch = false

func on_index_pressed(index):
	itemId = popUp.get_item_id(index)
	sceneMenu.set_text(str(popUp.get_item_text(index)))

func _on_load_button_pressed():
	var scenes
	match itemId:
		0: 
			var map = preload("res://scenes/TestMap.tscn").instantiate()
			emit_signal("loadMapManager", map)
			emit_signal("unloadMe", yaBoy)

