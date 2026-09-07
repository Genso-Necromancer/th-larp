extends Node
class_name MapManager

@onready var gameBoard :GameBoard = %Gameboard
@onready var guiManager :GUIManager = %GUIManager
var dialogue_overlay := preload("res://scenes/cutscenes/dialog_overlay.tscn")
const ITEM_PROMPT_SCENE := preload("res://scenes/GUI/ui_panels/item_prompt.tscn")
var dOverlay : DialogueOverlay
var current_map:String
var next_map:String
var is_suspended_load:=false
var load_initiated:= false
var soft_reset_in_progress := false
var end_state_screen_shown := false

func _ready():
	if gameBoard and guiManager: 
		gameBoard.guiManager = guiManager
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


func soft_reset_current_map() -> void:
	if soft_reset_in_progress:
		return
	var map_path := current_map
	if map_path == "" and gameBoard.current_map:
		map_path = gameBoard.current_map.get_scene_file_path()
	if map_path == "":
		push_warning("[MapManager]soft_reset_current_map: no current map path.")
		return
	soft_reset_in_progress = true
	load_initiated = false
	is_suspended_load = false
	next_map = ""
	if dOverlay and is_instance_valid(dOverlay):
		dOverlay.queue_free()
		dOverlay = null
	guiManager.reset_for_soft_reset()
	gameBoard.save_enum = Enums.SAVE_TYPE.NONE
	await gameBoard.free_map(false)
	current_map = map_path
	gameBoard.load_map(map_path)
	soft_reset_in_progress = false


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
	SignalTower.returning_to_title.connect(self._on_returning_to_title)
	SignalTower.chest_opened.connect(self._on_chest_opened)
	SignalTower.chest_stolen.connect(self._on_chest_stolen)
	SignalTower.item_used.connect(gameBoard._on_item_used)
	SignalTower.item_equipped.connect(gameBoard._on_item_equipped)
	#SignalTower.item_used.connect(guiManager._on_item_used)
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
	gameBoard.deployment_count_updated.connect(guiManager._on_gameboard_deploy_count_updated)
	gameBoard.formation_closed.connect(guiManager._on_gameboard_formation_closed)
	gameBoard.ui_returned.connect(guiManager._on_gameboard_ui_return)
	gameBoard.state_changed.connect(guiManager.DEBUG._on_gb_state_changed)
	gameBoard.state_changed.connect(self._on_gameboard_state_changed)
	gameBoard.step_changed.connect(guiManager.DEBUG._on_gb_step_changed)
	gameBoard.player_flow_changed.connect(guiManager._on_gameboard_player_flow_changed)
	gameBoard.target_focused.connect(guiManager._on_gameboard_target_focused)
	gameBoard.exp_display.connect(guiManager._on_gameboard_exp_display)
	gameBoard.toggle_prof.connect(guiManager._on_gameboard_toggle_prof)
	guiManager.gui_splash_finished.connect(self._on_gui_splash_finished)
	guiManager.start_the_justice.connect(gameBoard._on_action_weapon_selected)
	guiManager.formation_selected.connect(gameBoard._on_gui_formation_selected)
	guiManager.set_up_loaded.connect(gameBoard._on_gui_set_up_loaded)



#region scene loading
func _on_win_screen_win_finished() -> void:
	#start_load_screen()
	#await SignalTower.fade_out_complete
	GameState.change_state(self, GameState.gState.LOADING)
	load_cutscene()
	if gameBoard.current_map.end_script:
		#end_load_screen(0.1)
		dOverlay.prepare_new_dialogue(gameBoard.current_map.end_script)
		await dOverlay.dialog_finished
		#start_load_screen()
		#await SignalTower.fade_out_complete
	dOverlay.queue_free()
	gameBoard.free_map()
	#start_load_screen()
	#await SignalTower.fade_out_complete
	#


func _on_map_added(map:GameMap):
	end_state_screen_shown = false
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
	if gameBoard.current_map.start_script:
		dOverlay.prepare_new_dialogue(gameBoard.current_map.start_script)
		await dOverlay.dialog_finished
	dOverlay.queue_free()
	GameState.change_state(self, GameState.gState.LOADING)
	guiManager.call_setup(gameBoard.unit_loader.dep_cap, gameBoard.unit_loader.forced_deploy.keys(), gameBoard.current_map, gameBoard.unit_refs)
#endregion


#region GUI-Gameboard communication
func _on_returning_to_title():
	self.queue_free()


func _on_gameboard_state_changed(_state_keys:Array, state_index:int) -> void:
	if end_state_screen_shown:
		return
	match state_index:
		GameBoard.STATES.GAME_OVER:
			end_state_screen_shown = true
			guiManager._on_gameboard_player_lost()
		GameBoard.STATES.VICTORY:
			end_state_screen_shown = true
			guiManager._on_gameboard_player_win()


func trade_seeking(unit:Unit = Global.activeUnit):
	gameBoard.seek_trade(unit)


func call_trade(unit:Unit):
	guiManager.start_action_trade(gameBoard.activeUnit, unit)


func _on_cursor_moved(cell):
	guiManager.focusViewer.update_focus_viewer(cell)
#endregion


func _on_chest_opened(_cell:Vector2i, contents:Array[Item], currency:int, unit:Unit):
	if currency > 0:
		PlayerData.playerMon += currency
		await _show_chest_currency_prompt(currency)
	for item: Item in contents:
		var had_space := unit != null and unit.inventory.size() < unit.max_inv
		var granted_item: Item = await _grant_chest_item_to_unit(item, unit)
		if had_space and granted_item != null:
			await _show_chest_item_prompt(granted_item)
	_finish_player_chest_action(unit)


func _on_chest_stolen(_cell:Vector2i, contents:Array[Item], _currency:int, unit:Unit):
	for item: Item in contents:
		await _grant_chest_item_to_unit(item, unit)


func _grant_chest_item_to_unit(item: Item, unit: Unit) -> Item:
	if item == null or unit == null:
		return null
	var granted_item: Item = item.duplicate()
	if unit.inventory.size() >= unit.max_inv:
		if guiManager == null:
			push_warning("Chest item not granted because %s's inventory is full and no GuiManager was available." % [unit.unit_id])
			return null
		var chest_item_taken: bool = await guiManager.start_chest_overflow(unit, granted_item)
		return granted_item if chest_item_taken else null
	unit.inventory.append(granted_item)
	return granted_item


func _show_chest_item_prompt(item: Item) -> void:
	if item == null or guiManager == null:
		return
	var prompt: item_prompt = ITEM_PROMPT_SCENE.instantiate()
	guiManager.add_child(prompt)
	prompt.prompt_item(item)
	await _wait_for_item_prompt(prompt)


func _show_chest_currency_prompt(count:int) -> void:
	if count <= 0 or guiManager == null:
		return
	var prompt: item_prompt = ITEM_PROMPT_SCENE.instantiate()
	guiManager.add_child(prompt)
	prompt.prompt_currency(count)
	await _wait_for_item_prompt(prompt)


func _wait_for_item_prompt(prompt:item_prompt) -> void:
	if prompt == null:
		return
	var complete_callable := Callable(prompt, "_complete_signal")
	if not SignalTower.prompt_accepted.is_connected(complete_callable):
		SignalTower.prompt_accepted.connect(complete_callable, CONNECT_ONE_SHOT)
	GameState.change_state(prompt, GameState.gState.ACCEPT_PROMPT)
	await prompt.item_prompt_complete
	if SignalTower.prompt_accepted.is_connected(complete_callable):
		SignalTower.prompt_accepted.disconnect(complete_callable)
	prompt.queue_free()
	GameState.change_state(self, GameState.gState.LOADING)


func _finish_player_chest_action(unit:Unit) -> void:
	if unit != null:
		unit.on_chest = false
	if gameBoard == null:
		return
	if gameBoard.state == GameBoard.STATES.PLAYER_PHASE:
		gameBoard.turn_step = GameBoard.TURN_STEPS.END_PHASE
