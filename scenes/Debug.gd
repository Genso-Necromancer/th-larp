extends Control
class_name DebugScript

const DEBUG_STATUSES := ["Acted", "Sleep", "Dazed", "Silence"]

@onready var state_debug: Label = $PanelContainer/VBoxContainer/StateDebug
@onready var focus_debug: Label = $PanelContainer/VBoxContainer/focus
@onready var unit_focus_debug: Label = $PanelContainer/VBoxContainer/UnitFocus
@onready var danmaku_focus_debug: Label = $PanelContainer/VBoxContainer/DanmakuFocus

var root_vbox: VBoxContainer
var target_label: Label
var status_label: Label
var hp_spin: SpinBox
var comp_spin: SpinBox
var status_picker: OptionButton
var board: GameBoard
var _last_target_id := -1
var _pending_hp_value := 0
var _pending_comp_value := 0
var _last_target_unit: Unit


func _ready():
	get_viewport().gui_focus_changed.connect(self._on_gui_focused_changed)
	root_vbox = $PanelContainer/VBoxContainer
	$PanelContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_filter = Control.MOUSE_FILTER_PASS
	board = _get_board()
	_build_debug_controls()


func _process(_delta):
	visible = bool(Global.flags.get("DebugMode", false))

	var state = GameState.state
	var keys = GameState.gState.keys()
	var prevState = GameState.previousState
	var pString : StringName
	var cString : StringName
	var actSlave : StringName
	var prevSlave : StringName
	if state != null:
		cString = str(keys[state])
	else:
		cString = "--"
	if prevState:
		pString = str(keys[prevState[0]])
	else:
		pString = "--"

	if GameState.activeSlave:
		actSlave = GameState.activeSlave.name
	else:
		actSlave = "missing"
	if GameState.previousSlave.has(null):
		GameState.previousSlave.erase(null)
	elif GameState.previousSlave and GameState.previousSlave[-1] != null:
		prevSlave = GameState.previousSlave[-1].name
	else:
		prevSlave = "empty"

	state_debug.text = "Slave: %s | Prev.Slave:%s | State: %s | Previous State: %s" % [actSlave, prevSlave, cString, pString]

	if Global.focusUnit:
		unit_focus_debug.text = "focusUnit : [%s]" % [Global.focusUnit.unit_name]
	else:
		unit_focus_debug.text = "focusUnit : [none]"

	if Global.focusDanmaku:
		danmaku_focus_debug.text = "focusDanmaku : [%s]" % [Global.focusDanmaku]
	else:
		danmaku_focus_debug.text = "focusDanmaku : [none]"

	_refresh_target_debug()


func _build_debug_controls() -> void:
	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	target_label = Label.new()
	target_label.text = "Debug Target: [none]"
	root_vbox.add_child(target_label)

	status_label = Label.new()
	status_label.text = "Statuses: -"
	root_vbox.add_child(status_label)

	var soft_reset_label := Label.new()
	soft_reset_label.text = "Soft Reset: F9"
	root_vbox.add_child(soft_reset_label)

	var hp_row := HBoxContainer.new()
	var hp_lbl := Label.new()
	hp_lbl.text = "HP"
	hp_row.add_child(hp_lbl)
	hp_spin = SpinBox.new()
	hp_spin.min_value = 0
	hp_spin.max_value = 999
	hp_spin.step = 1
	hp_spin.rounded = true
	hp_spin.custom_minimum_size = Vector2(70, 0)
	hp_spin.value_changed.connect(_on_hp_spin_value_changed)
	hp_row.add_child(hp_spin)
	var hp_btn := Button.new()
	hp_btn.text = "Set"
	hp_btn.pressed.connect(_on_set_hp_pressed)
	hp_row.add_child(hp_btn)
	root_vbox.add_child(hp_row)

	var comp_row := HBoxContainer.new()
	var comp_lbl := Label.new()
	comp_lbl.text = "Comp"
	comp_row.add_child(comp_lbl)
	comp_spin = SpinBox.new()
	comp_spin.min_value = 0
	comp_spin.max_value = 999
	comp_spin.step = 1
	comp_spin.rounded = true
	comp_spin.custom_minimum_size = Vector2(70, 0)
	comp_spin.value_changed.connect(_on_comp_spin_value_changed)
	comp_row.add_child(comp_spin)
	var comp_btn := Button.new()
	comp_btn.text = "Set"
	comp_btn.pressed.connect(_on_set_comp_pressed)
	comp_row.add_child(comp_btn)
	var comp_zero_btn := Button.new()
	comp_zero_btn.text = "Zero"
	comp_zero_btn.pressed.connect(_on_zero_comp_pressed)
	comp_row.add_child(comp_zero_btn)
	root_vbox.add_child(comp_row)

	var status_row := HBoxContainer.new()
	status_picker = OptionButton.new()
	for status_name in DEBUG_STATUSES:
		status_picker.add_item(status_name)
	status_row.add_child(status_picker)
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_on_apply_status_pressed)
	status_row.add_child(apply_btn)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear_status_pressed)
	status_row.add_child(clear_btn)
	root_vbox.add_child(status_row)

	var turn_row := HBoxContainer.new()
	var end_turn_btn := Button.new()
	end_turn_btn.text = "End Turn"
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	turn_row.add_child(end_turn_btn)
	root_vbox.add_child(turn_row)


func _get_board() -> GameBoard:
	var node: Node = self
	while node != null:
		if node is MapManager:
			return node.gameBoard
		node = node.get_parent()
	return null


func _get_debug_target() -> Unit:
	if Global.activeUnit:
		_last_target_unit = Global.activeUnit
		return Global.activeUnit
	if Global.focusUnit:
		_last_target_unit = Global.focusUnit
		return Global.focusUnit
	if _last_target_unit and is_instance_valid(_last_target_unit):
		return _last_target_unit
	return null


func _refresh_target_debug() -> void:
	var unit := _get_debug_target()
	if unit == null:
		_last_target_id = -1
		target_label.text = "Debug Target: [none]"
		status_label.text = "Statuses: -"
		return
	_last_target_unit = unit

	var target_id := unit.get_instance_id()
	target_label.text = "Debug Target: [%s] HP %d/%d | Comp %d/%d" % [
		unit.unit_name,
		unit.current_life,
		int(unit.active_stats.get("Life", unit.current_life)),
		unit.current_comp,
		int(unit.active_stats.get("Comp", unit.current_comp))
	]

	var active_statuses: Array[String] = []
	for status_name in DEBUG_STATUSES:
		if unit.check_status(status_name):
			active_statuses.append(status_name)
	status_label.text = "Statuses: %s" % [", ".join(active_statuses) if not active_statuses.is_empty() else "-"]

	hp_spin.max_value = max(0, int(unit.active_stats.get("Life", unit.current_life)))
	comp_spin.max_value = max(0, int(unit.active_stats.get("Comp", unit.current_comp)))
	var target_changed := _last_target_id != target_id
	if target_changed:
		hp_spin.value = unit.current_life
		_pending_hp_value = unit.current_life
	if target_changed:
		comp_spin.value = unit.current_comp
		_pending_comp_value = unit.current_comp
	_last_target_id = target_id


func _set_unit_status(unit: Unit, status_name: String, active: bool) -> void:
	if status_name == "Acted":
		unit.set_acted(active)
	elif active:
		unit.status_controller.apply_debug_status(status_name)
	else:
		unit.status_controller.set_status_flag(status_name, active)


func _on_set_hp_pressed() -> void:
	var unit := _get_debug_target()
	if unit == null:
		return
	_sync_spin_pending_values()
	unit.current_life = clampi(int(_pending_hp_value), 0, int(unit.active_stats.get("Life", unit.current_life)))
	unit.update_stats()
	unit.update_life_bar()
	unit.check_death()
	_refresh_target_debug()


func _on_set_comp_pressed() -> void:
	var unit := _get_debug_target()
	if unit == null:
		return
	_sync_spin_pending_values()
	unit.set_composure(int(_pending_comp_value), "DebugSet")
	unit.update_composure_bar()
	_refresh_target_debug()


func _on_zero_comp_pressed() -> void:
	var unit := _get_debug_target()
	if unit == null:
		return
	_pending_comp_value = 0
	if comp_spin:
		comp_spin.value = 0
	unit.set_composure(0, "DebugZero")
	unit.update_composure_bar()
	_refresh_target_debug()


func _on_hp_spin_value_changed(value: float) -> void:
	_pending_hp_value = int(value)


func _on_comp_spin_value_changed(value: float) -> void:
	_pending_comp_value = int(value)


func _sync_spin_pending_values() -> void:
	if hp_spin:
		var hp_line_edit := hp_spin.get_line_edit()
		if hp_line_edit:
			_pending_hp_value = int(hp_line_edit.text)
		else:
			_pending_hp_value = int(hp_spin.value)
	if comp_spin:
		var comp_line_edit := comp_spin.get_line_edit()
		if comp_line_edit:
			_pending_comp_value = int(comp_line_edit.text)
		else:
			_pending_comp_value = int(comp_spin.value)


func _on_apply_status_pressed() -> void:
	var unit := _get_debug_target()
	if unit == null:
		return
	var status_name := status_picker.get_item_text(status_picker.selected)
	_set_unit_status(unit, status_name, true)
	_refresh_target_debug()


func _on_clear_status_pressed() -> void:
	var unit := _get_debug_target()
	if unit == null:
		return
	var status_name := status_picker.get_item_text(status_picker.selected)
	_set_unit_status(unit, status_name, false)
	_refresh_target_debug()


func _on_end_turn_pressed() -> void:
	if board == null:
		board = _get_board()
	if board == null:
		return
	board._advance_to_end_phase()


func _on_gui_focused_changed(f):
	if f == null:
		focus_debug.text = "GUI Focus: [none]"
		return
	focus_debug.text = "GUI Focus: [%s]" % [f.name]


func _on_gb_state_changed(stateKeys:Array, stateInd):
	var state :String = stateKeys[stateInd]
	$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer/GBState.set_text(state)


func _on_gb_step_changed(stepKeys:Array, stepInd):
	var step:String = stepKeys[stepInd]
	$PanelContainer/VBoxContainer/VBoxContainer/HBoxContainer2/GBStep.set_text(step)
