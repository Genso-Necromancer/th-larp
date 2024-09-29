extends Control
class_name GUIManager

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

#remove eventually
@onready var weaponFrame = $ActionMenu/m/m/c/v
@onready var weaponBox = $ActionMenu/m
@onready var ActionBox = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer
@onready var foreCast = $CombatForecast

#these too
@onready var AtkB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/AtkBtn
@onready var SklB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/SklBtn
@onready var WaitB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/WaitBtn
@onready var EndB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/EndBtn


@onready var parent = get_parent()
@onready var GRANDDAD = parent.get_parent()
@onready var mainCon = GRANDDAD.get_parent()
@onready var GameState = mainCon.GameState


var opWepX
var opWepY
var originalPositionProfX
var originalPositionProfY

#preloads (this is how I should have been doing shit from the start!)
var turnTrackerRes = preload("res://scenes/turn_tracker.tscn")

#scenes
var turnTracker

#nodes unassigned
var unitProf : Node
var setUpMenu : Node
var HUD : Node
var timer : Timer
var tween : Tween
var menuCursor : Control



#roster variables
var rosterData = UnitData.rosterData
var depCount = 0
var depLimit = 0
var forcedDep : Array = []
var sState = null
var rosterInit : bool = false
enum sStates {
	HOME,
	DEPLOY,
	FORM,
	MANAGE,
	UNITOP,
	TRDSEEK,
	TRADING,
	SUPPLY,
	USE,
	BEGIN}
var unitObjs = Global.unitObjs
var activeBtn : Node

#nodes?
var actMenu
var tradeScn : Node



#states
@onready var gameState = mainCon.GameState
var currentButton: Button = null
#@onready var _timer: Timer = $Timer

var windowMode = DisplayServer.window_get_mode()
#var Global.actionMenu = Global.actionMenu:
#	set(value):
#		Global.actionMenu = value
#		Global.actionMenu = value

		




var mouseSensitivity = 0.2
var mouseThreshold = 0.1
var profFocus




func _ready():
	
	menuCursor.visible = false
	foreCast.visible = false
	_load_turn_tracker()
	
func update_labels(): #Use this to cascade assigning strings from XML to all hard loaded buttons HERE
	pass
	
func _change_state(state):
	mainCon.newSlave = [self]
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
		"Profile": 
			unitProf = node
			opWepX = node.position.x
			opWepY = node.position.y
			originalPositionProfX = unitProf.position.x
			originalPositionProfY = unitProf.position.y
		"SetUp": setUpMenu = node
		"HUD": HUD = node
		"Trade": tradeScn = node
		"Cursor": menuCursor = node
		"Action": 
			actMenu = node
			
	
func reinitialize():
	if !menuCursor.wep_updated.is_connected(self.update_forecast):
		menuCursor.wep_updated.connect(self.update_forecast)
	

	
	
func _clear_active_btn():
	if activeBtn.get_meta("deployed"):
		_font_color_change(activeBtn, "Default")
	else:
		_font_color_change(activeBtn, "Undeployed")
	activeBtn = null
	
func _set_active_btn(b):
	activeBtn = b
	_font_color_change(activeBtn, "Selected")
	
func _relocate_child(child, newParent):
	if child.get_parent():
		child.get_parent().remove_child(child)
	newParent.add_child(child)
	
		
func accept_skip():
	var failScreen : Control = $FailScreen
	var winScreen : Control = $WinScreen
	var expContainer : Control = $ExpGain
	match true:
		expContainer.visible:
			expContainer.animation_skip()
			
		failScreen.visible:
			pass
		winScreen.visible:
			winScreen.close_win_screen()
		
		

func regress_menu():
	match sState:
		sStates.HOME: pass
		sStates.DEPLOY: _close_unit_menu()
		sStates.MANAGE: _close_unit_menu()
		sStates.UNITOP: _close_unit_options()
		sStates.TRDSEEK: _open_unit_options(activeBtn)
		sStates.TRADING: tradeScn.regress_trade()
		sStates.SUPPLY: tradeScn.regress_trade()
		sStates.USE: tradeScn.regress_trade()

func _font_color_change(b, style):
	var fColor
	match style:
		"Default": fColor = Color(1,1,1)
		"Undeployed": fColor = Color (0,0,1)
		"Selected": fColor = Color(1,0,0)
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
	



func _on_gameboard_toggle_prof(): #Needs filtering for while in set-up menu. Perhaps a filter function should be called first.
#	print("GUI",state, unitId)
	var profVis = unitProf.visible
	if sState == sStates.HOME: #profile should not open on set up home menu
		return
	if profVis and Global.focusUnit != profFocus:
		update_prof()
		profFocus = Global.focusUnit
	else:
		
		if unitProf.visible == false:
			update_prof()
			unitProf.visible = true
			profFocus = Global.focusUnit
			
		else:
			unitProf.visible = false

func update_prof():
	emit_signal("profile_called")
		
func _on_gameboard_target_focused(cmbData : Dictionary, mode : int, range: Array = [-1, -1]):
	var fc = $CombatForecast
	fc.update_fc(cmbData)
	fc.show_fc()
	match mode:
		0: actMenu.open_weapons(range)
		1: pass
		

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

func _on_gameboard_call_setup(dLimit, forced):
	var setUpWin = $SetUpMain
	var homeMenu = $SetUpMain/SetUpGrid/SetUpPnl1/M/VBSet
	var infoPanel = $SetUpMain/SetUpGrid/SetUpPnl2
	var homeBtns = homeMenu.get_children()
	var i = 0
	sState = sStates.HOME
	forcedDep = forced
	depLimit = dLimit
	setUpWin.visible = true
	homeMenu.visible = true
	_change_state(gameState.GB_SETUP)
	infoPanel.visible = false
	_resignal_menuCursor(homeMenu)
	


func _on_btn_deploy_pressed():
	var sCountPnl = $SetUpMain/SetUpGrid/SetUpPnl2
	sCountPnl.visible = false
	sState = sStates.DEPLOY
	_open_unit_menu()

func _open_unit_menu():
	var homeMenu = $SetUpMain/SetUpGrid/SetUpPnl1/M/VBSet
	var grdRost = $SetUpMain/SetUpGrid/SetUpPnl1/M/GRDRost
	var btns : Array
#	var infoPanel = $SetUpMain/SetUpGrid/SetUpPnl2
	var grid = setUpMenu.get_children()
	homeMenu.visible = false
#	infoPanel.visible = true
	
	if !rosterInit:
		var first: Button = null
		var units = UnitData.rosterData
		var filled = 0
		var i = 0
		var unitData = UnitData.unitData
		
		for unit in units:
			var b = Button.new()
			
			b.set_text(str(unitData[unit].Profile.UnitName))
			if forcedDep.has(unit):
				b.set_meta("forced", true)
				b.set_meta("deployed", true)
				
			elif filled < depLimit:
				b.set_meta("forced", false)
				b.set_meta("deployed", true)
				filled += 1
			else:
				b.set_meta("forced", false)
				b.set_meta("deployed", false)
				_font_color_change(b, "Undeployed")
			b.set_action_mode(BaseButton.ACTION_MODE_BUTTON_PRESS)
			b.set_mouse_filter(Control.MOUSE_FILTER_PASS)
			b.set_meta("unit", unitObjs[unit])
			b.set_button_icon(unitData[unit].Profile.Prt)
			b.set_expand_icon(false)
			grdRost.add_child(b)
			_connect_unit_btn(b, i)
			i += 1
			rosterInit = true
			btns = grdRost.get_children()
	else:
		var i = 0
		var dQue : Array = []
		var unQue : Array = []
		btns = grdRost.get_children()
		#create match case for if supply or deploy, reconnecting what the unit's "button" does when pressed
		for b in btns:
			var isDeployed = b.get_meta("deployed")
			var isForced = b.get_meta("forced")
			
			if isForced:
				grdRost.move_child(b, i)
				_connect_unit_btn(b, i)
				i += 1
			elif isDeployed:
				dQue.append(b)
			else:
				unQue.append(b)
		for b in dQue:
			grdRost.move_child(b, i)
			_connect_unit_btn(b, i)
			i += 1			
		for b in unQue:
			grdRost.move_child(b, i)
			_connect_unit_btn(b, i)
			i += 1
		btns = grdRost.get_children()
	
	_resignal_menuCursor(grdRost)
	Global.focusUnit = btns[0].get_meta("unit")
	update_prof()
	grdRost.visible = true


func _close_unit_menu():
	var homeMenu = $SetUpMain/SetUpGrid/SetUpPnl1/M/VBSet
	var grdRost = $SetUpMain/SetUpGrid/SetUpPnl1/M/GRDRost
	var homeBtns = homeMenu.get_children()
	var sCountPnl = $SetUpMain/SetUpGrid/SetUpPnl2
	sCountPnl.visible = false
#	unitProf.visible = false
	grdRost.visible = false
	homeMenu.visible = true
	_resignal_menuCursor(homeMenu)
#	homeBtns[0].grab_focus()
	sState = sStates.HOME

func _toggle_unit(b):
	#metadata: force, deployed; unit
	var forced = b.get_meta("forced")
	var deployed = b.get_meta("deployed")
	var unit = b.get_meta("unit")
	
	
	if forced:
		#create feedback for user when unable to deploy forced unit
		print("Unit is Forced")
		return
	
	if deployed:
		_font_color_change(b, "Undeployed")
		emit_signal("deploy_toggled", unit, deployed)
		b.set_meta("deployed", false)
	elif !deployed and depCount < depLimit:
		_font_color_change(b, "Default")
		emit_signal("deploy_toggled", unit, deployed)
		b.set_meta("deployed", true)
	
func _on_gameboard_deploy_toggled(deployed, limit):
	var label = $SetUpMain/SetUpGrid/SetUpPnl2/M/DLmtLbl
	depLimit = limit
	depCount = deployed
	label.set_text(str(deployed) + " / " + str(limit))

func _roster_mouse_entered(unit):
	Global.focusUnit = unit
	update_prof()

func _connect_unit_btn(b, i):
	var unit = b.get_meta("unit")
	
	#disconnect signals
	if b.button_down.is_connected(self._toggle_unit.bind(b)):
		b.button_down.disconnect(self._toggle_unit.bind(b))
	if b.button_down.is_connected(self._roster_btn_pressed.bind(b)):
		b.button_down.disconnect(self._roster_btn_pressed.bind(b))
	
	if !b.mouse_entered.is_connected(self._roster_mouse_entered.bind(unit)): #only needs to be connected once
		b.mouse_entered.connect(self._roster_mouse_entered.bind(unit))
	
	#match and connect appropriate signals
	match sState:
		sStates.DEPLOY: b.button_down.connect(self._toggle_unit.bind(b))
		sStates.MANAGE: b.button_down.connect(self._roster_btn_pressed.bind(b))




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
		
	if btns.size() > i: menuCursor.call_deferred("set_cursor", btns[i])
	#btns[i].call_deferred("grab_focus")
	
	#print("resignal: ")
	#print("-Button: " + str(btns[i].get_global_position()))
	
	
func _connect_btn_to_cursor(b):
	if b.mouse_entered.is_connected(self._on_mouse_entered.bind(b)): #incase of order switching, this must be reconnected
		b.mouse_entered.disconnect(self._on_mouse_entered.bind(b))
	b.mouse_entered.connect(self._on_mouse_entered.bind(b))
	if b.focus_entered.is_connected(menuCursor.set_cursor.bind(b)): #incase of order switching, this must be reconnected
		b.focus_entered.disconnect(menuCursor.set_cursor.bind(b))
	b.focus_entered.connect(menuCursor.set_cursor.bind(b))
	
	
	
func _strip_menuCursor(p = menuCursor.menu_parent):
	var btns = p.get_children()
	for b in btns:
		if b.mouse_entered.is_connected(self._on_mouse_entered.bind(b)): 
			b.mouse_entered.disconnect(self._on_mouse_entered.bind(b))
		if b.focus_entered.is_connected(menuCursor.set_cursor.bind(b)):
			b.focus_entered.disconnect(menuCursor.set_cursor.bind(b))
	menuCursor.visible = false
	
func _on_mouse_entered(b):
	b.grab_focus()
########

#Set-up Menu Functions
func _roster_btn_pressed(b):
	match sState:
		sStates.MANAGE: _open_unit_options(b)
		sStates.TRDSEEK: _open_trade_menu(b)

func _on_frm_btn_pressed():
	setUpMenu.visible = false
	menuCursor.visible = false
#	_relocate_child(unitProf, self)
	sState = sStates.FORM
	emit_signal("formation_toggled")


func _on_gameboard_formation_closed():
	var homeMenu = $SetUpMain/SetUpGrid/SetUpPnl1/M/VBSet
	var homeBtns = homeMenu.get_children()
	setUpMenu.visible = true
	menuCursor.visible = true
	#after revamping menuCursor code, make sure setup is it's parent
	sState = sStates.HOME
	emit_signal("formation_toggled")
	homeBtns[1].grab_focus()
	mainCon.newSlave = [self]
	mainCon.state = GameState.GB_SETUP
	
	
func _on_mng_btn_pressed():
	sState = sStates.MANAGE
	_open_unit_menu()
	
func _open_unit_options(b):
	var unit = b.get_meta("unit")
	var mngCont = $SetUpMain/MngOptPnl
	var mngPnl = $SetUpMain/MngOptPnl
	var unitData = unit.unitData
	var btns = mngPnl.get_buttons()
	var menu = mngPnl.get_menu()
	var noWep = true
	var noUse = true
	var noInv = true
	_set_active_btn(b)
	sState = sStates.UNITOP
	mngCont.visible = true
	_resignal_menuCursor(menu)
	for item in unitData.Inv:
		if unit.check_valid_weapon(item):
			noWep = false
		
		if !noWep:
			break
	
	btns[2].disabled = noWep
	btns[3].disabled = tradeScn._check_usable_inv(unit)
		
func _return_roster_focus():
	var grdRost = $SetUpMain/SetUpGrid/SetUpPnl1/M/GRDRost
	_resignal_menuCursor(grdRost)

func _close_unit_options():
	var mngPnl = $SetUpMain/MngOptPnl
	mngPnl.visible = false
	match sState:
		sStates.TRDSEEK: _return_roster_focus()
		sStates.UNITOP: 
			sState = sStates.MANAGE
			_clear_active_btn()
			_return_roster_focus()
			
	

func _on_trade_lb_pressed():
	sState = sStates.TRDSEEK
	_close_unit_options()

func _open_trade_menu(b):
	var char1 = activeBtn.get_meta("unit")
	var char2 = b.get_meta("unit")
	var lists = []
	var strip = true
	var setUp = $SetUpMain/SetUpGrid
	setUp.visible = false
	sState = sStates.TRADING
	tradeScn.open_trade_menu(char1, char2)
	lists.append(tradeScn.get_trade_list(2))
	lists.append(tradeScn.get_trade_list(1))
	for p in lists:
		_resignal_menuCursor(p, strip)
		strip = false
	
func _on_item_selected(b):
	var cursorDest = tradeScn.find_cursor_destionation(b)
	_font_color_change(b, "Selected")
	menuCursor.set_cursor(cursorDest)
	
func _on_item_deselected(b, snap = false):
	_font_color_change(b, "Default")
	if snap:
		menuCursor.set_cursor(b)
	

func _on_trade_closed():
	var setUp = $SetUpMain/SetUpGrid
	setUp.visible = true
	_open_unit_options(activeBtn)

func _on_supply_lb_pressed():
	var unit = activeBtn.get_meta("unit")
	var setUp = $SetUpMain/SetUpGrid
	sState = sStates.SUPPLY
	_close_unit_options()
	setUp.visible = false
	tradeScn.open_supply_menu(unit) 
	
	
func _on_trd_focus_changed(p, b = null):
	_resignal_menuCursor(p)
	
func _on_tab_selected(p):
	var kidCount1 = p[1].get_child_count()
	var focus = menuCursor.currentFocus
	_resignal_menuCursor(p[0], true)
	if kidCount1 > 0:
		_resignal_menuCursor(p[1], false)
	else:
		menuCursor.set_cursor(focus)
	


func _on_equip_lb_pressed():
	pass # Replace with function body.


func _on_use_lb_pressed():
	var unit = activeBtn.get_meta("unit")
	var setUp = $SetUpMain/SetUpGrid
	sState = sStates.USE
	_close_unit_options()
	setUp.visible = false
	tradeScn.open_use_menu(unit)

func _on_profile_request(newParent):
	_relocate_child(unitProf, newParent)
	_on_gameboard_toggle_prof()
	
func _on_item_used(unit, item):
	emit_signal("item_used", unit, item)


func _on_begin_btn_pressed():
	menuCursor.visible = false
	setUpMenu.visible = false
	sState = sStates.BEGIN
	turnTracker.visible = true
	emit_signal("map_started")
	
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
	foreCast.hide_fc()
	_strip_menuCursor()
	emit_signal("start_the_justice")

func _on_gameboard_skill_target_canceled():
	actMenu.open_skill_menu()

func _on_action_menu_menu_opened(container):
	#_resignal_menuCursor(container)
	call_deferred("_resignal_menuCursor",container)
	
func _on_weapon_selected(button):
	foreCast.hide_fc()
	_strip_menuCursor()
	emit_signal("start_the_justice", button)


#func _on_action_menu_weapon_changed(weapon):
	#pass # Replace with function body.

#Game State transitions

func _start_load_screen():
	pass

func _end_load_screen():
	pass

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

func _on_gameboard_map_loaded():
	_end_load_screen()
	



