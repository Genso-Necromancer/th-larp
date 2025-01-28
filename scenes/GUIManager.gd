extends Control
class_name GUIManager

signal gui_splash_finished
signal gui_closed
signal start_the_justice
signal guiReady
signal deploy_toggled(unitID, depStatus)
signal profile_called
signal formation_toggled
signal item_used
signal map_started
signal action_selected



@export var mapCursorPath : NodePath
@export var menuOffSet : int = 150

@onready var mapCursor := get_node(mapCursorPath)
@onready var originalPositionActX = $ActionMenu.position.x
@onready var originalPositionActY = $ActionMenu.position.y

@onready var foreCast = $CombatForecast




@onready var parent = get_parent()
@onready var GRANDDAD = parent.get_parent()
@onready var mainCon = GRANDDAD.get_parent()
@onready var GameState = mainCon.GameState

#states
enum sStates {
	HOME,
	DEPLOY,
	FORM,
	ROSTER,
	UNITOP,
	TRDSEEK,
	TRADING,
	SUPPLY,
	MANAGE,
	BEGIN}

var sState := sStates.HOME:
	set(value):
		sState = value
		print("sState Changed: ", sStates.keys()[value])

var opWepX
var opWepY
var originalPositionProfX
var originalPositionProfY

#preloads (this is how I should have been doing shit from the start!)
var turnTrackerRes = preload("res://scenes/turn_tracker.tscn")
var mapSetUp : MapGui
var rosterGrid : UnitRoster
var tradeScreen : TradeScreen
var unitProf : UnitProfile

#scenes
var turnTracker

#prompts
var isForecastPrompt = false

#nodes unassigned

var HUD : Node
var timer : Timer
var tween : Tween
var menuCursor : Control



#roster variables
var rosterData = UnitData.rosterData
var depCount = 0
var depLimit = 0
var forcedDep : Array = []
var rosterInit : bool = false
var unitObjs = Global.unitObjs
var activeBtn : Node

#focusTracking
var prevFocus

#trade variables
var trade1 : Unit
var trade2 : Unit

#nodes?
var actMenu

#states
@onready var gameState = mainCon.GameState
#@onready var _timer: Timer = $PanelContainerTimer

var windowMode = DisplayServer.window_get_mode()
#var Global.actionMenu = Global.actionMenu:
#	set(value):
#		Global.actionMenu = value
#		Global.actionMenu = value

		




var mouseSensitivity = 0.2
var mouseThreshold = 0.1
var profFocus


func _init():
	_load_assets()


func _ready():
	SignalTower.prompt_accepted.connect(_on_prompt_accepted)
	menuCursor.visible = false
	foreCast.visible = false
	_connect_asset_signals()
	_load_turn_tracker()
	
func update_labels(): #Use this to cascade assigning strings from XML to all hard loaded buttons HERE
	pass
	
	


func _on_prompt_accepted():
	_initiate_ai_sequence()
	
func _change_state(state):
	var prev = mainCon.previousSlave
	mainCon.previousSlave = mainCon.newSlave
	if state == mainCon.state: return
	elif state == mainCon.previousState: 
		mainCon.newSlave = prev
	else: mainCon.newSlave = [self]
	
	mainCon.previousState = mainCon.state
	mainCon.state = state
	
func _load_turn_tracker():
	turnTracker = turnTrackerRes.instantiate()
	add_child(turnTracker)
	
func _on_gameboard_turn_order_updated(turns):
	turnTracker.display_turns(turns)
	
func _on_jobs_done(id, node):
	var parent = get_parent()
	var mapMan = parent.get_parent()
	match id:
		#"Profile": 
			#unitProf = node
			#opWepX = node.position.x
			#opWepY = node.position.y
			#originalPositionProfX = unitProf.position.x
			#originalPositionProfY = unitProf.position.y
		
		"HUD": HUD = node
		"Cursor": menuCursor = node
		"Action": 
			actMenu = node
			
	
func reinitialize():
	if !menuCursor.wep_updated.is_connected(self.update_forecast):
		menuCursor.wep_updated.connect(self.update_forecast)
	

	
	
func _clear_active_btn():
	activeBtn.temp_font_change()
	activeBtn = null
	
func _set_active_btn(b) -> void:
	if !b:
		push_error("set_active_btn: Missing Button")
		return
	activeBtn = b
	activeBtn.temp_font_change("Selected")
	

func _set_trade_partners(b):
	trade1 = activeBtn.get_unit()
	trade2 = b.get_unit()
	#b.temp_font_change("Selected")
	
func _relocate_child(child, newParent):
	if child.get_parent():
		child.get_parent().remove_child(child)
	newParent.add_child(child)
	
		
#func accept_skip():
	#var failScreen : Control = $FailScreen
	#var winScreen : Control = $WinScreen
	#var expContainer : Control = $ExpGain
	#match mainCon.state:
		#GameState.ACCEPT_PROMPT:
			#if expContainer.visible:
				#expContainer.animation_skip()
			#
		#GameState.FAIL_STATE:
			#pass
		#GameState.WIN_STATE:
			#winScreen.close_win_screen()
		#GameState.SCENE_ACTIVE:
			#emit_signal("scene_skipped")
		
		

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
	if sState < 3 or sState > 7:  #profile should not open in these states.
		return
		
	#if sState != sStates.BEGIN:
		#menuCursor.toggle_visible()
	
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
		_change_state(GameState.GB_PROFILE)
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
		_change_state(mainCon.previousState)


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
		0: actMenu.open_weapons(reach)
		1: pass
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
	turnTracker.visible = false

func _on_gameboard_time_set():
	HUD.set_sun(Global.gameTime)

func _on_gameboard_turn_changed():
#	var sunMod = 0
	var sunRot = Global.rotationFactor
#	if sunDial.rotation_degrees >= (361 - sunRot):
#		sunMod = sunDial.rotation_degrees - (361 - sunRot)
#		sunMod += sunRot
#		sunDial.rotation_degrees = sunMod
#	else: sunDial.rotation_degrees += sunRot
#	sunDial.rotation_degrees += sunRot
#	clockLabel.set_text(str(Global.gameTime))
	HUD.update_sun(sunRot)


func _on_gameboard_gb_ready(_state):
	reinitialize()

#HERE
func _on_gameboard_exp_display(oldExp, expSteps, results, unitPrt, unitName):
	var expContainer : Control = $ExpGain
	
	_change_state(gameState.ACCEPT_PROMPT)
	expContainer.init_exp_display(oldExp, expSteps, results, unitPrt, unitName)
	expContainer.toggle_visibility()

func call_setup(dLimit, forced, map):
	var btns = mapSetUp.btnContainer
	mapSetUp.connect_buttons(self)
	mapSetUp.set_chapter(map.chapterNumber, map.title, map.get_objectives(), map.get_loss_conditions())
	mapSetUp.set_mon(UnitData.playerMon)
	mapSetUp.toggle_visible()
	_resignal_menuCursor(btns)
	
	sState = sStates.HOME
	forcedDep = forced
	depLimit = dLimit
	
	rosterGrid.init_roster(forcedDep, depLimit)
	_change_state(gameState.GB_SETUP)

func _load_assets():
	mapSetUp = load("res://scenes/GUI/MapSetup.tscn").instantiate()
	rosterGrid = load("res://scenes/GUI/unit_roster.tscn").instantiate()
	tradeScreen = load("res://scenes/trade_screen.tscn").instantiate()
	unitProf = load("res://scenes/profile.tscn").instantiate()
	
	add_child(mapSetUp)
	add_child(rosterGrid)
	add_child(tradeScreen)
	add_child(unitProf)
	
	
func _connect_asset_signals():
	unitProf.tooltips_on.connect(self._on_profile_tooltips_on)
	unitProf.tooltips_off.connect(self._on_profile_tooltips_off)

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
	menuCursor.visible = false
	mapSetUp.toggle_visible()
	sState = sStates.BEGIN
	turnTracker.visible = true
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
	var focus
	
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
		_set_trade_partners(b)
		rosterGrid.toggle_visible()
		_open_trade_menu()
	
func _on_gameboard_formation_closed():
	var btns = mapSetUp.btnContainer
	mapSetUp.toggle_visible()
	menuCursor.toggle_visible()
	#after revamping menuCursor code, make sure setup is it's parent
	sState = sStates.HOME
	emit_signal("formation_toggled")
	_resignal_menuCursor(btns)
	_change_state(GameState.GB_SETUP)

	
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
	var strip = true
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
	

func _on_trade_closed():
	trade1 = null
	trade2 = null
	rosterGrid.toggle_visible()
	_open_unit_options(activeBtn)

func _on_supply_pressed():
	var unit = activeBtn.get_unit()
	sState = sStates.SUPPLY
	_close_unit_options()
	rosterGrid.close_menu()
	tradeScreen.open_supply_menu(unit)
	
	
func _on_trd_focus_changed(p, b = null):
	_resignal_menuCursor(p)

func _on_manage_pressed():
	var unit = activeBtn.get_unit()
	sState = sStates.MANAGE
	_close_unit_options()
	rosterGrid.close_menu()
	tradeScreen.open_manage_menu(unit)


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



	
#########

#Action/Generic options menu functions

func _close_act_menu():
	foreCast.hide_fc()
	actMenu.close_menu()
	
func _on_action_menu_menu_closed():
	_strip_menuCursor()

func _on_gameboard_cell_selected(_cell): #cell is sent by signal for general use, but the specific cell selected is not currently needed
	actMenu.open_generic_menu()
	

func _on_action_menu_action_selected(selection):
	_strip_menuCursor()
	emit_signal("action_selected", selection)
			
			
			
func _on_gameboard_unit_move_ended(unit):
	actMenu.open_action_menu(unit)
	
func _on_gameboard_unit_deselected():
	_close_act_menu()

func _on_gameboard_menu_canceled():
	_close_act_menu()
	
func _on_gameboard_forecast_confirmed():
	if actMenu.visible:
		return
	#foreCast.hide_fc()
	_strip_menuCursor()
	emit_signal("start_the_justice")

func _on_gameboard_skill_target_canceled():
	actMenu.open_skill_menu()

func _on_action_menu_menu_opened(container):
	#_resignal_menuCursor(container)
	call_deferred("_resignal_menuCursor",container)
	
func _on_weapon_selected(button): #weapon can change after selection if mouse moves at wrong time. HERE Fix this, you absolute fucking retard
	#foreCast.hide_fc()
	_strip_menuCursor()
	emit_signal("start_the_justice", button)




#func _on_action_menu_weapon_changed(weapon):
	#pass # Replace with function body.

#Game State transitions

func _start_load_screen():
	pass

func _end_load_screen():
	pass

func play_splash(chNum:int, chTitle:String, timeString:String):
	var splashPlayer = load("res://scenes/GUI/chapter_splash.tscn").instantiate()
	add_child(splashPlayer)
	_change_state(GameState.ACCEPT_PROMPT)
	splashPlayer.splash_player_finished.connect(self._on_splash_player_finished)
	splashPlayer.play_splash(chNum, chTitle, timeString)


func _on_splash_player_finished():
	emit_signal("gui_splash_finished")


func _on_gameboard_player_lost():
	var failScreen = $FailScreen
	failScreen.fade_in_failure()
	_change_state(GameState.FAIL_STATE)

func _on_gameboard_player_win():
	var winScreen = $WinScreen
	winScreen.fade_in_win()
	_change_state(GameState.WIN_STATE)

func _on_win_screen_win_finished():
	_start_load_screen()
	turnTracker.free_tokens()

func _on_gameboard_map_loaded(_map):
	_end_load_screen()
	

func _on_animation_handler_sequence_complete():
	foreCast.hide_fc()
	turnTracker.visible = true


func _on_gameboard_sequence_initiated(_sequence):
	_change_state(GameState.SCENE_ACTIVE)
