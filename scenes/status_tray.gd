extends MarginContainer

class_name StatusTray

@onready var statusGrid := $StatusGridMargin/StatusGrid

func _ready():
	visible = false
	
func update(unit:Unit):
	statusGrid.check_status(unit)
	if statusGrid.icons:
		visible = true
	else:
		visible = false
	

func connect_icons(node:Control):
	for icon in statusGrid.icons:
		icon.focus_entered.connect(node._on_focus_entered.bind(icon))
		icon.focus_exited.connect(node._on_focus_exited.bind(icon))
		icon.mouse_entered.connect(node._on_mouse_entered.bind(icon))
		icon.mouse_exited.connect(node._on_mouse_exited.bind(icon))

func get_icons() -> Array:
	return statusGrid.icons
