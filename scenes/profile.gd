extends AspectRatioContainer

class_name UnitProfile

signal tooltips_on(buttons)
signal tooltips_off

@export var inventory : InventoryPanel
@export var fBox : Control
@export var infoPanel : InfoPanel
@export var statusTray : StatusTray
@export var isPreview : bool = false
@export var initialFocus : Label
@export var portrait : TextureRect
var focusLabels : Array = []
var isMouseFocus : bool = false
var toolTipMode:=false:
	set(value):
		if isPreview: return
		elif value:
			infoPanel.open_popup()
			emit_signal("tooltips_on")
			
		else: 
			infoPanel.close_popup()
			emit_signal("tooltips_off")
			
		toolTipMode = value
var controllerMode := false


func _init():
	self.visible = false


func _ready():
	#toggle_blockers()
	#_hide_info()
	if !isPreview: _connect_labels()


func toggle_profile():
	toggle_vis()
	if !isPreview: infoPanel.toggle_focus_signal()


func toggle_vis():
	visible = !visible


func update_prof():
	var focusUnit = Global.focusUnit
	var unitData : Dictionary
	
	if !focusUnit: return
	focusUnit.update_stats()
	unitData = focusUnit.unitData
	focusLabels.clear()
	_clear_skills()
	
	focusLabels = get_tree().get_nodes_in_group("ToolTipLabels")
	get_tree().call_group("ProfileLabels", "set_meta", "Unit", focusUnit)
	if statusTray:
		statusTray.update(focusUnit)
		statusTray.connect_icons(self)
		focusLabels.append_array(statusTray.get_icons())
	
	
	#var unitStats = focusUnit.activeStats
	#var unitBuffs = focusUnit.activeBuffs
	
	if inventory: focusLabels += _update_inventory(focusUnit)
	if fBox: focusLabels += _update_features(focusUnit)
	if !isPreview: _update_portrait(unitData["Profile"]["FullPrt"])
	elif isPreview and portrait: _update_portrait(unitData["Profile"]["Prt"])
	get_tree().call_group("ProfileLabels", "you_need_to_update_yourself_NOW", focusUnit)


func _update_portrait(path : String) -> void:
	var texture : CompressedTexture2D
	if !ResourceLoader.exists(path): texture = load("res://sprites/ERROR.png")
	else: texture = load(path)
	portrait.set_texture(texture)


func _update_inventory(unit) -> Array:
	inventory.set_meta("Unit", unit)
	inventory.clear_items()
	var itemButtons :Array = []
	for b in inventory.fill_items():
		var button = b.get_button()
		_connect_focus_signals(b)
		button.add_to_group("ItemTT")
		itemButtons.append(button)
	return itemButtons


func _update_features(unit) -> Array:
	var skills = unit.unitData.Skills
	var sData = UnitData.skillData
	var passives = unit.unitData.Passives
	var pData = UnitData.passiveData
	var sPath = load("res://scenes/GUI/skill_button.tscn")
	var pPath = load("res://scenes/GUI/passive_button.tscn")
	var s : SkillButton
	var p : PassiveButton
	var buttons : Array = []
	
	for passive in passives:
		p = generate_passivebutton(pPath, pData[passive])
		buttons.append(p.get_button())
		p.get_button().add_to_group("PassivesTT")
		p.set_meta_data(passive, unit, false)
		fBox.add_child(p)
	
	for skill in skills:
		s = generate_skillbutton(sPath, sData[skill])
		buttons.append(s.get_button())
		s.get_button().add_to_group("SkillsTT")
		s.set_meta_data(skill, unit, false)
		fBox.add_child(s)
		
	return buttons


func generate_skillbutton(path, data) -> SkillButton:
	var b : SkillButton
	b = path.instantiate()
	b.isIconMode = isPreview
	b.set_item_text(data.SkillName, str(data.Cost))
	b.set_item_icon(data.Icon)
	_connect_focus_signals(b)
	return b


func generate_passivebutton(path, data) -> PassiveButton:
	var b : PassiveButton
	b = path.instantiate()
	b.isIconMode = isPreview
	b.set_passive_text(data)
	b.set_passive_icon(data)
	_connect_focus_signals(b)
	return b


func _connect_focus_signals(b:Control):
	var button = b.get_button()
	if !isPreview: 
		#button.focus_entered.connect(self._on_focus_entered.bind(b))
		#button.focus_exited.connect(self._on_focus_exited.bind(b))
		button.mouse_entered.connect(self._on_mouse_entered.bind(b))
		button.mouse_exited.connect(self._on_mouse_exited.bind(b))


func _clear_skills() -> void:
	if !fBox: return
	for kid in fBox.get_children():
		fBox.remove_child(kid)
		kid.queue_free()


#tool tip code
func toggle_tooltips(control = false):
	toolTipMode = !toolTipMode
	if !control and toolTipMode: 
		initialFocus.call_deferred("grab_focus")


func toggle_controller_mode():
	if isMouseFocus: return
	controllerMode = !controllerMode
	toggle_tooltips()


func _connect_labels() -> Array:
	var labels = get_tree().get_nodes_in_group("ToolTipLabels")
	for l in labels:
		l.mouse_entered.connect(self._on_mouse_entered.bind(l))
		l.mouse_exited.connect(self._on_mouse_exited.bind(l))
	return labels


func _on_mouse_entered(control:Control) -> void:

	if !visible: return 
	isMouseFocus = true
	if !controllerMode: 
		toggle_tooltips(control)



func _on_mouse_exited(control:Control) -> void:
	if !visible: return 
	var focus = control
	isMouseFocus = false
	if !controllerMode: 
		toggle_tooltips(control)
	if !controllerMode and !focusLabels.has(control) and control is ItemButton:
		focus = control.get_button()
		focus.release_focus()
	
	
