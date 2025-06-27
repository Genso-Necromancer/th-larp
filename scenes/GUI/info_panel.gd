extends PanelContainer

class_name InfoPanel

#@onready var effTitle := $ToolTipContainer/ItemDisplayMargin/VBoxContainer/EffectTitleBox
#@onready var effCon := $ToolTipContainer/ItemDisplayMargin/VBoxContainer/EffectContainer
@export var focusOffset : Vector2 = Vector2(-250,-50)
@export var isRoaming : bool = false
@onready var TTCon := $ToolTipContainer
@onready var animTree := $AnimationPlayer/AnimationTree
@onready var animPlayer := $AnimationPlayer
@onready var itemDisplay :ItemDisplay= $ToolTipContainer/VBoxContainer/ItemDisplayMargin


var hasEffects := false
var activeRefs := []
var currentFocus : Control

func _ready():
	visible = false
	animPlayer.animation_finished.connect(self._on_animation_finished)



func toggle_focus_signal() -> void:
	if !get_viewport().gui_focus_changed.is_connected(self._update_info):
		get_viewport().gui_focus_changed.connect(self._update_info)
		return
	if get_viewport().gui_focus_changed.is_connected(self._update_info):
		get_viewport().gui_focus_changed.disconnect(self._update_info)
		return

#func toggle_visible():
	#var animPlayer := $AnimationPlayer
	#if !visible: 
		#visible = true
		#animPlayer.play("Open")
	#else: 
		#animPlayer.play("Close")

func open_popup():
	visible = true
	#_match_internal_size()
	_open_refs()
	_reset_size()
	_tween_blend("Open")
	#animPlayer.play("Open")
	
	
func close_popup():
	_close_refs()
	#effTitle.visible = false
	#effCon.visible = false
	_tween_blend("Close")
	#animPlayer.play("Close")
	
	_reset_size()
	

func set_panel(button):
	currentFocus = button
	if button == null:
		return
	var cPosition = button.get_global_position()
	var cSize = button.size
	var newPos
	newPos = Vector2(cPosition.x + (cSize.x), cPosition.y) - Vector2(-25,20)
	set_global_position(newPos)


func _reset_panel():
	var newPos = Vector2(0,0)
	set_global_position(newPos)


func _match_internal_size():
	pass
	#var conSize = TTCon.get_size()
	#var x = clampi(conSize.x, defaultSize.x, 500)
	#var y = clampi(conSize.y, defaultSize.y, 500)
	#
	#storedSize = Vector2(x,y)

func _reset_size():
	size = custom_minimum_size


func _tween_min_size():
	pass
	#var tween = get_tree().create_tween()
	#tween.finished.connect(self._open_ttcon)
	#tween.tween_property(self, "size", storedSize,0.3)
	#_reset_internal_size()


func _tween_blend(Anim:StringName):
	var tween = get_tree().create_tween()
	var dest : float
	match Anim:
		"Open": dest = -1.0
		"Close": dest = 1.0
	
	tween.tween_property(animTree, "parameters/blend_position", dest,0.3)
	

func _open_ttcon():
	TTCon.visible = true

func _on_animation_finished(anim):
	match anim:
		"Close": 
			_reset_size()
		"Open": 
			pass
			

func _update_info(control:Control) -> void:
	var unit :Unit = Global.focusUnit
	var type : StringName
	var tt : ToolTipDisplay = $ToolTipContainer/VBoxContainer/ToolTipDisplay
	var statDisplay : ItemDisplay = $ToolTipContainer/VBoxContainer/ItemDisplayMargin
	var toolTip : String
	var parser := ToolTipParser.new()
	
	for group in control.get_groups():
		if group.ends_with("TT"):
			type = group
			break
	if !type: return
	elif type == "ItemTT" and control.get_meta("Item").id == "unarmed": return
	_close_refs()
	activeRefs.clear()
	if isRoaming: set_panel(control)
	
	itemDisplay.visible = false
	match type:
		"ItemTT": 
			var data = control.get_meta("Item")
			toolTip = parser.get_skill(data)
			statDisplay.update_stat_values(control)
			activeRefs.append(statDisplay)
			itemDisplay.visible = true
		"SkillsTT": 
			var data = control.get_meta("ID")
			toolTip = parser.get_skill(data)
			statDisplay.update_stat_values(control)
			activeRefs.append(statDisplay)
			itemDisplay.visible = true
		"ProfileTT":
			toolTip = parser.get_lore(unit, control.get_meta("ToolTip"))
			
		"CombatTT":
			toolTip = parser.get_combat(unit, control.get_meta("ToolTip"))
			
		"ActiveTT": 
			toolTip = parser.get_active(unit, control.get_meta("ToolTip"))
			
		"PassivesTT":
			
			var passive = control.get_meta("ID")
			toolTip = parser.get_passive(passive)
			
		"StatusTT":
			toolTip = parser.get_status(unit, control.get_meta("ID"))
			
	activeRefs.append(tt.display_tooltip(toolTip))
	_open_ttcon()
	#activeRefs.append(tt)
	
	open_popup()
	
	
func _open_refs():
	_open_ttcon()
	for ref in activeRefs:
		ref.visible = true
	
func _close_refs():
	for ref in activeRefs:
		ref.visible = false
