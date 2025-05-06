extends Control
class_name GUIManager

signal gui_splash_finished
signal start_the_justice
signal deploy_toggled(unitID, depStatus)
signal formation_toggled
signal item_used
signal map_started
signal gui_action_menu_canceled

@onready var blocker : Panel = $PanelBlocker #used to block the map easily
@onready var HUD : Control = $HUD
#unvetted
@export var mapCursorPath : NodePath
@export var menuOffSet : int = 150
@onready var mapCursor := get_node(mapCursorPath)


@onready var parent = get_parent()
@onready var GRANDDAD = parent.get_parent()

#states
enum sStates {
	END,
	HOME,
	TRADING,
	UNITOP,
	SUPPLY,
	TRDSEEK,
	FORM,
	DEPLOY,
	MANAGE,
	ROSTER,
	BEGIN,
	}

var sState := sStates.HOME:
	set(value):
		
		match value: #Temporary, may be best to have HUD groups to control?
			sStates.FORM: focusViewer.enableViewer = true
			sStates.BEGIN: focusViewer.enableViewer = true
			_: 
				turnTracker.hide_self()
				focusViewer.enableViewer = false
			
			
		sState = value
		#print("sState Changed: ", sStates.keys()[value])

##preloads (this is how I should have been doing shit from the start!)
var turnTrackerRes = preload("res://scenes/turn_tracker.tscn")
var mapSetUp : MapGui
var rosterGrid : UnitRoster
var tradeScreen : TradeScreen
var unitProf : UnitProfile
var actMenu : ActionMenu
var foreCast : CombatForecast

##scenes
var turnTracker : TurnTracker

##prompts
var isForecastPrompt = false

##nodes unassigned
var timer : Timer
var tween : Tween
var menuCursor : MenuCursor
var focusViewer : FocusViewer
var chClock : ChapterClock



##roster variables
var rosterData = UnitData.rosterData
var depCount = 0
var depLimit = 0
var forcedDep : Array = []
var rosterInit : bool = false
var unitObjs = Global.unitObjs
var activeBtn : Node

##focusTracking
var prevFocus

##trade variables
var trade1 : Unit
var trade2 : Unit
var inSetup := false


var windowMode = DisplayServer.window_get_mode()
var mouseSensitivity = 0.2
var mouseThreshold = 0.1
var profFocus


func _init():
	_load_assets()


func _ready():
	SignalTower.prompt_accepted.connect(_on_prompt_accepted)
	SignalTower.sequence_complete.connect(self._on_animation_handler_sequence_complete)
	#menuCursor.visible = false
	#_add_hud_children()
	_connect_asset_signals()


func _add_hud_children():
	var hudElements := [chClock, turnTracker, focusViewer]
	
	for node in hudElements:
		_relocate_child(node, HUD)


func update_labels(): #Use this to cascade assigning strings from XML to all hard loaded buttons HERE
	pass


func _on_prompt_accepted():
	_initiate_ai_sequence()


func _on_jobs_done(id, node):
	match id:
		"HUD": HUD = node


func _clear_active_btn():
	activeBtn.temp_font_change()
	activeBtn = null


func _set_active_btn(b) -> void:
	if !b:
		push_error("set_active_btn: Missing Button")
		return
	activeBtn = b
	activeBtn.temp_font_change("Selected")


func _set_roster_trade_partners(b):
	trade1 = activeBtn.get_unit()
	trade2 = b.get_unit()
	#b.temp_font_change("Selected")


func _relocate_child(child, newParent):
	if child.get_parent():
		child.get_parent().remove_child(child)
	newParent.add_child(child)


func regress_menu():
	match sState:
		sStates.HOME: pass
		sStates.DEPLOY: _close_unit_menu()
		sStates.ROSTER: _close_unit_menu()
		sStates.UNITOP: _close_unit_options()
		sStates.TRDSEEK: _open_unit_options(activeBtn)
		sStates.TRADING: tradeScreen.regress_trade()
		sStates.SUPPLY: tradeScreen.regress_trade()
		sStates.MANAGE: tradeScreen.regress_trade()


func _font_color_change(b, style):
	var fColor
	match style:
		"Deployed": fColor = Color(1,1,1)
		"Undeployed": fColor = Color(0.194, 0.194, 0.194)
		"Selected": fColor = Color(0.776, 0.675, 0)
		"Forced": fColor = Color(0, 0.62, 0)
	b.add_theme_color_override("font_color", fColor)
	b.add_theme_color_override("font_pressed_color", fColor)
	b.add_theme_color_override("font_hover_color", fColor)
	b.add_theme_color_override("font_focus_color", fColor)
	b.add_theme_color_override("font_hover_pressed_color", fColor)


func _snap_to_cursor(node): #bug gy save for later
	var cursorPos = mapCursor.to_local(mapCursor.position)
	var newPos
	
	newPos = cursorPos
#	newPos.x += menuOffSet
	print("Node " + str(node.global_position))
	print("cursor " + str(cursorPos))
	print("new " + str(newPos))
	node.global_position = newPos
	print("Node " + str(node.global_position))


func _on_gameboard_toggle_prof():
	toggle_profile()
		
			
func toggle_profile() -> void: 
	if sState < sStates.TRDSEEK: return #profile should not open in these states.
	
	if unitProf.visible and Global.focusUnit != profFocus:
		update_prof()
		profFocus = Global.focusUnit
	elif unitProf.toolTipMode:
		toggle_tooltips()
	elif !unitProf.visible:
		prevFocus = get_viewport().gui_get_focus_owner()
		
		if prevFocus:
			prevFocus.release_focus()
		update_prof()
		_resignal_menuCursor_array(unitProf.focusLabels, 2)
		menuCursor.visible = false
		unitProf.toggle_profile()
		profFocus = Global.focusUnit
		rosterGrid.set_bar_focus(false)
		GameState.change_state(self, GameState.gState.GB_PROFILE)
		focusViewer.visible = false
	else:
		_strip_menuCursor(false, unitProf.focusLabels)
		rosterGrid.set_bar_focus(true)
		if sState != sStates.BEGIN and sState != sStates.FORM: 
			menuCursor.visible = true
		if prevFocus:
			var button = prevFocus
			button.call_deferred("grab_focus")
		prevFocus = null
		unitProf.toggle_profile()
		GameState.change_state()
		focusViewer.visible = true


func update_prof():
	unitProf.update_prof()
	
	
func toggle_tooltips():
	unitProf.toggle_controller_mode()

func _on_profile_tooltips_on():
	menuCursor.visible = true
	
func _on_profile_tooltips_off():
	menuCursor.visible = false


func _on_gameboard_target_focused( mode : int, reach: Array = [-1, -1]):
	_swap_to_forecast()
	match mode:
		0: 
			GameState.change_state(self, GameState.gState.GB_COMBAT_FORECAST)
			actMenu.open_weapon_select(reach)
		1: 
			GameState.change_state(self, GameState.gState.GB_COMBAT_FORECAST)
			actMenu.open_skill_confirm()
		2: _ai_sequence_check()
	
func _ai_sequence_check():
	isForecastPrompt = true
	match Options.aiForecastPrompt:
		0: pass
		1: _prompt_delay()


func _prompt_delay():
	var time = Options.promptDelay
	await get_tree().create_timer(time).timeout
	_initiate_ai_sequence()


func _initiate_ai_sequence():
	if isForecastPrompt:
		isForecastPrompt = false
		emit_signal("start_the_justice")


func _swap_to_forecast():
	var fc = $CombatForecast
	fc.show_fc()
	turnTracker.hide_self()


#HERE
func _on_gameboard_exp_display(oldExp, expSteps, results, unitPrt, unitName):
	var expContainer : Control = $ExpGain
	
	GameState.change_state(self, GameState.gState.ACCEPT_PROMPT)
	expContainer.init_exp_display(oldExp, expSteps, results, unitPrt, unitName)
	expContainer.toggle_visibility()

func call_setup(dLimit, forced, map):
	var btns = mapSetUp.btnContainer
	inSetup = true
	mapSetUp.connect_buttons(self)
	mapSetUp.free_previous_obj()
	mapSetUp.call_deferred("set_chapter",map.chapterNumber, map.title, map.get_objectives(), map.get_loss_conditions())
	mapSetUp.set_mon(UnitData.playerMon)
	mapSetUp.toggle_visible()
	menuCursor.resignal_cursor(btns.get_children())
	sState = sStates.HOME
	forcedDep = forced
	depLimit = dLimit
	rosterGrid.init_roster(forcedDep, depLimit)
	GameState.change_state(self, GameState.gState.GB_SETUP)

func _load_assets():
	mapSetUp = load("res://scenes/GUI/MapSetup.tscn").instantiate()
	rosterGrid = load("res://scenes/GUI/unit_roster.tscn").instantiate()
	tradeScreen = load("res://scenes/trade_screen.tscn").instantiate()
	unitProf = load("res://scenes/profile.tscn").instantiate()
	actMenu = load("res://scenes/GUI/action_menu.tscn").instantiate()
	foreCast = load("res://scenes/combat_forecast.tscn").instantiate()
	menuCursor = load("res://scenes/GUI/menu_cursor.tscn").instantiate()
	focusViewer = load("res://scenes/GUI/cursor_focus_viewer.tscn").instantiate()
	chClock = load("res://scenes/GUI/chapter_clock.tscn").instantiate()
	turnTracker = turnTrackerRes.instantiate()
	
	add_child(chClock)
	add_child(turnTracker)
	add_child(focusViewer)
	add_child(mapSetUp)
	add_child(foreCast)
	add_child(actMenu)
	add_child(rosterGrid)
	add_child(tradeScreen)
	add_child(unitProf)
	add_child(menuCursor)
	chClock.add_to_group("hud")
	
	menuCursor.visible = false


func _connect_asset_signals():
	unitProf.tooltips_on.connect(self._on_profile_tooltips_on)
	unitProf.tooltips_off.connect(self._on_profile_tooltips_off)
	actMenu.action_menu_canceled.connect(self._on_action_menu_canceled)
	actMenu.action_menu_selected.connect(GRANDDAD._on_action_menu_selected)
	actMenu.action_menu_item_pressed.connect(self._on_action_item_pressed)
	actMenu.action_menu_trade_pressed.connect(self._on_action_trade_pressed)
	#actMenu.action_menu_ofuda_open.connect(self._on_action_ofuda_open)
	
#SetUp Buttons
func _on_btn_deploy_pressed():
	#var sCountPnl = $SetUpMain/SetUpGrid/SetUpPnl2
	mapSetUp.toggle_visible()
	sState = sStates.DEPLOY
	_open_unit_menu()
	
	
func _on_frm_btn_pressed():
	mapSetUp.toggle_visible()
	menuCursor.toggle_visible()
#	_relocate_child(unitProf, self)
	sState = sStates.FORM
	
	emit_signal("formation_toggled")
	
	
func _on_mng_btn_pressed():
	mapSetUp.toggle_visible()
	sState = sStates.ROSTER
	_open_unit_menu()


func _on_begin_btn_pressed():
	inSetup = false
	menuCursor.visible = false
	mapSetUp.toggle_visible()
	sState = sStates.BEGIN
	#turnTracker.unhide_self()
	chClock.visible = true
	emit_signal("map_started")


func _on_status_btn_pressed():
	pass


func _open_unit_menu():
	match sState:
		sStates.DEPLOY: rosterGrid.open_menu(0)
		sStates.ROSTER: rosterGrid.open_menu(1)
	
	_assign_cursor_to_roster()
	update_prof()


func _assign_cursor_to_roster():
	var btns : Array = []
	for bar in rosterGrid.unitBars:
		btns.append(bar.button)
		_connect_unit_btn(bar)
	#if !activeBtn: Global.focusUnit = rosterGrid.unitBars[0].get_unit()
	#else: Global.focusUnit = activeBtn.get_unit()
	_resignal_menuCursor_array(btns, 1)

func _close_unit_menu():
	var btns = mapSetUp.btnContainer
	rosterGrid.close_menu()
	mapSetUp.toggle_visible()
	_resignal_menuCursor(btns)
	sState = sStates.HOME
	

func _toggle_unit(b):
	#metadata: force, deployed; unit
	var state = b.buttonState
	var unit = b.get_unit()
	match state:
		"Forced": #create feedback for user when unable to deploy forced unit
			print("Unit is Forced")
		"Deployed":
			b.set_state("Undeployed")
			emit_signal("deploy_toggled", unit, true)
		"Undeployed":
			if depCount < depLimit:
				b.set_state("Deployed")
				emit_signal("deploy_toggled", unit, false)
			else:
				#create feedback for user
				print("Deploy Limit Reached")
		
	
func _on_gameboard_deploy_toggled(deployed):
	depCount = deployed
	rosterGrid.update_deploy_count(deployed)

func _roster_focus_entered(unit):
	Global.focusUnit = unit
	update_prof()

func _connect_unit_btn(bar):
	var unit = bar.get_unit()
	var b = bar.button
	
	if !b.pressed.is_connected(self._roster_btn_pressed.bind(bar)):
		b.pressed.connect(self._roster_btn_pressed.bind(bar))
	
	if !b.focus_entered.is_connected(self._roster_focus_entered.bind(unit)):
		b.focus_entered.connect(self._roster_focus_entered.bind(unit))


#Menu cursor reparenting and resignaling
func _resignal_menuCursor(p, strip = true, oldP = menuCursor.menu_parent):
	var i = 0
	var btns = p.get_children()
	#var focus
	
	if strip and oldP != null:
		_strip_menuCursor(oldP)
	menuCursor.visible = true
	menuCursor.menu_parent = p
	for b in btns:
		_connect_btn_to_cursor(b)
		
	while btns.size() > i and btns[i].disabled == true:
		i += 1
		
	if btns.size() > i and !btns[i].has_focus(): 
		btns[i].call_deferred("grab_focus")
		#menuCursor.call_deferred("set_cursor", btns[i])
	#btns[i].call_deferred("grab_focus")
	
	#print("resignal: ")
	#print("-Button: " + str(btns[i].get_global_position()))

func _resignal_menuCursor_array(btns:Array, mode:= 0):
	var i = 0
	var focus
	if btns.is_empty(): return
	menuCursor.visible = true
	for b in btns:
		_connect_btn_to_cursor(b)
		
	while btns.size() > i and !btns[i].visible:
		i += 1
	
	match mode:
		0: focus = btns[0]
		1: 
			if !activeBtn: focus = btns[i]
			else: focus = activeBtn.button
		2: focus = false
	
	if focus and btns.size() > i: 
		focus.call_deferred("grab_focus")
	
	
func _connect_btn_to_cursor(b):
	if b.mouse_entered.is_connected(self._on_mouse_entered.bind(b)): #incase of order switching, this must be reconnected
		b.mouse_entered.disconnect(self._on_mouse_entered.bind(b))
	b.mouse_entered.connect(self._on_mouse_entered.bind(b))
	if b.focus_entered.is_connected(menuCursor.set_cursor.bind(b)): #incase of order switching, this must be reconnected
		b.focus_entered.disconnect(menuCursor.set_cursor.bind(b))
	b.focus_entered.connect(menuCursor.set_cursor.bind(b))
	
	
	
func _strip_menuCursor(p = menuCursor.menu_parent, array: Array = []):
	var btns 
	if array.size()>0: btns = array
	else: btns = p.get_children()
	for b in btns:
		if b.mouse_entered.is_connected(self._on_mouse_entered.bind(b)): 
			b.mouse_entered.disconnect(self._on_mouse_entered.bind(b))
		if b.focus_entered.is_connected(menuCursor.set_cursor.bind(b)):
			b.focus_entered.disconnect(menuCursor.set_cursor.bind(b))
	menuCursor.visible = false
	
func _on_mouse_entered(b):
	b.call_deferred("grab_focus")
########

#Set-up Menu Functions
func _roster_btn_pressed(b):
	match sState:
		sStates.DEPLOY: _toggle_unit(b)
		sStates.ROSTER: _open_unit_options(b)
		sStates.TRDSEEK: _trade_unit_select_roster(b)


func _trade_unit_select_roster(b) -> void:
	if b.get_unit() == activeBtn.get_unit(): return
	else: 
		_set_roster_trade_partners(b)
		rosterGrid.toggle_visible()
		_open_trade_menu()
	
func _on_gameboard_formation_closed():
	var btns :Array = mapSetUp.btnContainer.get_children()
	mapSetUp.toggle_visible()
	menuCursor.toggle_visible()
	#after revamping menuCursor code, make sure setup is it's parent
	sState = sStates.HOME
	emit_signal("formation_toggled")
	menuCursor.resignal_cursor(btns)
	#_resignal_menuCursor(btns)
	GameState.change_state(self, GameState.gState.GB_SETUP)

	
func _open_unit_options(b):
	sState = sStates.UNITOP
	_set_active_btn(b)
	var cursorParent = rosterGrid.open_unit_manager()
	_resignal_menuCursor(cursorParent)
	

func _close_unit_options():
	rosterGrid.close_unit_manager()
	match sState:
		sStates.TRDSEEK: _assign_cursor_to_roster()
		sStates.UNITOP: 
			sState = sStates.ROSTER
			_assign_cursor_to_roster()
			_clear_active_btn()
			
			
	
func _on_trade_pressed():
	sState = sStates.TRDSEEK
	_close_unit_options()


func _open_trade_menu():
	#var strip = true
	sState = sStates.TRADING
	tradeScreen.open_trade_menu(trade1, trade2)


func _on_item_list_filled(buttons, ignoreFocus := false):
	var m = 0
	if ignoreFocus:
		m = 2
	_resignal_menuCursor_array(buttons, m)


func _on_item_selected(b):
	var cursorDest = tradeScreen.find_cursor_destionation(b)
	#_font_color_change(b, "Selected")
	cursorDest.call_deferred("grab_focus")
	

func _on_trade_closed() -> void:
	if inSetup:
		rosterGrid.toggle_visible()
		_open_unit_options(activeBtn)
	elif trade1 and trade2:
		menuCursor.visible = false
		GameState.change_state()
		GRANDDAD.trade_seeking()
	else:
		menuCursor.visible = false
		GameState.change_state()
		actMenu.return_previous_state()
	trade1 = null
	trade2 = null


func _on_supply_pressed():
	var unit = activeBtn.get_unit()
	sState = sStates.SUPPLY
	_close_unit_options()
	rosterGrid.close_menu()
	tradeScreen.open_supply_menu(unit)


func _on_trd_focus_changed(p, _b = null):
	menuCursor.resignal_cursor(p.get_children())

func _on_manage_pressed():
	var unit = activeBtn.get_unit()
	sState = sStates.MANAGE
	_close_unit_options()
	rosterGrid.close_menu()
	tradeScreen.open_manage_menu(unit)


func _on_action_item_pressed(unit:Unit):
	GameState.change_state(self,GameState.gState.GB_SETUP)
	sState = sStates.MANAGE
	tradeScreen.open_manage_menu(unit)


#func _on_action_ofuda_open(unit:Unit):
	#GameState.change_state(self,GameState.gState.GB_SETUP)
	#sState = sStates.MANAGE
	#tradeScreen.open_manage_menu(unit)


func _on_action_trade_pressed(unit:Unit):
	trade1 = unit
	GRANDDAD.trade_seeking(unit)


func start_action_trade(trade_target:Unit):
		GameState.change_state(self, GameState.gState.GB_SETUP)
		sState = sStates.TRADING
		trade1 = Global.activeUnit
		trade2 = trade_target
		_open_trade_menu()


func _on_use_lb_pressed():
	var unit = activeBtn.get_meta("unit")
	var setUp = $SetUpMain/SetUpGrid
	sState = sStates.MANAGE
	_close_unit_options()
	setUp.visible = false
	tradeScreen.open_use_menu(unit)


func _on_profile_request(newParent):
	_relocate_child(unitProf, newParent)
	_on_gameboard_toggle_prof()


func _on_item_used(unit, item):
	emit_signal("item_used", unit, item)


#Action/Generic options menu functions
func regress_act_menu():
	actMenu.return_previous_state()
	
func _on_action_menu_canceled():
	#_strip_menuCursor()
	emit_signal("gui_action_menu_canceled")


func cancel_forecast():
	#GameState.change_state(self, GameState.gState.GB_ACTION_MENU)
	turnTracker.unhide_self()
	foreCast.hide_fc()
	regress_act_menu()


func _on_gameboard_cell_selected(_cell): #cell is sent by signal for general use, but the specific cell selected is not currently needed
	GameState.change_state(self, GameState.gState.GB_ACTION_MENU)
	actMenu.open_as_options()


func _on_gameboard_unit_move_ended(unit):
	GameState.change_state(self, GameState.gState.GB_ACTION_MENU)
	actMenu.open_as_action(unit)


func _on_gameboard_targeting_canceled():
	GameState.change_state(self, GameState.gState.GB_ACTION_MENU)
	regress_act_menu()


func _on_gameboard_forecast_confirmed():
	if actMenu.visible:
		return
	#foreCast.hide_fc()
	_strip_menuCursor()
	emit_signal("start_the_justice")


func _on_action_menu_menu_opened(container):
	#_resignal_menuCursor(container)
	call_deferred("_resignal_menuCursor",container)


func _on_weapon_selected(button): #weapon can change after selection if mouse moves at wrong time. HERE Fix this, you absolute fucking retard
	#foreCast.hide_fc()
	_strip_menuCursor()
	emit_signal("start_the_justice", button)


func fade_map_out():
	SignalTower.fader_fade_out.emit()


func fade_map_in():
	SignalTower.fader_fade_in.emit()


func play_splash(chNum:int, chTitle:String, timeString:String):
	var splashPlayer = load("res://scenes/GUI/chapter_splash.tscn").instantiate()
	add_child(splashPlayer)
	GameState.change_state(self, GameState.gState.ACCEPT_PROMPT)
	splashPlayer.splash_player_finished.connect(self._on_splash_player_finished)
	splashPlayer.play_splash(chNum, chTitle, timeString)


func _on_splash_player_finished():
	emit_signal("gui_splash_finished")


func _on_gameboard_player_lost():
	var failScreen = $FailScreen
	sState = sStates.END
	failScreen.fade_in_failure()
	GameState.change_state(self, GameState.gState.FAIL_STATE)


func _on_gameboard_player_win():
	var winScreen = $WinScreen
	sState = sStates.END
	winScreen.fade_in_win()


func _on_win_screen_win_finished():
	turnTracker.free_tokens()


func _on_animation_handler_sequence_complete():
	foreCast.hide_fc()
	turnTracker.unhide_self()


func _on_gameboard_sequence_initiated(_sequence):
	GameState.change_state(self, GameState.gState.SCENE_ACTIVE)

#region turn tracker signal routing
func _on_turn_changed()->void:
	turnTracker.change_turn()
	

func _on_new_round(turn_order:Array[StringName])->void:
	turnTracker.display_turns(turn_order)


func _on_turn_added(team:StringName)->void:
	turnTracker.add_turn(team)


func _on_turn_removed(team:StringName)->void:
	turnTracker.remove_turn(team)

#endregion
