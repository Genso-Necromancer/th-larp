@tool
extends TextureLabelButton
class_name SaveFileButton

enum SCENE_STATE{
	EMPTY, ##No Save File associated with button
	FILE ##Has a valid save file
}
var state : SCENE_STATE = SCENE_STATE.EMPTY
var save_file : String = ""


func _ready():
	pass
	


##Assigns an existing save file.[br]
func set_file(file) -> void:
	save_file = file
	if SaveHub.is_valid_file(file): state = SCENE_STATE.FILE
	else: state = SCENE_STATE.EMPTY
	_format()

func get_save_file() -> String:
	return save_file

func _format() -> void:
	var header = SaveHub.get_header(save_file)
	if !header: state = SCENE_STATE.EMPTY
	match state:
		SCENE_STATE.EMPTY: return
		SCENE_STATE.FILE: _load_save_header(header)


func _load_save_header(header: Dictionary):
	var date:= "%d/%d/%d - %d:%d:%d" % [header.Date.month,header.Date.day,header.Date.year,header.Date.hour,header.Date.minute,header.Date.second]
	var saveSlot:String= header.FileName.get_basename().slice("_",1)
	var denote:String
	var timeUnits : Dictionary = Global.float_to_time(header.GameTime)
	var timeString : String = Global.time_to_string(timeUnits.Hours, timeUnits.Minutes)
	var vLb:= $ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/IsComplete
	var chTimeLb:= $ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/ChapterTime
	match header.TimeOfDay:
		Enums.DAY: denote = "AM"
		Enums.NIGHT: denote = "PM"
	
	match header.TimeOfDay:
		Enums.TIME.NIGHT: denote = "PM"
		Enums.TIME.DAY: denote = "AM"
	$ContentsHBox/SaveMargin.visible = true
	$ContentsHBox/LabelMargin.visible = false
	$ContentsHBox/SaveMargin/SaveVBox/HeaderVBox/FileSlot.set_text(saveSlot)
	$ContentsHBox/SaveMargin/SaveVBox/HeaderVBox/Date.set_text(date)
	#$ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/ChapterNumber.set_text(str(header.ChapterNumber))
	$ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/ChapterTitle.set_text(header.ChapterTitle)
	if header.Victory: 
		vLb.visible = true
		chTimeLb.visible = false
	else:
		vLb.visible = false
		chTimeLb.visible = true
		chTimeLb.set_text(timeString+denote)
	$ContentsHBox/SaveMargin/SaveVBox/PlayTimeHBox/PlayTime.set_text(str(header.PlayTime))
	
