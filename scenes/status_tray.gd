extends MarginContainer

class_name StatusTray

@export var statusGrid : StatusGrid

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
		if node.has_method("_on_focus_entered"):
			var on_focus_entered := Callable(node, "_on_focus_entered").bind(icon)
			if not icon.focus_entered.is_connected(on_focus_entered):
				icon.focus_entered.connect(on_focus_entered)
		if node.has_method("_on_focus_exited"):
			var on_focus_exited := Callable(node, "_on_focus_exited").bind(icon)
			if not icon.focus_exited.is_connected(on_focus_exited):
				icon.focus_exited.connect(on_focus_exited)
		if node.has_method("_on_mouse_entered"):
			var on_mouse_entered := Callable(node, "_on_mouse_entered").bind(icon)
			if not icon.mouse_entered.is_connected(on_mouse_entered):
				icon.mouse_entered.connect(on_mouse_entered)
		if node.has_method("_on_mouse_exited"):
			var on_mouse_exited := Callable(node, "_on_mouse_exited").bind(icon)
			if not icon.mouse_exited.is_connected(on_mouse_exited):
				icon.mouse_exited.connect(on_mouse_exited)

func get_icons() -> Array:
	return statusGrid.icons
