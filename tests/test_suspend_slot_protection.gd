extends SceneTree


func _initialize() -> void:
	for mode in [Enums.SAVE_TYPE.SET_UP, Enums.SAVE_TYPE.TRANSITION]:
		assert(not SaveHub.can_write_save(SaveHub.suspended_format, mode))
		assert(not SaveHub.can_write_save("user://saves/" + SaveHub.suspended_format, mode))
		assert(SaveHub.can_write_save(SaveHub.save_format % 0, mode))
	assert(SaveHub.can_write_save(SaveHub.suspended_format, Enums.SAVE_TYPE.SUSPENDED))
	var screen := SaveScreen.new()
	var files: Array = [SaveHub.suspended_format, SaveHub.save_format % 0]
	assert(screen._get_suspended_save(files) == SaveHub.suspended_format)
	assert(files == [SaveHub.save_format % 0])
	screen.free()
	print("Suspend slot protection checks passed")
	quit()
