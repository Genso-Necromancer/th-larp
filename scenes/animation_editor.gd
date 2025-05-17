extends HBoxContainer

signal changed(new_data: Dictionary)
signal remove_anim_pressed()

@onready var name_btn	: OptionButton	= $AnimNameOptionButton
@onready var tgt_btn	: OptionButton	= $AnimTargetOptionButton
@onready var pos_sb		: SpinBox		= $SpinBox
@onready var remove_btn	: Button		= $RemoveAnimButton


func _ready():
	name_btn.connect("item_selected", Callable(self, "_on_fields_changed"))
	tgt_btn.connect("item_selected", Callable(self, "_on_fields_changed"))
	pos_sb.connect("value_changed", Callable(self, "_on_fields_changed"))
	remove_btn.connect("pressed", Callable(self, "_on_remove_pressed"))


# TODO inherit options from singleton or something
func setup(data:Dictionary, speaker_names:Array):
	name_btn.clear()
	var anim_list = ["slide","shake","hop","double_hop","interact","toggle_fade","teleport","question"]
	for n in anim_list:
		name_btn.add_item(n)
	name_btn.selected = anim_list.find(data.get("name","slide"))
	
	tgt_btn.clear()
	for n in speaker_names:
		tgt_btn.add_item(n)
	tgt_btn.selected = speaker_names.find(data.get("target",0))
	
	pos_sb.value = data.get("pos", 0.0)
	var show = name_btn.get_item_text(name_btn.selected) in ["slide","teleport"]
	pos_sb.modulate.a = 1 if show else 0


func _on_fields_changed(args = null):
	var d = {
		"name": name_btn.get_item_text(name_btn.selected),
		"target": tgt_btn.get_item_text(tgt_btn.selected),
	}
	
	var show = name_btn.get_item_text(name_btn.selected) in ["slide","teleport"]
	pos_sb.modulate.a = 1 if show else 0
	
	if d.name in ["slide","teleport"]:
		d.pos = pos_sb.value
		
	changed.emit(d)


func _on_remove_pressed():
	remove_anim_pressed.emit()
