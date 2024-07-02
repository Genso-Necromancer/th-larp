extends Control

signal jobs_done_act
signal action_selected(selection)

@onready var actFrame = $Count
@onready var subFrame = $m
@onready var frames = [actFrame, subFrame]


func _ready():
	var parent = get_parent()
	self.jobs_done_act.connect(parent._on_jobs_done)
	emit_signal("jobs_done_act", "Action", self)
	


#func get_options_menu():
	#var menu = $Count/ActionBox/CenterContainer/VBoxContainer
	#return menu

func _open_menu():
	self.visible = true
	
func close_menu():
	var generic = $Count/ActionBox/CenterContainer/GenericContainer
	var action = $Count/ActionBox/CenterContainer/ActionContainer
	self.visible = false
	generic.visible = false
	action.visible = false
	
func open_generic_menu():
	var container = $Count/ActionBox/CenterContainer/GenericContainer
	
	container.visible = true
	return container
	
func open_action_menu(unit):
	var action = $Count/ActionBox/CenterContainer/ActionContainer
	var aBtn = $Count/ActionBox/CenterContainer/ActionContainer/AtkBtn
	var sBtn = $Count/ActionBox/CenterContainer/ActionContainer/SklBtn
	var wBtn = $Count/ActionBox/CenterContainer/ActionContainer/WaitBtn
	
	_open_menu()
	action.visible = true
	if unit != null and unit.unitData.EQUIP != null:
		aBtn.disabled = false
	else:
		aBtn.disabled = true
		
	if unit != null and unit.unitData.Skills.size() != null and unit.unitData.Skills.size() > 0:
		sBtn.disabled = false
	else: 
		sBtn.disabled = true
			
	if unit != null and unit.check_status("Sleep"):
		aBtn.disabled = true
		sBtn.disabled = true
	#print("open_menu:")
	#print("Button: " + str(aBtn.get_global_position()))
	return action
	
	
func switch_frame(f):
	for frame in frames:
		frame.visible = false
	
	var frame
	match f:
		"Action": frame = actFrame
		"Sub": frame = subFrame
	frame.visible = true


func _on_end_btn_pressed():
	var selection = "End"
	accept_event()
	close_menu()
	emit_signal("action_selected", selection)
