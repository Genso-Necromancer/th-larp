extends GridContainer

class_name StatusGrid

var icons := []

func check_status(unit:Unit):
	clear_status()
	if unit == null:
		return
	var entries: Array = []
	if unit.has_method("get_status_tray_entries"):
		entries = unit.get_status_tray_entries()
	else:
		var condition : Dictionary = unit.status
		for status in condition:
			if status == "Acted":
				continue
			if condition[status]:
				entries.append(status)
	for entry in entries:
		_add_icon(entry)
	
	
func clear_status():
	for icon in icons:
		icon.queue_free()
	icons.clear()

func _add_icon(status):
	var icon : StatusIcon = load("res://sprites/icons/status_icon.tscn").instantiate()
	icon.load_status_icon(status)
	icons.append(icon)
	add_child(icon)
