extends Node
class_name MapManager

@onready var gameBoard :GameBoard = $Gameboard
@onready var guiManager :GUIManager = $CanvasLayer/GUIManager
var dialogie_overlay := preload("res://scenes/cutscenes/dialog_overlay.tscn")
var dOverlay : DialogueOverlay

func _ready():
	_connect_signals()
	

func load_map(map):
	gameBoard.load_map(map)


func _connect_signals()-> void:
	SignalTower.inventory_weapon_changed.connect(gameBoard._on_inventory_weapon_changed)
	SignalTower.action_weapon_selected.connect(gameBoard._on_action_weapon_selected)
	SignalTower.action_skill_confirmed.connect(gameBoard._on_action_weapon_selected)
	gameBoard.map_loaded.connect(self._on_map_loaded)
	gameBoard.gameboard_targeting_canceled.connect(guiManager._on_gameboard_targeting_canceled)
	gameBoard.cursor.cursor_moved.connect(self._on_cursor_moved)
	gameBoard.map_freed.connect(self._on_map_freed)
	gameBoard.turn_changed.connect(guiManager._on_turn_changed)
	gameBoard.new_round.connect(guiManager._on_new_round)
	gameBoard.turn_added.connect(guiManager._on_turn_added)
	gameBoard.turn_removed.connect(guiManager._on_turn_removed)
	guiManager.gui_splash_finished.connect(self._on_gui_splash_finished)
	guiManager.gui_action_menu_canceled.connect(gameBoard._on_gui_action_menu_canceled)
	


#region scene loading
func _on_win_screen_win_finished() -> void:
	#start_load_screen()
	#await SignalTower.fade_out_complete
	GameState.change_state(self, GameState.gState.LOADING)
	load_cutscene()
	if gameBoard.currMap.end_script != null:
		#end_load_screen(0.1)
		dOverlay.prepare_new_dialogue(gameBoard.currMap.end_script)
		await dOverlay.dialog_finished
		#start_load_screen()
		#await SignalTower.fade_out_complete
	dOverlay.queue_free()
	Global.flags.NextMap = gameBoard.currMap.next_map
	gameBoard.free_map()
	#start_load_screen()
	#await SignalTower.fade_out_complete
	#


func _on_map_loaded(map:GameMap):
	#SignalTower.fader_fade_in.emit()
	#await SignalTower.fade_in_complete
	var chNum = map.chapterNumber
	var chTitle = map.title
	var timeString : String = Global.time_to_string(map.hours,map.minutes)
	load_cutscene()
	#end_load_screen()
	#await SignalTower.fade_in_complete
	guiManager.play_splash(chNum, chTitle, timeString)


func _on_map_freed()->void:
	var saveScreen :SaveScreen= load("res://scenes/chapter_save_screen.tscn").instantiate()
	$CanvasLayer.add_child(saveScreen)
	
	saveScreen.save_scene_finished.connect(self._on_save_scene_finished.bind(saveScreen))
	#end_load_screen()


func load_cutscene():
	dOverlay = dialogie_overlay.instantiate()
	$CanvasLayer.add_child(dOverlay)


#func _load_save_screen(mode:int)-> void:
	#var saveScreen
	#match mode:
		#0:pass
		#1:pass
		#2:pass


func _on_save_scene_finished(save_screen:SaveScreen) -> void:
	#start_load_screen()
	GameState.change_state(self, GameState.gState.LOADING)
	save_screen.queue_free()
	gameBoard.load_map(Global.flags.NextMap)


func start_load_screen(speed: float = 0.5):
	GameState.change_state(self, GameState.gState.LOADING)
	SignalTower.fader_fade_out.emit(speed)


func end_load_screen(speed: float = 0.5):
	SignalTower.fader_fade_in.emit(speed)


func _on_gui_splash_finished():
	GameState.change_state(self, GameState.gState.LOADING)
	if gameBoard.currMap.start_script:
		dOverlay.prepare_new_dialogue(gameBoard.currMap.start_script)
		await dOverlay.dialog_finished
	dOverlay.queue_free()
	GameState.change_state(self, GameState.gState.LOADING)
	guiManager.call_setup(gameBoard.depCap, gameBoard.forcedDeploy.keys(), gameBoard.currMap)
#endregion


#region GUI-Gameboard communication
func _on_action_menu_selected(bName:StringName):
	match bName:
		"TalkBtn": pass
		"SeizeBtn": gameBoard.unit_wait()
		"VisitBtn": pass
		"ShopBtn":pass
		"AtkBtn": 
			gameBoard.start_attack_targeting()
		"SklBtn": 
			gameBoard.start_skill_targeting()
		"OpenBtn": pass
		"StealBtn": pass
		"ItmBtn": 
			pass
		"TrdBtn": 
			pass
		"WaitBtn": gameBoard.unit_wait()
		"EndBtn": pass
		"StatBtn": pass
		"OpBtn": pass
		"SusBtn": pass


func trade_seeking(unit:Unit = Global.activeUnit):
	gameBoard.seek_trade(unit)


func call_trade(unit:Unit):
	guiManager.start_action_trade(unit)


func _on_cursor_moved(cell):
	guiManager.focusViewer.update_focus_viewer(cell)
#endregion
