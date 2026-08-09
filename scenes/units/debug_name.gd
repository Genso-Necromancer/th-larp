extends Label

@onready var unit: Unit = $"../../.."
var is_set:=false

func _process(_delta):
	if !is_set: _set_label()
	
func _ready():
	_set_label()

func _set_label():
	var unit_name := str(unit.unit_name)
	if unit_name == "": return
	var lv:= str(unit.unit_level)
	var label:String = "%s %s" % [lv, unit_name]
	set_text(label)
	is_set = true
