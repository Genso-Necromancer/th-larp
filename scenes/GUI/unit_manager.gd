extends Control
class_name UnitManager

@onready var buttonBox = $PanelContainer/MarginContainer/VBoxContainer
@onready var memorize_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Memorize


func connect_buttons(receiver):
	var t = $PanelContainer/MarginContainer/VBoxContainer/Trade
	var s = $PanelContainer/MarginContainer/VBoxContainer/Supply
	var m = $PanelContainer/MarginContainer/VBoxContainer/Manage
	
	t.pressed.connect(receiver._on_trade_pressed)
	s.pressed.connect(receiver._on_supply_pressed)
	m.pressed.connect(receiver._on_manage_pressed)
	memorize_button.pressed.connect(receiver._on_memorize_pressed)


func set_unit(unit: Unit) -> void:
	var can_memorize := unit != null and unit.has_spell_memorization()
	memorize_button.visible = can_memorize
	memorize_button.disabled = not can_memorize
