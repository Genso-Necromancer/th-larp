extends Control
signal load_scene(scene)
signal map_picked
signal loadMapManager

const MAP_SCENE_DIR := "res://scenes/maps/scenes"

@onready var sceneMenu = $VBoxContainer/SceneMenu
@onready var loadBtn = $VBoxContainer/LoadButton
var selected_map_path := ""
var map_paths: Array[String] = []
#@onready var yaBoy = $"."

func _ready():
	var popUp = sceneMenu.get_popup()
	_populate_map_menu(popUp)
	popUp.index_pressed.connect(self.on_index_pressed)


func _populate_map_menu(popUp: PopupMenu) -> void:
	popUp.clear()
	map_paths.clear()
	selected_map_path = ""
	sceneMenu.set_text("Pick Scene")
	var dir := DirAccess.open(MAP_SCENE_DIR)
	if dir == null:
		push_warning("[StartMenu] Could not open map scene folder: %s" % MAP_SCENE_DIR)
		loadBtn.disabled = true
		return

	var files := dir.get_files()
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tscn"):
			continue
		var map_path := "%s/%s" % [MAP_SCENE_DIR, file_name]
		map_paths.append(map_path)
		popUp.add_item(file_name.get_basename(), map_paths.size() - 1)

	loadBtn.disabled = map_paths.is_empty()


func on_index_pressed(index):
	var popUp = sceneMenu.get_popup()
	var item_id = popUp.get_item_id(index)
	if item_id < 0 or item_id >= map_paths.size():
		selected_map_path = ""
		return
	selected_map_path = map_paths[item_id]
	sceneMenu.set_text(str(popUp.get_item_text(index)))

func _on_load_button_pressed():
	if selected_map_path == "":
		push_warning("[StartMenu] No map selected.")
		return
	emit_signal("loadMapManager", selected_map_path)
	emit_signal("map_picked")
