extends AspectRatioContainer

class_name UnitProfile

signal tooltips_on(buttons)
signal tooltips_off

@onready var inventory := $ProfileMargin/ProfileHBox/SideBarMargin/SideBarVBox/InventoryPanel
@onready var fBox := $ProfileMargin/ProfileHBox/ProfileContainer/DataMargin/DataVBox/CoreMargin/CoreVBox/FeaturesMargin/FeaturesVBox/fBoxPanel/fBoxMargin/FeatLbVBox
@onready var infoPanel := $infoNode/InfoPanel
@onready var statusTray := $ProfileMargin/ProfileHBox/ProfileContainer/PortraitMargin/StatusTrayMargin

var focusLabels : Array = []
var isMouseFocus : bool = false

var toolTipMode:=false:
	set(value):
		if value:
			infoPanel.open_popup()
			emit_signal("tooltips_on")
			#print("open")
		else: 
			infoPanel.close_popup()
			emit_signal("tooltips_off")
			#print("close")
			
		
		toolTipMode = value
		

var controllerMode := false

func _init():
	self.visible = false

func _ready():
	#toggle_blockers()
	_hide_info()
	_connect_labels()
	

func toggle_profile():
	visible = !visible
	
	infoPanel.toggle_focus_signal()
	
	


func update_prof():
	var focusUnit = Global.focusUnit
	var unitData : Dictionary
	
	if !focusUnit: return
	focusUnit.update_stats()
	unitData = focusUnit.unitData
	focusLabels.clear()
	_clear_skills()
	statusTray.update(focusUnit)
	statusTray.connect_icons(self)
	
	focusLabels = get_tree().get_nodes_in_group("ToolTipLabels")
	get_tree().call_group("ProfileLabels", "set_meta","Unit", focusUnit)
	#var unitStats = focusUnit.activeStats
	#var unitBuffs = focusUnit.activeBuffs
	focusLabels.append_array(statusTray.get_icons())
	focusLabels += _update_inventory(focusUnit)
	focusLabels += _update_features(focusUnit)
	_update_portrait(unitData["Profile"]["FullPrt"])
	get_tree().call_group("ProfileLabels", "you_need_to_update_yourself_NOW", focusUnit)
	

func _update_portrait(path : String):
	var texture = load(path)
	var portrait := $ProfileMargin/ProfileHBox/ProfileContainer/PortraitMargin/UnitPrt
	if !texture:
		texture = load("res://sprites/ERROR.png")
	portrait.set_texture(texture)

func _update_status(_unitStatus):
	var _grid := $ProfileMargin/ProfileHBox/ProfileContainer/PortraitMargin/StatusTrayMargin/StatusGridMargin/StatusGrid
	

func _update_inventory(unit) -> Array:
	inventory.set_meta("Unit", unit)
	inventory.clear_items()
	var itemButtons :Array = []
	for b in inventory.fill_items():
		var button = b.get_button()
		button.focus_entered.connect(self._on_focus_entered.bind(b))
		button.focus_exited.connect(self._on_focus_exited.bind(b))
		button.mouse_entered.connect(self._on_mouse_entered.bind(b))
		button.mouse_exited.connect(self._on_mouse_exited.bind(b))
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
	b.set_item_text(data.SkillName, str(data.Cost))
	b.set_item_icon(data.Icon)
	
	var button = b.get_button()
	
	button.focus_entered.connect(self._on_focus_entered.bind(b))
	button.focus_exited.connect(self._on_focus_exited.bind(b))
	button.mouse_entered.connect(self._on_mouse_entered.bind(b))
	button.mouse_exited.connect(self._on_mouse_exited.bind(b))
	return b


func generate_passivebutton(path, data) -> PassiveButton:
	var b : PassiveButton
	b = path.instantiate()
	b.set_passive_text(data)
	b.set_passive_icon(data)
	var button = b.get_button()
	
	button.focus_entered.connect(self._on_focus_entered.bind(b))
	button.focus_exited.connect(self._on_focus_exited.bind(b))
	button.mouse_entered.connect(self._on_mouse_entered.bind(b))
	button.mouse_exited.connect(self._on_mouse_exited.bind(b))
	return b


func _clear_skills():
	for kid in fBox.get_children():
		fBox.remove_child(kid)
		kid.queue_free()


#tool tip code
func toggle_tooltips(control = false):
	toolTipMode = !toolTipMode
	if !control and toolTipMode: focusLabels[0].call_deferred("grab_focus")
	#elif toolTipMode: control.call_deferred("grab_focus")
	
	
func toggle_controller_mode():
	if isMouseFocus: return
	controllerMode = !controllerMode
	toggle_tooltips()

func _update_tooltip(control:Control):
	pass
	#infoPanel.open_popup()
	#infoPanel.close_popup()

func _hide_info():
	pass
	#infoPanel.close_popup()
	

func _connect_labels() -> Array:
	var labels = get_tree().get_nodes_in_group("ToolTipLabels")
	for l in labels:
		l.focus_entered.connect(self._on_focus_entered.bind(l))
		l.focus_exited.connect(self._on_focus_exited.bind(l))
		l.mouse_entered.connect(self._on_mouse_entered.bind(l))
		l.mouse_exited.connect(self._on_mouse_exited.bind(l))
	return labels

func _on_focus_entered(control:Control):
	pass

	#_update_tooltip(control)
	#toggle_tooltips(control)
	

func _on_focus_exited(_node):
	pass
	#toggle_tooltips()
	#_hide_info()
	


func _on_mouse_entered(control:Control):
	var focus = control
	isMouseFocus = true
	if !controllerMode: 
		toggle_tooltips(control)
	if !focusLabels.has(control):
		focus = control.get_button()
	#focus.call_deferred("grab_focus")

func _on_mouse_exited(control:Control):
	var focus = control
	isMouseFocus = false
	if !controllerMode: 
		toggle_tooltips(control)
	if !controllerMode and !focusLabels.has(control):
		focus = control.get_button()
		focus.release_focus()
	


	
