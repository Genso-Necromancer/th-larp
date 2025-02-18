extends GridContainer

class_name StatusGrid

var icons := []

func check_status(unit:Unit):
	clear_status()
	var condition : Dictionary = unit.status
	for status in condition:
		if status == "Acted": continue
		elif condition[status]: _add_icon(status)
	
	
func clear_status():
	for icon in icons:
		icon.queue_free()
	icons.clear()

func _add_icon(status:String):
	var icon : StatusIcon = load("res://sprites/icons/status_icon.tscn").instantiate()
	icon.load_status_icon(status)
	icons.append(icon)
	add_child(icon)
