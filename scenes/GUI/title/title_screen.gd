extends Control
class_name TitleScreen
signal unload_me

@onready var debug_menu := $Margin/VBox/StartMenu
@onready var feature_workshop_button := $Margin/VBox/ButtonMargin/Vbox/FeatureWorkshop


func _ready():
	var main :MainNode= get_parent()
	var debug_enabled := bool(Global.flags.get("DebugMode", false))
	GameState.change_state(self, GameState.gState.START)
	feature_workshop_button.visible = debug_enabled
	debug_menu.visible = debug_enabled
	debug_menu.loadMapManager.connect(main.on_load_map_manager)
	debug_menu.map_picked.connect(self._unload_scene)


func _unload_scene():
	var main :MainNode= get_parent()
	main.unload_me(self)



func _on_new_game_button_pressed(_button):
	var main :MainNode= get_parent()
	main.new_game_start()
	main.unload_me(self)


func _on_feature_workshop_button_pressed(_button):
	var main :MainNode= get_parent()
	main.new_game_start(MainNode.FEATURE_WORKSHOP_MAP)
	main.unload_me(self)


func _on_load_game_button_pressed(_button):
	var main :MainNode= get_parent()
	main.begin_file_select()
	main.unload_me(self)


func _on_exit_button_pressed(_button):
	SignalTower.exiting_game.emit()
