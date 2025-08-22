@tool
extends TextureLabelButton
class_name SaveFileButton

enum SCENE_STATE{
	EMPTY, ##No Save File associated with button
	FILE ##Has a valid save file
}
var state : SCENE_STATE = SCENE_STATE.EMPTY
var save_name : String


func _ready():
	pass
	


##Assigns an existing save file.[br]
func set_file(file_name:String) -> void:
	if SaveHub.is_valid_file(file_name): state = SCENE_STATE.FILE
	else: state = SCENE_STATE.EMPTY
	_format(file_name)


func get_save_file() -> String:
	return save_name


func _format(file_name:String) -> void:
	var headStone := SaveHub.get_header(file_name)
	var saveData:Dictionary
	if !headStone: state = SCENE_STATE.EMPTY
	elif headStone.SaveType == Enums.SAVE_TYPE.SUSPENDED: _enable_suspended_format()
	match state:
		SCENE_STATE.EMPTY: save_name = file_name
		SCENE_STATE.FILE:
			save_name = file_name
			_format_save_slot(headStone)


func _enable_suspended_format():
	## put code here to change visuals of the save file to indicate it's typing
	pass

func _format_save_slot(header: Dictionary):
	var date:= "%d/%d/%d - %d:%d:%d" % [header.Date.month,header.Date.day,header.Date.year,header.Date.hour,header.Date.minute,header.Date.second]
	var saveSlot:String= header.FileName.get_slice(".",0)
	var denote:String
	var timeUnits : Dictionary = Global.float_to_time(header.game_time)
	var timeString : String = Global.time_to_string(timeUnits.Hours, timeUnits.Minutes)
	var vLb:= $ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/IsComplete
	var chTimeLb:= $ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/ChapterTime
	match header.get("time_of_day",1):
		Enums.TIME.NIGHT: denote = "PM"
		Enums.TIME.DAY: denote = "AM"
	$ContentsHBox/SaveMargin.visible = true
	$ContentsHBox/LabelMargin.visible = false
	$ContentsHBox/SaveMargin/SaveVBox/HeaderVBox/FileSlot.set_text(saveSlot)
	$ContentsHBox/SaveMargin/SaveVBox/HeaderVBox/Date.set_text(date)
	$ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/ChapterNumber.set_text(str(header.chapter_number))
	$ContentsHBox/SaveMargin/SaveVBox/ChapterHBox/ChapterTitle.set_text(header.chapter_title)
	if header.victory:
		vLb.visible = true
		chTimeLb.visible = false
	else:
		vLb.visible = false
		chTimeLb.visible = true
		chTimeLb.set_text(timeString+denote)
	#$ContentsHBox/SaveMargin/SaveVBox/PlayTimeHBox/PlayTime.set_text(str(header.PlayTime))
	
