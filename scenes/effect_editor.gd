extends HBoxContainer

signal changed(new_data: Dictionary)
signal remove_effect_pressed

@onready var name_btn	: OptionButton	= $EffectNameOptionButton
@onready var tgt_btn	: OptionButton	= $EffectTargetOptionButton
@onready var pos_sb		: SpinBox		= $SpinBox
@onready var remove_btn	: Button		= $RemoveEffectButton


func _ready():
	name_btn.connect("item_selected", Callable(self, "_on_fields_changed"))
	tgt_btn.connect("item_selected", Callable(self, "_on_fields_changed"))
	pos_sb.connect("value_changed", Callable(self, "_on_fields_changed"))
	remove_btn.connect("pressed", Callable(self, "_on_remove_pressed"))


# TODO inherit options from singleton or something
func setup(data:Dictionary, speaker_names:Array):
	name_btn.clear()
	var effect_list = ["portrait-sil","portrait-normal","dim","loud","quiet","zoom","teleport","sound"]
	for n in effect_list:
		name_btn.add_item(n)
	name_btn.selected = effect_list.find(data.get("name","portrait-sil"))

	tgt_btn.clear()
	for n in speaker_names:
		tgt_btn.add_item(n)
	tgt_btn.selected = speaker_names.find(data.get("target",speaker_names[0]))
	
	pos_sb.value = data.get("pos", 0.0)
	var show_spinbox = name_btn.get_item_text(name_btn.selected) in ["teleport"]
	#pos_sb.modulate.a = 1 if show_spinbox else 0
	pos_sb.visible = show_spinbox
	
	var show_target = name_btn.get_item_text(name_btn.selected) in ["portrait-sil","portrait-normal","dim","teleport","zoom"]
	#tgt_btn.modulate.a = 1 if show_target else 0
	tgt_btn.visible = show_target


func _on_fields_changed(args = null):
	var d = {
		"name": name_btn.get_item_text(name_btn.selected),
		"target": tgt_btn.get_item_text(tgt_btn.selected),
	}
	
	var show_spinbox = name_btn.get_item_text(name_btn.selected) in ["teleport"]
	#pos_sb.modulate.a = 1 if show_spinbox else 0
	pos_sb.visible = show_spinbox
	
	var show_target = name_btn.get_item_text(name_btn.selected) in ["portrait-sil","portrait-normal","dim","teleport","zoom"]
	#tgt_btn.modulate.a = 1 if show_target else 0
	tgt_btn.visible = show_target
	
	if d.name in ["teleport"]:
		d.pos = pos_sb.value
		
	changed.emit(d)


func _on_remove_pressed():
	remove_effect_pressed.emit()
