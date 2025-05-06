extends PanelContainer

class_name ActionMenu

signal action_menu_canceled
signal action_menu_selected(bName)
signal action_menu_item_pressed(unit)
#signal action_menu_item_canceled
signal action_menu_trade_pressed(unit)


enum MENU_STATES {NONE, OPTIONS, ACTION, WEAPONS_TARGETING, WEAPON_FORECAST, SKILLS_OPEN, SKILL_TARGETING, SKILL_CONFIRM, ITEM_MANAGE, ITEM_TRADE, OFUDA_OPEN, OFUDA_TARGETING}
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
				MENU_STATES.NONE: _close_self()
				MENU_STATES.OPTIONS:
					aBox.display_player_options()
					_unhide_action_container()
					_hide_tertiary()
					_assign_cursor(aBox.get_children())
					cursor.setCursor = true
				MENU_STATES.ACTION:
					_close_inv()
					aBox.display_unit_actions(currentUnit)
					_hide_tertiary()
					_unhide_action_container()
					_assign_cursor(aBox.get_children())
					cursor.setCursor = true
				MENU_STATES.WEAPONS_TARGETING:
					_hide_cursor()
					_hide_action_container()
					_close_inv()
					emit_signal("action_menu_selected", "AtkBtn")
				MENU_STATES.WEAPON_FORECAST:
					_give_items_focus()
				MENU_STATES.SKILLS_OPEN:
					_swap_to_skills()
					_assign_cursor(sBox.get_children())
					cursor.setCursor = true
				MENU_STATES.SKILL_TARGETING:
					_hide_cursor()
					_hide_action_container()
					emit_signal("action_menu_selected", "SklBtn")
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

var prevState : Array[MENU_STATES] = []
var activeItem = null


func _ready():
	self.visible = false
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
##opens self as current unit's actions.
func open_as_action(unit: Unit):
	_load_cursor()
	currentUnit = unit
	_change_state(MENU_STATES.ACTION)
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
	_assign_cursor(inv.get_item_buttons())
	inv.items[0].button.call_deferred("grab_focus")


func _on_weapon_focus_entered(weapon):
	SignalTower.emit_signal("inventory_weapon_changed", weapon)
	
	
func _on_weapon_pressed(weapon):
	_close_self()
	SignalTower.emit_signal("action_weapon_selected", weapon)


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
	currentUnit = null
	aContainer.visible = false
	_close_inv()
	_free_cursor()


func _hide_tertiary():
	sContainer.visible = false
	cContainer.visible = false
	oContainer.visible = false
	_free_skills()
	_free_ofuda()


func _hide_action_container():
	_hide_tertiary()
	blocker.visible = false
	aContainer.visible = false


func _unhide_action_container():
	blocker.visible = true
	aContainer.visible = true

#Button functions
func _on_button_pressed(bName):
	match bName:
		"TalkBtn": pass
		"SeizeBtn": 
			SignalTower.action_seize.emit(currentUnit.cell)
			_clear_states()
			emit_signal("action_menu_selected", bName)
		"VisitBtn": pass
		"ShopBtn": pass
		"AtkBtn": _change_state(MENU_STATES.WEAPONS_TARGETING)
		"SklBtn": _change_state(MENU_STATES.SKILLS_OPEN)
		"OpenBtn": pass
		"StealBtn": pass
		"OfudaBtn": 
			_change_state(MENU_STATES.OFUDA_OPEN)
			
		"ItmBtn": 
			_change_state(MENU_STATES.ITEM_MANAGE)
			emit_signal("action_menu_item_pressed", currentUnit)
		"TrdBtn": 
			_change_state(MENU_STATES.ITEM_TRADE)
			emit_signal("action_menu_trade_pressed", currentUnit)
		"WaitBtn": 
			_clear_states()
			emit_signal("action_menu_selected", bName)
		"EndBtn": pass
		"StatBtn": pass
		"OpBtn": pass
		"SusBtn": pass


func _on_skill_pressed(sButton : Control):
	Global.activeSkill = sButton.get_meta("ID")
	_change_state(MENU_STATES.SKILL_TARGETING)


func _on_ofuda_pressed(oButton : Control):
	var unit: Unit = oButton.get_meta("Unit")
	var ofuda : Ofuda = oButton.get_meta("Item")
	unit.use_item(ofuda)
	#Global.activeSkill = oButton.get_meta("ID")
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
	cursor = cursorPath.instantiate()
	cursor.cursor_offset = cursorOffset
	add_child(cursor)
	

func _assign_cursor(buttons : Array):
	cursor.resignal_cursor(buttons)
	#cursor.call_deferred("set_cursor")


func _free_cursor():
	cursor.queue_free()


func _hide_cursor():
	cursor.visible = false


#Menu State Management
func _change_state(newState):
	prevState.append(state)
	state = newState


func return_previous_state() -> void:
	var newState : MENU_STATES
	#var curState : MENU_STATES = state
	
	
	if state == MENU_STATES.ACTION and Global.flags.traded: return
	elif state == MENU_STATES.ACTION and Global.flags.itemUsed: return
	
	if prevState.size() > 0:
		newState = prevState.pop_back()
		state = newState
	else: 
		print("action_menu, attempted invalid state return: No previous states.",)
		return
	
	#if curState == MENU_STATES.ITEM_MANAGE: emit_signal("action_menu_item_canceled")
	if newState == MENU_STATES.NONE: emit_signal("action_menu_canceled")

func _clear_states():
	_change_state(MENU_STATES.NONE)
	prevState.clear()


func _on_skill_confirm_pressed():
	_clear_states()
	SignalTower.emit_signal("action_skill_confirmed")
