extends TextureRect

class_name StatusIcon


func load_status_icon(status) -> StatusIcon:
	var icon : CompressedTexture2D
	var error : String = "res://sprites/ERROR.png"
	var path : String = "res://sprites/icons/status/%s.png" % [status.to_snake_case()]
	set_meta("Status", status)
	if ResourceLoader.exists(path): icon = load(path)
	else: icon = load(error)
	set_texture(icon)
	return self
