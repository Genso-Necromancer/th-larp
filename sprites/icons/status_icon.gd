extends TextureRect

class_name StatusIcon


func load_status_icon(status) -> StatusIcon:
	var icon : CompressedTexture2D
	var error : String = "res://sprites/ERROR.png"
	var icon_id := ""
	var tooltip_id = status
	if status is Dictionary:
		icon_id = String(status.get("icon", "status")).to_snake_case()
		tooltip_id = status.get("tooltip_id", status.get("id", icon_id))
	else:
		icon_id = String(status).to_snake_case()
	set_meta("ID", tooltip_id)
	var paths := [
		"res://sprites/icons/status/%s_icon.png" % [icon_id],
		"res://sprites/icons/status/%s.png" % [icon_id],
	]
	for path in paths:
		if ResourceLoader.exists(path):
			icon = load(path)
			break
	if icon == null:
		icon = load(error)
	set_texture(icon)
	return self
