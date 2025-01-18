extends Control
class_name MapGui

@onready var btnContainer := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox


func _init():
	toggle_visible()


func connect_buttons(parent):
	var d := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox/BTNDeploy
	var f := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox/FrmBtn
	var m := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox/MngBtn
	var b := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox/BeginBtn
	var s := $PanelContainer/MarginContainer/SetUpVbox/OptionsVBox/StatusBtn
	
	d.pressed.connect(parent._on_btn_deploy_pressed)
	f.pressed.connect(parent._on_frm_btn_pressed)
	m.pressed.connect(parent._on_mng_btn_pressed)
	b.pressed.connect(parent._on_begin_btn_pressed)
	s.pressed.connect(parent._on_status_btn_pressed)
	

func toggle_visible():
	var isVisible = visible
	visible = !isVisible


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


func set_mon(mon: int):
	var monLb := $PanelContainer/MarginContainer/SetUpVbox/MonVBox/MonCount
	monLb.set_text(str(mon))
