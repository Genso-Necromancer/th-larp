extends Label

@onready var unit: Unit = $"../.."

func _process(_delta):
	if get_text() != str(unit.cell): update_cell()
	
func update_cell():
	set_text(str(unit.cell))
