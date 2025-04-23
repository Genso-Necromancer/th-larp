extends Control

class_name FocusViewer


##StatusTray is paired, but in it's current state it's too bulky and specific for the main profile screen
@export var terrainPanel : TerrainPanel
@export var unitPanel : UnitProfile
@export var dmkPanel : DanmakuProfile

var enableViewer : bool = false:
	set(value):
		visible = value
		enableViewer = value

#func _process(_delta):
	#_update_unit_panel()
	#_update_dmk_panel()

func _ready():
	visible = false
	terrainPanel.visible = false
	unitPanel.visible = false


func update_focus_viewer(cell:Vector2i) -> void:
	terrainPanel.visible = true
	terrainPanel.update_terrain_data(cell)
	_update_unit_panel()
	_update_dmk_panel()

func _update_unit_panel() -> void:
	var test = Global.focusUnit
	if Global.focusUnit: 
		unitPanel.visible = true
		unitPanel.update_prof()
	else: 
		unitPanel.visible = false


func _update_dmk_panel() -> void:
	if Global.focusDanmaku: 
		dmkPanel.visible = true
		dmkPanel.update_prof()
	else: 
		dmkPanel.visible = false
