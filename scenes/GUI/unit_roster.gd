extends Control
class_name UnitRoster

#signal trade_requested

@onready var unitPreview := $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/UnitPreviewPanel

var unitButton := preload("res://scenes/GUI/unit_button.tscn")
var unitMngrPL := preload("res://scenes/GUI/unit_manager.tscn")
var unitManager : Control
var unit_bars : Array = []


func _init():
	toggle_visible()


func _ready():
	SignalTower.focus_unit_changed.connect(self._on_focus_changed)

func toggle_visible():
	var isVis = visible
	visible = !isVis
	

func init_roster(forcedDep:Array, depLimit:int, unit_refs:Dictionary):
	var capLabel := %CapLabel
	var order:= PlayerData.roster_order
	var filled := 0
	if unitManager:
		var tempHold = unitManager
		tempHold.queue_free()
	unitManager = unitMngrPL.instantiate()
	call_deferred("_connect_manager_btns", unitManager)
	unitPreview.add_child(unitManager)
	close_unit_manager()
	capLabel.set_text(str(depLimit))
	capLabel.set_meta("Limit", depLimit)
	for group in order:
		filled += _instantiate_unit_buttons(order[group],unit_refs,group)
	update_deploy_count(filled)
	unitPreview.toggle_vis()
	#for id in units:
		#var unit :String = id
		#var b :UnitButton= unitButton.instantiate()
		#
		#b.set_unit(unit_refs[unit])
		#if forcedDep.has(unit):
			#b.set_state("Forced")
			#filled += 1
			#
		#elif filled < depLimit:
			#b.set_state("Deployed")
			#filled += 1
		#else:
			#b.set_state("Undeployed")
		#grid.add_child(b)
		#unit_bars.append(b)
		#b.button.add_to_group("Rosterunit_bars")


func _instantiate_unit_buttons(order:Array, unit_refs:Dictionary, group:Enums.DEPLOYMENT)->int:
	var filled:= 0
	var state:String
	var grid := %GridContainer
	match group:
		Enums.DEPLOYMENT.FORCED: 
			state = "Forced"
			filled += 1
		Enums.DEPLOYMENT.DEPLOYED: 
			state = "Deployed"
			filled += 1
		Enums.DEPLOYMENT.UNDEPLOYED: 
			state = "Undeployed"
	for id in order:
		var b :UnitButton= unitButton.instantiate()
		b.set_unit(unit_refs[id])
		b.set_state(state)
		grid.add_child(b)
		unit_bars.append(b)
		b.button.add_to_group("Rosterunit_bars")
	return filled


func _refresh_roster_grid():
	var grid := %GridContainer
	var order:=PlayerData.roster_order
	var unitRefs:={}
	var barRefs:={}
	_orphan_bars(unitRefs,barRefs)
	for group in order:
		_readd_unit_bars(order[group],barRefs)


func _orphan_bars(unit_refs:Dictionary,bar_refs:Dictionary):
	var grid := %GridContainer
	for bar in unit_bars:
		var unit:Unit=bar.get_unit()
		bar_refs[unit.unit_id]=bar
		unit_refs[unit.unit_id]=unit
		grid.remove_child(bar)


func _readd_unit_bars(group:Array,bars:Dictionary):
	var grid := %GridContainer
	for id in group:
		grid.add_child(bars[id])


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
	await _refresh_roster_grid()
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
	#Global.focusUnit
	unitManager.visible = true
	return unitManager.buttonBox


func close_unit_manager():
	unitManager.visible = false


func _switch_trade_mode():
	close_unit_manager()


func set_bar_focus(canFocus:bool) ->void:
	if !visible: return
	if canFocus:
		get_tree().call_group("Rosterunit_bars","set_focus_mode", Control.FOCUS_ALL)
	else:
		get_tree().call_group("Rosterunit_bars","set_focus_mode", Control.FOCUS_NONE)


func _connect_manager_btns(manager):
	var p = get_parent()
	manager.connect_buttons(p)


func _on_focus_changed(_unit:Unit):
	if visible: 
		unitPreview.update_prof()
