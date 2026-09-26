@tool
extends EditorPlugin

const CUTSCENE_EXTENSION := "cutscene"
const TEXT_EXTENSIONS_SETTING := "docks/filesystem/textfile_extensions"


func _enter_tree() -> void:
	_register_cutscene_text_extension()


func _register_cutscene_text_extension() -> void:
	var settings := get_editor_interface().get_editor_settings()
	var raw_extensions := String(settings.get_setting(TEXT_EXTENSIONS_SETTING))
	var extensions := raw_extensions.split(",", false)
	for index in range(extensions.size()):
		extensions[index] = String(extensions[index]).strip_edges()
	if extensions.has(CUTSCENE_EXTENSION):
		return
	extensions.append(CUTSCENE_EXTENSION)
	settings.set_setting(TEXT_EXTENSIONS_SETTING, ",".join(extensions))
	settings.save()
	print("[CutsceneAuthoring] Registered .cutscene as an editable text file extension.")
