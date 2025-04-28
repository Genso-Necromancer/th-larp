@tool
extends TextureLabelButton
class_name SaveFileButton

enum SCENE_STATE{
	EMPTY, ##No Save File associated with button
	FILE ##Has a valid save file
}
var state : SCENE_STATE = SCENE_STATE.EMPTY
var save_file


func _ready():
	pass
	


##Assigns an existing save file.[br]
func set_file(file) -> void:
	save_file = file
	state = SCENE_STATE.FILE
	#Once save files are implemented, include setting the icon
