extends Control
class_name MapGui

@onready var btnContainer := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox
var enableSFX := false

func _init():
	toggle_visible()


func connect_buttons(parent):
	var d := %BTNDeploy
	var f := %FrmBtn
	var m := %MngBtn
	var b := %BeginBtn
	var s := %StatusBtn
	var sv := %SaveBtn
	
	d.pressed.connect(parent._on_btn_deploy_pressed)
	f.pressed.connect(parent._on_frm_btn_pressed)
	m.pressed.connect(parent._on_mng_btn_pressed)
	b.pressed.connect(parent._on_begin_btn_pressed)
	s.pressed.connect(parent._on_status_btn_pressed)
	sv.pressed.connect(parent._on_save_btn_pressed)
	
	

func toggle_visible():
	var isVisible = visible
	visible = !isVisible
	enableSFX = !isVisible


func set_chapter(number : int, title: String, objectives : Array, loss : Array):
	var chNum := $PanelContainer/MarginContainer/SetUpVbox/ChapterVbox/ChapterHBox/ChapterNumber
	var titleLb := $"PanelContainer/MarginContainer/SetUpVbox/ChapterVbox/Chapter Title"
	var objPath = load("res://scenes/GUI/objective_label.tscn")
	var objBox := $PanelContainer/MarginContainer/SetUpVbox/ConditionsBox/ObjectiveVBox
	var lossBox := $PanelContainer/MarginContainer/SetUpVbox/ConditionsBox/LossBox
	chNum.set_text(str(number))
	titleLb.set_text(title)
	for obj in objectives:
		var lb = objPath.instantiate()
		lb.set_text(obj)
		objBox.add_child(lb)
		
	for l in loss:
		var lb = objPath.instantiate()
		lb.set_text(l)
		lossBox.add_child(lb)


func free_previous_obj():
	var objs = $PanelContainer/MarginContainer/SetUpVbox/ConditionsBox/ObjectiveVBox.get_children()
	var losses := $PanelContainer/MarginContainer/SetUpVbox/ConditionsBox/LossBox.get_children()
	var first := true
	for obj in objs:
		if first:
			first = false
			continue
		obj.queue_free()
	first = true
	for loss in losses:
		if first:
			first = false
			continue
		loss.queue_free()


func set_mon(mon: int):
	var monLb := $PanelContainer/MarginContainer/SetUpVbox/MonVBox/MonCount
	monLb.set_text(str(mon))

#region btn sfx triggers
func _on_btn_deploy_focus_exited():
	_focus_switched_sfx()


func _on_frm_btn_focus_exited():
	_focus_switched_sfx()


func _on_mng_btn_focus_exited():
	_focus_switched_sfx()


func _on_begin_btn_focus_exited():
	_focus_switched_sfx()


func _on_btn_deploy_pressed():
	_button_confirm_sfx()


func _on_frm_btn_pressed():
	_button_confirm_sfx()


func _on_mng_btn_pressed():
	_button_confirm_sfx()


func _on_begin_btn_pressed():
	_button_confirm_sfx()


func _on_save_btn_pressed():
	_button_confirm_sfx()
#endregion

#region SFX
func _focus_switched_sfx():
	if visible:
		SignalTower.audio_called.emit("FocusChange")
		
func _button_confirm_sfx():
	if visible:
		SignalTower.audio_called.emit("Confirm")
#endregion
