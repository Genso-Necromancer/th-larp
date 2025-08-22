extends Control
class_name SaveScreen
signal save_scene_finished(self_ref:SaveScreen)
signal file_selected(save_number:int)
signal state_changed(state)

enum PROMPT_ANSWER{YES,NO}
enum SCENE_STATE{SAVE_CHECK, EXIT_PROMPT, FILE_SELECT, OVERWRITE, SAVING, LOADING, ENDING}

var state : SCENE_STATE = SCENE_STATE.SAVE_CHECK:
	set(value):
		state = value
		match value:
			SCENE_STATE.EXIT_PROMPT: pass
			SCENE_STATE.FILE_SELECT: pass
var _state_chain : Array[SCENE_STATE] = []
var _saved_once := false
var save_type : Enums.SAVE_TYPE = Enums.SAVE_TYPE.NONE
var last_focus : Control
var save_slots:Dictionary[String,SaveFileButton] = {}
var cached_button:SaveFileButton #Stores save slot when prompting user
@onready var cursor : MenuCursor = $MainContainer/menu_cursor
@onready var save_prompt : MarginContainer = $MainContainer/PromptScreenEdge
@onready var file_container : MarginContainer = $MainContainer/FileSelectScreenEdge
@onready var file_list : VBoxContainer = %FilesVBox
@onready var main_container : PanelContainer = $MainContainer
@onready var prompt_container : PanelContainer = $MainContainer/PromptContainer
@onready var blocker : Panel = $Blocker
@export var input_box : HBoxContainer
@export var prompt_box : HBoxContainer
var initial_focus : TextureLabelButton
@export var prompt_offset : Vector2:
	set(value):
		prompt_offset = value
		if cursor and value: cursor.cursor_offset = value


func _gui_input(event):
	if GameState.activeState == null:
			return
	if event is InputEventMouseMotion:
		GameState.activeState.mouse_motion(event)
	elif event is InputEventMouseButton:
		GameState.activeState.mouse_pressed(event)
	elif event is InputEventKey:
		GameState.activeState.event_key(event)


#region ready
func _ready():
	main_container.set_modulate(Color(1.0, 1.0, 1.0, 0.0))
	prompt_container.visible = false
	file_container.visible = false
	blocker.visible = false
	match save_type:
		Enums.SAVE_TYPE.NONE: #used for loading saves
			_close_save_prompt()
			_load_save_files()
			_change_state(SCENE_STATE.FILE_SELECT)
		Enums.SAVE_TYPE.TRANSITION:
			initial_focus = $MainContainer/PromptScreenEdge/PromptVBox/InputHBox/Confirm
			_change_state(SCENE_STATE.SAVE_CHECK)
			save_prompt.visible = true
			print("In Chapter Save Mode")
		Enums.SAVE_TYPE.SET_UP:
			_close_save_prompt()
			_load_save_files()
			_change_state(SCENE_STATE.FILE_SELECT)
	_fade_in()
	if initial_focus:
		await initial_focus.button.draw
		call_deferred("_init_cursor")
	_init_signals()
	GameState.change_state(self,GameState.gState.SAVE_SCENE)
	SaveHub.save_complete.connect(self._on_save_complete)


func _init_cursor() -> void:
	if prompt_offset: 
		cursor.cursor_offset = prompt_offset
	_move_cursor(initial_focus)


func _init_signals() -> void:
	for button :TextureLabelButton in input_box.get_children():
		var b : TextureButton = button.button
		cursor._connect_btn_to_cursor(b)
	for button :TextureLabelButton in prompt_box.get_children():
		var b : TextureButton = button.button
		cursor._connect_btn_to_cursor(b)


func _fade_in(speed:int=1)-> void:
	var tween:= get_tree().create_tween()
	tween.tween_property(main_container,"modulate",Color(1.0, 1.0, 1.0, 1.0),speed)
	
#endregion


#region input
func _on_confirm_button_pressed(_button:TextureLabelButton)-> void:
	_close_save_prompt()
	_load_save_files()
	_change_state(SCENE_STATE.FILE_SELECT)


func _on_deny_button_pressed(_button:TextureLabelButton)-> void:
	_fade_and_end()


func _on_continue_button_pressed(_button:TextureLabelButton)-> void:
	match state:
		SCENE_STATE.EXIT_PROMPT: 
			_fade_and_end(1)
		SCENE_STATE.OVERWRITE:
			_make_new_save(cached_button)
			_close_prompt()
		SCENE_STATE.LOADING:
			_push_file()
			_fade_and_end(1)
			


func _on_return_button_pressed(_button)-> void:
	return_pressed()


func return_pressed()-> void:
	back_out()



func accept_prompt():
	pass


func back_out():
	match state:
		SCENE_STATE.FILE_SELECT: _exit_scene()
		SCENE_STATE.OVERWRITE,SCENE_STATE.LOADING: _close_prompt()
		SCENE_STATE.EXIT_PROMPT: _close_prompt()
	accept_event()

#endregion


#region state switching
func _change_state(new_state:SCENE_STATE) -> void:
	_state_chain.append(state)
	state = new_state
	state_changed.emit(state)


func _to_previous_state() -> void:
	var newState : SCENE_STATE = _state_chain.pop_back()
	state = newState
	state_changed.emit(state)


func _new_state_chain() -> void:
	var newFocus : Control
	if last_focus: newFocus = last_focus
	else: newFocus = file_list.get_children()[0]
	_move_cursor(newFocus)
	_change_state(SCENE_STATE.FILE_SELECT)
	_state_chain.clear()
	

func _load_save_files() -> void:
	var saveFiles : Array = SaveHub.get_save_files()
	var remainder := 8 - saveFiles.size()
	var first : SaveFileButton = null
	var previous : SaveFileButton
	#var plusOne := false
	var fileCount := 0
	#call for existing save files
	
	var suspended:= _get_suspended_save(saveFiles)
	if suspended:
		var b : SaveFileButton = _instantiate_save_button(suspended)
		first = b
		previous = b
	
	for save in saveFiles:
		var b : SaveFileButton = _instantiate_save_button(save)
		if !first: 
			first = b
			previous = b
		else:
			b.set_neighbor(SIDE_TOP, previous.button)
			previous.set_neighbor(SIDE_BOTTOM, b.button)
			previous = b
		fileCount += 1

	while remainder > 0:
		var fileName:String= SaveHub.save_format % fileCount
		var b : SaveFileButton = _instantiate_save_button(fileName)
		fileCount += 1
		if !first: 
			first = b
			previous = b
		else:
			b.set_neighbor(SIDE_TOP, previous.button)
			previous.set_neighbor(SIDE_BOTTOM, b.button)
			previous = b
		remainder -= 1
		
	if first:
		first.set_neighbor(SIDE_TOP,previous.button)
		previous.set_neighbor(SIDE_BOTTOM,first.button)
	file_container.visible = true
	await file_container.draw
	call_deferred("_move_cursor", first)
	#_move_cursor(first)


func _get_suspended_save(files:Array) -> String:
	var i := files.find(SaveHub.suspended_format)
	var fileName : String
	if i > -1: 
		fileName = files.pop_at(i)
		return fileName
	else: return ""


func _instantiate_save_button(save_name:String) -> SaveFileButton:
	var buttonPath := load("res://scenes/GUI/save_file_button.tscn")
	var b : SaveFileButton = buttonPath.instantiate()
	
	file_list.add_child(b)
	save_slots[save_name] = b
	cursor._connect_btn_to_cursor(b.button)
	b.button_pressed.connect(self._on_save_pressed)
	b.button_focus_entered.connect(self._new_focus)
	b.key_input.connect(self._gui_input)
	b.set_neighbor(SIDE_LEFT,b.button)
	b.set_neighbor(SIDE_RIGHT, b.button)
	_format_save(save_name, b)
	return b


func _close_save_prompt() -> void:
	save_prompt.visible = false
	cursor.toggle_visible()


func _exit_scene() -> void:
	if _saved_once: _fade_and_end()
	else: _exit_verify()


func _exit_verify():
	print("Verifying Exit")
	var prompt := $MainContainer/PromptContainer/PromptPositionContainer/PromptMargin/PromptVBox/LabelMargin/PromptLabel
	var promptString:String
	match save_type:
		Enums.SAVE_TYPE.NONE: promptString = "return_title"
		Enums.SAVE_TYPE.TRANSITION: promptString = "without_saving"
		Enums.SAVE_TYPE.SET_UP: promptString = "return_setup"
	prompt.set_text(StringGetter.get_string(promptString))
	prompt_container.visible = true
	await prompt_container.draw
	call_deferred("_move_cursor",prompt_box.get_children()[0])
	#_move_cursor(prompt_box.get_children()[0])
	_change_state(SCENE_STATE.EXIT_PROMPT)


func _fade_and_end(speed:int = 2) -> void:
	var tween :=get_tree().create_tween()
	print("Ending Scene...")
	blocker.visible = true
	GameState.change_state(self,GameState.gState.LOADING)
	_change_state(SCENE_STATE.ENDING)
	prompt_container.visible = false
	cursor.visible = false
	tween.finished.connect(self._on_tween_fade_finished)
	tween.tween_property(main_container,"modulate",Color(1.0, 1.0, 1.0, 0.0),speed)


func _on_tween_fade_finished() -> void:
	save_scene_finished.emit(self)
	print("Save Scene Finished")
	queue_free()


func _verify_overwrite() -> void:
	#print("Verifying overwrite")
	var prompt := $MainContainer/PromptContainer/PromptPositionContainer/PromptMargin/PromptVBox/LabelMargin/PromptLabel
	prompt.set_text(StringGetter.get_string("overwrite_save") % [cached_button.save_name])
	prompt_container.visible = true
	await prompt_container.draw
	call_deferred("_move_cursor",prompt_box.get_children()[0])
	#_move_cursor(prompt_box.get_children()[0])
	_change_state(SCENE_STATE.OVERWRITE)


func _verify_load() -> void:
	var prompt := $MainContainer/PromptContainer/PromptPositionContainer/PromptMargin/PromptVBox/LabelMargin/PromptLabel
	prompt.set_text(StringGetter.get_string("load_file_normal") % [cached_button.save_name])
	prompt_container.visible = true
	await prompt_container.draw
	call_deferred("_move_cursor",prompt_box.get_children()[0])
	_change_state(SCENE_STATE.LOADING)


func _close_prompt() -> void:
	if last_focus: _move_cursor(last_focus)
	prompt_container.visible = false
	_to_previous_state()
#endregion


#region cursor manipulation
func _move_cursor(new_button:Control, off_set:Vector2 = cursor.cursor_offset) -> void:
	if !cursor.visible: cursor.toggle_visible()
	if off_set != cursor.cursor_offset: cursor.cursor_offset = off_set
	if new_button is not TextureButton:
		new_button = new_button.button
	new_button.call_deferred("grab_focus")
	cursor.set_cursor(new_button)

func _new_focus(button):
	last_focus = button
#endregion


#region save buttons
func _connect_save(b: SaveFileButton) -> void:
	var clickable : TextureButton = b.button
	cursor._connect_btn_to_cursor(clickable)
	b.button_pressed.connect(self._on_save_pressed)


func _on_save_pressed(button:SaveFileButton) -> void:
	match save_type:
		Enums.SAVE_TYPE.NONE: 
			match button.state:
				button.SCENE_STATE.EMPTY:
					_button_invalid_sfx()
					return
				button.SCENE_STATE.FILE:
					cached_button = button
					_verify_load()
		Enums.SAVE_TYPE.TRANSITION,Enums.SAVE_TYPE.SET_UP:
			match button.state:
				button.SCENE_STATE.EMPTY:
					_make_new_save(button)
				button.SCENE_STATE.FILE:
					cached_button = button
					_verify_overwrite()
			

func _format_save(save_name:String, button:SaveFileButton) -> void:
	button.set_file(save_name)
#endregion


#region saving
func _make_new_save(button:SaveFileButton) -> void:
	var saveFile :String= button.get_save_file()
	print("["+saveFile+"]"+"creating new save....")
	_change_state(SCENE_STATE.SAVING)
	cursor.visible = false
	button.label_text = StringGetter.get_string("saving_file")
	SaveHub.save_to_file(saveFile, save_type)
	#print("["+saveFile+"]"+"Awaiting signal....")
	#button.label_text = StringGetter.get_string("save_complete")
	
	
func _on_save_complete(file_name:String):
	_saved_once = true
	print("[save_"+file_name+"]"+"Done Saving")
	_format_save(file_name, save_slots[file_name])
	_new_state_chain()
#endregion


func _push_file():
	file_selected.emit(cached_button.save_name)

#func _on_deny_button_focus_entered(button):
	#pass # Replace with function body.
#
#
#func _on_continue_button_focus_entered(button):
	#pass # Replace with function body.

#region sfx
func _button_invalid_sfx(): # SFX Missing
	print("[chapter_save_screen]Invalid SFX missing")
	#if visible:
		#SignalTower.audio_called.emit("Invalid")
#endregion
