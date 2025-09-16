extends Node
class_name MapManager

@onready var gameBoard :GameBoard = %Gameboard
@onready var guiManager :GUIManager = %GUIManager
var dialogue_overlay := preload("res://scenes/cutscenes/dialog_overlay.tscn")
var dOverlay : DialogueOverlay
var current_map:String
var next_map:String
var is_suspended_load:=false
var load_initiated:= false

func _ready():
	_connect_signals()


#region save/load
func save()->Dictionary:
	var saveData:Dictionary
	saveData["DataType"] = "MapManager"
	saveData["current_map"] = current_map
	saveData["next_map"] = next_map
	return saveData


func load_data(save_data:Dictionary):
	var data :Dictionary= save_data.MapManager
	current_map = data.current_map
	next_map = data.next_map

#endregion

	
func load_map(map:String):
	if !map: print("[MapManager]load_map: empty map string")
	gameBoard.load_map(map)


func load_map_from_file(map:String, save_data:Dictionary, is_suspended:bool=false):
	if !map: print("[MapManager]load_map_from_file: empty map string")
	is_suspended_load = is_suspended
	if is_suspended_load: gameBoard.save_enum = Enums.SAVE_TYPE.SUSPENDED
	gameBoard.load_map(map, save_data)


#func load_suspended_map_from_file(map:String, save_data:Dictionary):
	#if !map: print("[MapManager]load_suspended_map_from_file: empty map string")
	#is_suspended_load = true
	#gameBoard.load_map(map, save_data)


func shift_to_next_map():
	current_map = next_map
	next_map = ""


func _connect_signals()-> void:
	SignalTower.inventory_weapon_changed.connect(gameBoard._on_inventory_weapon_changed)
	SignalTower.action_weapon_selected.connect(gameBoard._on_action_weapon_selected)
	SignalTower.action_skill_confirmed.connect(gameBoard._on_action_weapon_selected)
	SignalTower.returning_to_title.connect(self._on_returning_to_title)
	SignalTower.chest_opened.connect(self._on_chest_opened)
	SignalTower.chest_stolen.connect(self._on_chest_stolen)
	gameBoard.map_loaded.connect(self._on_map_loaded)
	gameBoard.gameboard_targeting_canceled.connect(guiManager._on_gameboard_targeting_canceled)
	gameBoard.cursor.cursor_moved.connect(self._on_cursor_moved)
	gameBoard.map_freed.connect(self._on_map_freed)
	gameBoard.turn_changed.connect(guiManager._on_turn_changed)
	gameBoard.new_round.connect(guiManager._on_new_round)
	gameBoard.turn_added.connect(guiManager._on_turn_added)
	gameBoard.turn_removed.connect(guiManager._on_turn_removed)
	gameBoard.map_added.connect(self._on_map_added)
	gameBoard.action_confirmed.connect(guiManager._on_gameboard_action_confirmed)
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
	gameBoard.free_map()
	#start_load_screen()
	#await SignalTower.fade_out_complete
	#


func _on_map_added(map:GameMap):
	var newTime = Global.time_to_float(map.hours, map.minutes)
	#Global.game_time = newTime
	#Global.currentMap = map
	current_map = map.get_scene_file_path()
	PlayerData.chapter_title = map.title
	next_map = map.next_map
	


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


#func _on_suspension_loaded(map:GameMap):
	#var chNum = map.chapterNumber
	#var chTitle = map.title
	#var timeString : String = Global.time_to_string(map.hours,map.minutes)
	##end_load_screen()
	##await SignalTower.fade_in_complete
	#guiManager.play_splash(chNum, chTitle, timeString)


func _on_map_freed()->void:
	var saveScreen :SaveScreen= load("res://scenes/chapter_save_screen.tscn").instantiate()
	shift_to_next_map()
	saveScreen.save_type = Enums.SAVE_TYPE.TRANSITION
	$%CanvasLayer.add_child(saveScreen)
	saveScreen.save_scene_finished.connect(self._on_save_scene_finished)
	#end_load_screen()


func load_cutscene():
	dOverlay = dialogue_overlay.instantiate()
	$%CanvasLayer.add_child(dOverlay)


func _on_save_scene_finished(save_screen:SaveScreen) -> void:
	#Establish the need for the loading screen
	GameState.change_state(self, GameState.gState.LOADING)
	gameBoard.load_map(current_map)


func start_load_screen(speed: float = 0.5):
	GameState.change_state(self, GameState.gState.LOADING)
	SignalTower.fader_fade_out.emit(speed)


func end_load_screen(speed: float = 0.5):
	SignalTower.fader_fade_in.emit(speed)


func _on_gui_splash_finished()->void:
	if load_initiated: 
		return
	elif is_suspended_load:
		is_suspended_load = false
		load_initiated = true
		_suspended_start()
	else:
		load_initiated = true
		_set_up_start()


func _suspended_start():
	if !Global.flags.DebugMode:
		SaveHub.delete_temp()
	GameState.change_state(self, GameState.gState.LOADING)
	guiManager.begin_mode()
	#gameBoard.begin_chapter()				


func _set_up_start():
	GameState.change_state(self, GameState.gState.LOADING)
	if gameBoard.currMap.start_script:
		dOverlay.prepare_new_dialogue(gameBoard.currMap.start_script)
		await dOverlay.dialog_finished
	dOverlay.queue_free()
	GameState.change_state(self, GameState.gState.LOADING)
	guiManager.call_setup(gameBoard.depCap, gameBoard.forcedDeploy.keys(), gameBoard.currMap, gameBoard.unitObjs)
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
		"OpenDoorBtn": gameBoard.door_targeting()
		"OpenChestBtn": pass
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


func _on_returning_to_title():
	self.queue_free()


func trade_seeking(unit:Unit = Global.activeUnit):
	gameBoard.seek_trade(unit)


func call_trade(unit:Unit):
	guiManager.start_action_trade(unit)


func _on_cursor_moved(cell):
	guiManager.focusViewer.update_focus_viewer(cell)
#endregion


func _on_chest_opened(cell:Vector2i, contents:Array[Item], unit:Unit):
	#Unlock animation + SFX
	#Cycle Contents and add to unit inv
	#If inv full, send to storage and inform player
	pass

func _on_chest_stolen(cell:Vector2i, contents:Array[Item], unit:Unit):
	#Unlock animation + SFX
	#Stolen Sfx + prompt player what was stolen
	#add to unit inv
	#if inv full, check the fucking AI, they shouldn't be stealing with full inventories
	pass
