extends Control
class_name SpellMemorizationPanel

signal closed
signal focus_buttons_changed(buttons: Array)

@onready var title_label: Label = %TitleLabel
@onready var slot_list: VBoxContainer = %SlotList
@onready var option_list: VBoxContainer = %OptionList
@onready var close_button: Button = %CloseButton

var unit: Unit
var selected_slot := -1
var slot_buttons: Array[Button] = []
var option_buttons: Array[Button] = []


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visible = false


func open_for_unit(new_unit: Unit) -> void:
	unit = new_unit
	selected_slot = 0
	visible = true
	_refresh()


func get_focus_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	buttons.append_array(slot_buttons)
	buttons.append_array(option_buttons)
	buttons.append(close_button)
	return buttons


func _refresh() -> void:
	_clear_container(slot_list)
	_clear_container(option_list)
	slot_buttons.clear()
	option_buttons.clear()
	if unit == null:
		title_label.text = "Memorize Spell"
		return
	title_label.text = "Memorize Spell - %s" % unit.unit_name
	_build_slot_buttons()
	_build_option_buttons()
	call_deferred("_emit_focus_buttons_changed")


func _build_slot_buttons() -> void:
	var slots := unit.get_memorized_skill_slots()
	if slots.is_empty():
		selected_slot = -1
		var empty_label := Label.new()
		empty_label.text = "No slots available"
		slot_list.add_child(empty_label)
		return
	selected_slot = clampi(selected_slot, 0, slots.size() - 1)
	for i in range(slots.size()):
		var skill = slots[i]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.text = _get_slot_text(i, skill)
		button.toggle_mode = true
		button.button_pressed = i == selected_slot
		button.pressed.connect(_on_slot_pressed.bind(i))
		slot_list.add_child(button)
		slot_buttons.append(button)


func _build_option_buttons() -> void:
	if selected_slot < 0:
		return
	var clear_button := Button.new()
	clear_button.focus_mode = Control.FOCUS_ALL
	clear_button.text = "Clear Slot"
	clear_button.pressed.connect(_on_clear_pressed)
	option_list.add_child(clear_button)
	option_buttons.append(clear_button)

	var options := unit.get_memorizable_spell_options()
	if options.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No spells available"
		option_list.add_child(empty_label)
		return
	for skill in options:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.text = StringGetter.get_skill_name(skill)
		button.pressed.connect(_on_spell_pressed.bind(skill))
		option_list.add_child(button)
		option_buttons.append(button)


func _get_slot_text(slot_index: int, skill) -> String:
	var slot_name := "Slot %d" % [slot_index + 1]
	if skill is Skill:
		return "%s: %s" % [slot_name, StringGetter.get_skill_name(skill)]
	return "%s: Empty" % slot_name


func _on_slot_pressed(slot_index: int) -> void:
	selected_slot = slot_index
	_refresh()


func _on_spell_pressed(skill: Skill) -> void:
	if unit == null or selected_slot < 0:
		return
	unit.set_memorized_skill(selected_slot, skill)
	_refresh()


func _on_clear_pressed() -> void:
	if unit == null or selected_slot < 0:
		return
	unit.clear_memorized_skill(selected_slot)
	_refresh()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _emit_focus_buttons_changed() -> void:
	if visible:
		focus_buttons_changed.emit(get_focus_buttons())


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
