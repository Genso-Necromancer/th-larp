extends PanelContainer

class_name ActionMenu

signal action_menu_suspending_game

#new
signal move_selected
signal attack_selected
signal skill_selected(skill)
signal item_selected(unit)
signal trade_selected(unit)
signal wait_selected
signal ofuda_selected(unit, ofuda)
signal door_selected
signal seize_selected(cell)
signal suspend_requested
signal menu_canceled
signal weapon_confirmed(button)
signal skill_confirmed

enum MENU_STATES {NONE, OPTIONS, ACTION,ACTION2, WEAPONS_TARGETING, WEAPON_FORECAST, SKILLS_OPEN, SKILL_TARGETING, SKILL_CONFIRM, ITEM_MANAGE, ITEM_TRADE, OFUDA_OPEN, OFUDA_TARGETING, SUSPEND_PROMPT, SUSPENDING, DOOR}
@onready var aContainer : MarginContainer = $ScreenMargin/ActionBackgroundMargin
@onready var oContainer : MarginContainer = $ScreenMargin/OfudaBackgroundMargin
@onready var sContainer : MarginContainer = $ScreenMargin/SkillBackgroundMargin
@onready var cContainer : MarginContainer = $ScreenMargin/ConfirmBackgroundMargin
@onready var aBox : ActionBox = $ScreenMargin/ActionBackgroundMargin/ActionMargin/ActionBox
@onready var sBox : SkillBox = $ScreenMargin/SkillBackgroundMargin/SkillMargin/SkillBox
@onready var oBox : OfudaBox = $ScreenMargin/OfudaBackgroundMargin/OfudaMargin/OfudaBox
@export var skillConfirm : Button
@export var cursorOffset := Vector2(0,0)
@onready var blocker :Panel = $Blocker
@onready var inv : InventoryPanel =  $ScreenMargin/TradePnl

var cursorPath := preload("res://scenes/GUI/menu_cursor.tscn")
var cursor : MenuCursor
var currentUnit : Unit
var state := MENU_STATES.NONE:
	set(value):
			state = value
			match state:
				MENU_STATES.OPTIONS, MENU_STATES.ACTION, MENU_STATES.ACTION2, MENU_STATES.SKILLS_OPEN, MENU_STATES.OFUDA_OPEN, MENU_STATES.SUSPEND_PROMPT, MENU_STATES.SUSPENDING:
					mouse_filter = Control.MOUSE_FILTER_STOP
				_:
					mouse_filter = Control.MOUSE_FILTER_IGNORE
			match state:
				MENU_STATES.NONE: _close_self()
				MENU_STATES.OPTIONS:
					aBox.display_player_options()
					_unhide_action_container()
					_hide_tertiary()
					_assign_cursor(aBox.get_children())
					cursor.setCursor = true
				MENU_STATES.ACTION:
					_action_open()
				MENU_STATES.ACTION2:
					_action_open(true)
				MENU_STATES.WEAPONS_TARGETING:
					_hide_cursor()
					_hide_action_container()
					_close_inv()
				MENU_STATES.WEAPON_FORECAST:
					_give_items_focus()
				MENU_STATES.SKILLS_OPEN:
					_swap_to_skills()
					_assign_cursor(sBox.get_children())
					cursor.setCursor = true
				MENU_STATES.SKILL_TARGETING:
					_hide_cursor()
					_hide_action_container()
					_close_inv()
				MENU_STATES.SKILL_CONFIRM:
					_assign_cursor([skillConfirm])
					cursor.setCursor = true
				MENU_STATES.ITEM_MANAGE, MENU_STATES.ITEM_TRADE:
					#inv.visible = true
					_hide_cursor()
					_hide_action_container()
				MENU_STATES.OFUDA_OPEN:
					_swap_to_ofuda()
					_assign_cursor(oBox.get_children())
					cursor.setCursor = true
				MENU_STATES.OFUDA_TARGETING:
					_hide_cursor()
					_hide_action_container()
				MENU_STATES.SUSPEND_PROMPT:
					var choices:= %promptHBox
					var buttons:Array=[]
					for btn in choices.get_children():
						buttons.append(btn.button)
					_assign_cursor(buttons)
					cursor.setCursor = true
				MENU_STATES.SUSPENDING:
					_switch_to_save_warning()
				MENU_STATES.DOOR:
					_hide_cursor()
					_hide_action_container()


var prevState : Array[MENU_STATES] = []
var activeItem = null
var _suppress_cancel_emit := false

func _ready():
	self.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	aBox.connect_signals(self)
	inv.visible = false
	aContainer.visible = false
	oContainer.visible = false
	sContainer.visible = false
	cContainer.visible = false
	#var parent = get_parent()
	#self.weapon_selected.connect(parent._on_weapon_selected)
	#self.item_used.connect(parent._on_item_used)

#New Code
func end_self():
	_clear_states(true)


##opens self as current unit's actions.
func open_as_action(unit: Unit, moved:bool = false):
	_load_cursor()
	currentUnit = unit
	if moved: _change_state(MENU_STATES.ACTION2)
	else: _change_state(MENU_STATES.ACTION)
	self.visible = true
	cursor.setCursor = true


##opens self as player options.
func open_as_options():
	_load_cursor()
	_change_state(MENU_STATES.OPTIONS)
	self.visible = true
	cursor.setCursor = true


func open_weapon_select(reach):
	inv.set_meta("Unit", currentUnit)
	inv.fill_items(false, reach, true)
	_connect_forecast_signal(inv.get_item_buttons())
	inv.visible = true
	_change_state(MENU_STATES.WEAPON_FORECAST)


func open_skill_confirm():
	cContainer.visible = true
	_change_state(MENU_STATES.SKILL_CONFIRM)

func _close_inv():
	inv.clear_items()
	inv.visible = false


func _give_items_focus():
	var item_buttons := inv.get_item_buttons()
	_assign_cursor(item_buttons)
	if inv.items.is_empty():
		return
	inv.items[0].button.call_deferred("grab_focus")


func _on_weapon_focus_entered(weapon):
	SignalTower.emit_signal("inventory_weapon_changed", weapon)
	
	
func _on_weapon_pressed(weapon):
	_close_self()
	weapon_confirmed.emit(weapon)


func _swap_to_skills():
	var skills : Array
	aContainer.visible = false
	sContainer.visible = true
	skills = sBox.fill_skills(currentUnit)
	_connect_skill_signals(skills)


func _swap_to_ofuda():
	var ofuda : Array
	aContainer.visible = false
	oContainer.visible = true
	ofuda = oBox.fill_ofuda(currentUnit)
	_connect_ofuda_signals(ofuda)


func _close_self():
	self.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	currentUnit = null
	aContainer.visible = false
	_close_inv()
	_free_cursor()


func _hide_tertiary():
	sContainer.visible = false
	cContainer.visible = false
	oContainer.visible = false
	%SuspendPanel.visible = false
	_free_skills()
	_free_ofuda()


func _hide_action_container():
	_hide_tertiary()
	blocker.visible = false
	aContainer.visible = false


func _unhide_action_container():
	blocker.visible = true
	aContainer.visible = true


func _action_open(moved:bool = false):
	_close_inv()
	aBox.display_unit_actions(currentUnit,moved)
	_hide_tertiary()
	_unhide_action_container()
	_assign_cursor(aBox.get_children())
	cursor.setCursor = true


#Button functions
func _on_button_pressed(bName):
	match bName:
		"MoveBtn":
			_clear_states(true)
			state = MENU_STATES.NONE
			move_selected.emit()
		"TalkBtn": pass
		"SeizeBtn":
			seize_selected.emit(currentUnit.cell)
			_clear_states(true)
		"VisitBtn": pass
		"ShopBtn": pass
		"AtkBtn":
			attack_selected.emit()
			_change_state(MENU_STATES.WEAPONS_TARGETING)
		"SklBtn":
			# Do not emit skill_selected yet; actual skill choice happens in _on_skill_pressed
			_change_state(MENU_STATES.SKILLS_OPEN)
		"OpenDoorBtn":
			# New intent signal
			door_selected.emit()
			# Keep old flow for now
			_change_state(MENU_STATES.DOOR)
		"OpenChestBtn": pass
		"StealBtn": pass
		"OfudaBtn":
			_change_state(MENU_STATES.OFUDA_OPEN)
		"ItmBtn":
			_change_state(MENU_STATES.ITEM_MANAGE)
			item_selected.emit(currentUnit)
		"TrdBtn":
			_change_state(MENU_STATES.ITEM_TRADE)
			trade_selected.emit(currentUnit)
		"WaitBtn":
			_clear_states(true)
			wait_selected.emit()
		"EndBtn": pass
		"StatBtn": pass
		"OpBtn": pass
		"SusBtn":
			_prompt_suspension()


func _prompt_suspension():
	var sPan:= %SuspendPanel
	aContainer.visible = false
	sPan.visible = true
	_change_state(MENU_STATES.SUSPEND_PROMPT)


func _switch_to_save_warning():
	%SuspendPromptText.visible = false
	%promptHBox.visible = false
	%SaveWarningText.visible = true


func _on_skill_pressed(sButton : Control):
	var skill = sButton.get_meta("ID")
	skill_selected.emit(skill)
	_change_state(MENU_STATES.SKILL_TARGETING)


func _on_ofuda_pressed(oButton : Control):
	var unit: Unit = oButton.get_meta("Unit")
	var ofuda: Ofuda = oButton.get_meta("Item")
	# New intent signal
	ofuda_selected.emit(unit, ofuda)
	# Legacy compatibility:
	# For now we do NOT force use_item() here anymore.
	# Let higher-level code decide what happens next.
	_change_state(MENU_STATES.OFUDA_TARGETING)


func _free_skills():
	for s in sBox.get_children():
		s.queue_free()


func _free_ofuda():
	for o in oBox.get_children():
		o.queue_free()


#Signal Functions
func _connect_skill_signals(buttons : Array):
	for b in buttons:
		b.pressed.connect(self._on_skill_pressed.bind(b))


func _connect_ofuda_signals(buttons : Array):
	for b in buttons:
		b.pressed.connect(self._on_ofuda_pressed.bind(b))


func _connect_forecast_signal(weapons : Array):
	for w in weapons:
		w.focus_entered.connect(self._on_weapon_focus_entered.bind(w))
		w.pressed.connect(self._on_weapon_pressed.bind(w))


#Menu Cursor Functions
func _load_cursor():
	if is_instance_valid(cursor):
		return
	cursor = cursorPath.instantiate()
	cursor.cursor_offset = cursorOffset
	add_child(cursor)
	

func _assign_cursor(buttons : Array):
	#var bLayers:Array = []
	#for b:Button in buttons:
		#var bl :TextureButton= b.get_button()
		#bLayers.append(bl)
	#cursor.resignal_cursor(bLayers)
	cursor.resignal_cursor(buttons)
	#cursor.call_deferred("set_cursor")


func _free_cursor():
	if not is_instance_valid(cursor):
		return
	cursor.queue_free()
	cursor = null


func _hide_cursor():
	if is_instance_valid(cursor):
		cursor.visible = false


func suspend_menu():
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
	self.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocker.visible = false
	_free_cursor()


func resume_menu():
	mouse_filter = Control.MOUSE_FILTER_STOP
	self.visible = true
	_load_cursor()


#Menu State Management
func _change_state(newState):
	prevState.append(state)
	state = newState
	print(prevState)


func return_previous_state() -> void:
	var newState : MENU_STATES
	#var curState : MENU_STATES = state
	
	print(prevState)
	if state == MENU_STATES.ACTION and PlayerData.traded: return
	elif state == MENU_STATES.ACTION and PlayerData.item_used: return
	elif state == MENU_STATES.ACTION and PlayerData.move_committed: return
	
	if prevState.size() > 0:
		newState = prevState.pop_back()
		state = newState
		print(prevState)
	else: 
		print("action_menu, attempted invalid state return: No previous states.",)
		return
	
	#if curState == MENU_STATES.ITEM_MANAGE: emit_signal("action_menu_item_canceled")
	if newState == MENU_STATES.NONE and not _suppress_cancel_emit: 
		menu_canceled.emit()

func _clear_states(suppress_cancel := false):
	_suppress_cancel_emit = suppress_cancel
	_change_state(MENU_STATES.NONE)
	_suppress_cancel_emit = false
	prevState.clear()
	print(prevState)


func _on_skill_confirm_pressed():
	_clear_states(true)
	skill_confirmed.emit()


func _on_suspend_confirm_button_pressed(_button):
	_change_state(MENU_STATES.SUSPENDING)
	# New intent signal
	suspend_requested.emit()
	# Legacy compatibility
	action_menu_suspending_game.emit()


func _on_suspend_reject_button_pressed(_button):
	return_previous_state()
