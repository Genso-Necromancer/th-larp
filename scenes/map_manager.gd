extends Node

class_name MapManager

@onready var gameBoard :GameBoard = $Gameboard
@onready var guiManager :GUIManager = $CanvasLayer/GUIManager


func _ready():
	gameBoard.map_loaded.connect(self._on_map_loaded)
	gameBoard.gameboard_targeting_canceled.connect(guiManager._on_gameboard_targeting_canceled)
	SignalTower.inventory_weapon_changed.connect(gameBoard._on_inventory_weapon_changed)
	SignalTower.action_weapon_selected.connect(gameBoard._on_action_weapon_selected)
	SignalTower.action_skill_confirmed.connect(gameBoard._on_action_weapon_selected)
	guiManager.gui_splash_finished.connect(self._on_gui_splash_finished)
	guiManager.gui_action_menu_canceled.connect(gameBoard._on_gui_action_menu_canceled)
	gameBoard.cursor.cursor_moved.connect(self._on_cursor_moved)

func load_map(map):
	gameBoard.change_map(map)


func _on_map_loaded(map:GameMap):
	var chNum = map.chapterNumber
	var chTitle = map.title
	var timeString : String = Global.time_to_string(map.hours,map.minutes)
	guiManager.play_splash(chNum, chTitle, timeString)


##GUI-Gameboard communication
func _on_gui_splash_finished():
	guiManager.call_setup(gameBoard.depCap, gameBoard.forcedDeploy.keys(), gameBoard.currMap)


func _on_action_menu_selected(bName:StringName):
	match bName:
		"TalkBtn": pass
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
	guiManager.focusViewer.call_deferred("update_focus_viewer",cell)
