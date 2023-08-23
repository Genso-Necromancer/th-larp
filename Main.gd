extends Node




func _unhandled_input(event):
	if event.is_action_pressed("ui_snap"):
		take_screenshot()
func take_screenshot():
	var viewport = get_viewport()
	if viewport:
		await RenderingServer.frame_post_draw
		var screenshot = viewport.get_texture().get_image()
#		var image = ImageTexture.new()
		var tag = 0
		var fileName
		

#		image.create_from_image(screenshot)
		fileName= ("screenshot%s.png" % [tag])
		while is_screenshot_duplicate(fileName):
			tag += 1
			fileName= ("screenshot%s.png" % [tag])
		screenshot.save_png("res://screenshots/screenshot%s.png" % [tag])

func is_screenshot_duplicate(fileName: String) -> bool:
	var dir := DirAccess.open("res://screenshots/")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file == fileName:
				return true
			else:
				file = dir.get_next()
	return false
