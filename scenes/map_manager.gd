extends Node

class_name MapManager

@onready var gameBoard := $Gameboard
@onready var guiManager := $CanvasLayer/GUIManager


func _ready():
	gameBoard.map_loaded.connect(self._on_map_loaded)
	guiManager.gui_splash_finished.connect(self._on_gui_splash_finished)


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
	
func _on_gui_splash_finished():
	guiManager.call_setup(gameBoard.depCap, gameBoard.forcedDeploy.keys(), gameBoard.currMap)
