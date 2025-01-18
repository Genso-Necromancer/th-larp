extends Control
class_name UnitManager

@onready var buttonBox = $PanelContainer/MarginContainer/VBoxContainer


func connect_buttons(receiver):
	var t = $PanelContainer/MarginContainer/VBoxContainer/Trade
	var s = $PanelContainer/MarginContainer/VBoxContainer/Supply
	var m = $PanelContainer/MarginContainer/VBoxContainer/Manage
	
	t.pressed.connect(receiver._on_trade_pressed)
	s.pressed.connect(receiver._on_supply_pressed)
	m.pressed.connect(receiver._on_manage_pressed)
