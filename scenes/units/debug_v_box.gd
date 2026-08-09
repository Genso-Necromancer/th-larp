extends VBoxContainer

func _process(_delta):
	visible = bool(Global.flags.get("DebugMode", false))
