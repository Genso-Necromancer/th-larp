extends Control
class_name UnitRoster

signal trade_requested

@onready var unitPreview := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/UnitPreviewPanel

var unitButton := preload("res://scenes/GUI/unit_button.tscn")
var unitMngrPL := preload("res://scenes/GUI/unit_manager.tscn")
var unitManager : Control
var unitBars : Array = []


func _init():
	toggle_visible()


func _ready():
	SignalTower.focus_unit_changed.connect(self._on_focus_changed)

func toggle_visible():
	var isVis = visible
	visible = !isVis
	

func init_roster(forcedDep, depLimit):
	var grid = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ScrollContainer/GridContainer
	var capLabel = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/CapLabel
	
	#var first: Button = null
	var units = UnitData.rosterData
	var filled = 0
	var unitObjs = Global.unitObjs
	if unitManager:
		var tempHold = unitManager
		tempHold.queue_free()
	unitManager = unitMngrPL.instantiate()
	call_deferred("_connect_manager_btns", unitManager)
	unitPreview.add_child(unitManager)
	close_unit_manager()
	capLabel.set_text(str(depLimit))
	capLabel.set_meta("Limit", depLimit)
	for unit in units:
		var b = unitButton.instantiate()
		
		b.set_unit(unitObjs[unit])
		if forcedDep.has(unit):
			b.set_state("Forced")
			filled += 1
			
		elif filled < depLimit:
			b.set_state("Deployed")
			filled += 1
		else:
			b.set_state("Undeployed")
		grid.add_child(b)
		unitBars.append(b)
		b.button.add_to_group("RosterUnitBars")
	update_deploy_count(filled)
	unitPreview.toggle_vis()

func update_deploy_count(count):
	var countLabel = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/CountLabel
	var capLabel = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/CapLabel
	var limit = capLabel.get_meta("Limit")
	countLabel.set_text(str(count))
	if count == limit:
		_font_state_change(countLabel, "DeployCap")
	else:
		_font_state_change(countLabel)

func open_menu(mode: int):
	var count = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer
	toggle_visible()
	match mode:
		0: count.visible = true
		1: count.visible = false
		
func close_menu():
	var count = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer
	toggle_visible()
	count.visible = false

func _font_state_change(node, state := ""):
	var fColor
	match state:
		"DeployCap": fColor = Color(0.212, 0.682, 0)
		_: 
			node.remove_theme_color_override("font_color")
			node.remove_theme_color_override("font_pressed_color")
			node.remove_theme_color_override("font_hover_color")
			node.remove_theme_color_override("font_focus_color")
			node.remove_theme_color_override("font_hover_pressed_color")
			return
	node.add_theme_color_override("font_color", fColor)
	node.add_theme_color_override("font_pressed_color", fColor)
	node.add_theme_color_override("font_hover_color", fColor)
	node.add_theme_color_override("font_focus_color", fColor)
	node.add_theme_color_override("font_hover_pressed_color", fColor)


func open_unit_manager() -> Control: #need catch for which items to show
	Global.focusUnit
	unitManager.visible = true
	return unitManager.buttonBox


func close_unit_manager():
	unitManager.visible = false


func _switch_trade_mode():
	close_unit_manager()


func set_bar_focus(canFocus:bool) ->void:
	if !visible: return
	if canFocus:
		get_tree().call_group("RosterUnitBars","set_focus_mode", Control.FOCUS_ALL)
	else:
		get_tree().call_group("RosterUnitBars","set_focus_mode", Control.FOCUS_NONE)


func _connect_manager_btns(manager):
	var p = get_parent()
	manager.connect_buttons(p)


func _on_focus_changed(_unit:Unit):
	if visible: 
		unitPreview.update_prof()
