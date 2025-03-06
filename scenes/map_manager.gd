extends Node

class_name MapManager

@onready var gameBoard := $Gameboard
@onready var guiManager := $CanvasLayer/GUIManager


func _ready():
	gameBoard.map_loaded.connect(self._on_map_loaded)
	gameBoard.gameboard_targeting_canceled.connect(guiManager._on_gameboard_targeting_canceled)
	SignalTower.inventory_weapon_changed.connect(gameBoard._on_inventory_weapon_changed)
	SignalTower.action_weapon_selected.connect(gameBoard._on_action_weapon_selected)
	guiManager.gui_splash_finished.connect(self._on_gui_splash_finished)
	guiManager.gui_action_menu_canceled.connect(gameBoard._on_gui_action_menu_canceled)
	

func load_map(map):
	gameBoard.change_map(map)
	

func _on_map_loaded(map):
	var chNum = map.chapterNumber
	var chTitle = map.title
	var time = map.gameTime
	#var dayHalf := ""
	var timeString := "%s:00"
	
	if time < 10:
		time = "0%s" % [time]
	timeString = timeString % [time]
	
	guiManager.play_splash(chNum, chTitle, timeString)
	
	#if time > 12:
		#time = time - 12
		#dayHalf = "PM"
	#elif: time == 12:
		#dayHalf = "PM"
	#elif: time == 0:

##GUI-Gameboard communication

func _on_gui_splash_finished():
	guiManager.call_setup(gameBoard.depCap, gameBoard.forcedDeploy.keys(), gameBoard.currMap)


func _on_action_menu_selected(bName:StringName):
	match bName:
		"TalkBtn": pass
		"AtkBtn": 
			gameBoard.start_attack_targeting()
		"SklBtn": 
			pass
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
