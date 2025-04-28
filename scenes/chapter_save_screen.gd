extends Control
class_name SaveScreen
signal save_scene_finished
signal state_changed(state)

enum PROMPT_ANSWER{YES,NO}
enum SCENE_STATE{SAVE_CHECK, EXIT_PROMPT, FILE_SELECT, OVERWRITE, SAVING, ENDING}
var state : SCENE_STATE = SCENE_STATE.SAVE_CHECK:
	set(value):
		state = value
		match value:
			SCENE_STATE.EXIT_PROMPT: pass
			SCENE_STATE.FILE_SELECT: pass
var state_chain : Array[SCENE_STATE] = []
var saved_once := false
var is_chapter_save := true
@onready var cursor : MenuCursor = $MainContainer/menu_cursor
@onready var save_prompt : MarginContainer = $MainContainer/PromptScreenEdge
@onready var file_container : MarginContainer = $MainContainer/FileSelectScreenEdge
@onready var file_list : VBoxContainer = $MainContainer/FileSelectScreenEdge/FilesVBox
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
var last_focus : Control


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
	if is_chapter_save:
		initial_focus = $MainContainer/PromptScreenEdge/PromptVBox/InputHBox/Confirm
		_change_state(SCENE_STATE.SAVE_CHECK)
		save_prompt.visible = true
		print("In Chapter Save Mode")
	else: pass #code to enter save/load mode.
	_fade_in()
	await initial_focus.button.draw
	#_init_cursor()
	call_deferred("_init_cursor")
	_init_signals()
	GameState.change_state(self,GameState.gState.SAVE_SCENE)


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


func _fade_in()-> void:
	var tween:= get_tree().create_tween()
	tween.tween_property(main_container,"modulate",Color(1.0, 1.0, 1.0, 1.0),1)
	
#endregion


#region input
func _on_confirm_button_pressed(_button:TextureLabelButton)-> void:
	_close_save_prompt()
	_load_save_files()
	_change_state(SCENE_STATE.FILE_SELECT)


func _on_deny_button_pressed(_button:TextureLabelButton)-> void:
	_fade_and_end()


func _on_continue_button_pressed(button:TextureLabelButton)-> void:
	match state:
		SCENE_STATE.EXIT_PROMPT: 
			_fade_and_end()
		SCENE_STATE.OVERWRITE: 
			_make_new_save(button)


func _on_return_button_pressed(_button)-> void:
	return_pressed()


func return_pressed()-> void:
	back_out()



func accept_prompt():
	pass


func back_out():
	match state:
		SCENE_STATE.FILE_SELECT: _exit_scene()
		SCENE_STATE.OVERWRITE: _close_prompt()
		SCENE_STATE.EXIT_PROMPT: _close_prompt()
	accept_event()

#endregion


#region state switching
func _change_state(new_state:SCENE_STATE) -> void:
	state_chain.append(state)
	state = new_state
	state_changed.emit(state)


func _to_previous_state() -> void:
	var newState : SCENE_STATE = state_chain.pop_back()
	state = newState
	state_changed.emit(state)


func _new_state_chain() -> void:
	var newFocus : Control
	if last_focus: newFocus = last_focus
	else: newFocus = file_list.get_children()[0]
	_move_cursor(newFocus)
	_change_state(SCENE_STATE.FILE_SELECT)
	state_chain.clear()
	

func _load_save_files() -> void:
	var buttonPath := load("res://scenes/GUI/save_file_button.tscn")
	var saveFiles : Array = []
	var remainder := 10 - saveFiles.size()
	var first : SaveFileButton = null
	var previous : SaveFileButton
	
	#call for existing save files
	for save in saveFiles:
		#Initialize buttons and assign save files
		var b : SaveFileButton = buttonPath.instantiate()
		file_list.add_child(b)
		if !first: 
			first = b
			previous = b
		else:
			b.set_neighbor(SIDE_TOP, previous.button)
			previous.set_neighbor(SIDE_BOTTOM, b.button)
			previous = b
		cursor._connect_btn_to_cursor(b.button)
		b.button_pressed.connect(self._on_save_pressed)
		b.button_focus_entered.connect(self._new_focus)
		b.key_input.connect(self._gui_input)
		b.set_neighbor(SIDE_LEFT,b.button)
		b.set_neighbor(SIDE_RIGHT, b.button)
		_format_save(save, b)
		
	while remainder > 0:
		var b :SaveFileButton= buttonPath.instantiate()
		file_list.add_child(b)
		if !first: 
			first = b
			previous = b
		else:
			b.set_neighbor(SIDE_TOP, previous.button)
			previous.set_neighbor(SIDE_BOTTOM, b.button)
			previous = b
		cursor._connect_btn_to_cursor(b.button)
		b.button_pressed.connect(self._on_save_pressed)
		b.button_focus_entered.connect(self._new_focus)
		b.key_input.connect(self._gui_input)
		b.set_neighbor(SIDE_LEFT,b.button)
		b.set_neighbor(SIDE_RIGHT, b.button)
		remainder -= 1
		
	if first:
		first.set_neighbor(SIDE_TOP,previous.button)
		previous.set_neighbor(SIDE_BOTTOM,first.button)
	file_container.visible = true
	await file_container.draw
	call_deferred("_move_cursor", first)
	#_move_cursor(first)


func _close_save_prompt() -> void:
	save_prompt.visible = false
	cursor.toggle_visible()


func _exit_scene() -> void:
	if saved_once: _fade_and_end()
	else: _exit_verify()


func _exit_verify():
	print("Verifying Exit")
	var prompt := $MainContainer/PromptContainer/PromptPositionContainer/PromptMargin/PromptVBox/LabelMargin/PromptLabel
	prompt.set_text(StringGetter.get_string("without_saving"))
	prompt_container.visible = true
	await prompt_container.draw
	call_deferred("_move_cursor",prompt_box.get_children()[0])
	#_move_cursor(prompt_box.get_children()[0])
	_change_state(SCENE_STATE.EXIT_PROMPT)

func _fade_and_end() -> void:
	var tween :=get_tree().create_tween()
	print("Ending Scene...")
	blocker.visible = true
	GameState.change_state(self,GameState.gState.LOADING)
	_change_state(SCENE_STATE.ENDING)
	prompt_container.visible = false
	cursor.visible = false
	tween.finished.connect(self._on_tween_fade_finished)
	tween.tween_property(main_container,"modulate",Color(1.0, 1.0, 1.0, 0.0),2)


func _on_tween_fade_finished() -> void:
	save_scene_finished.emit()
	print("Save Scene Finished")


func _verify_overwrite() -> void:
	print("Verifying overwrite")
	var prompt := $MainContainer/PromptContainer/PromptPositionContainer/PromptMargin/PromptVBox/LabelMargin/PromptLabel
	prompt.set_text(StringGetter.get_string("overwrite_save"))
	prompt_container.visible = true
	await prompt_container.draw
	call_deferred("_move_cursor",prompt_box.get_children()[0])
	#_move_cursor(prompt_box.get_children()[0])
	_change_state(SCENE_STATE.OVERWRITE)


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
	if is_chapter_save:
		match button.state:
			button.SCENE_STATE.EMPTY: 
				_make_new_save(button)
			button.SCENE_STATE.FILE: 
				_verify_overwrite()


func _format_save(save_file, button:SaveFileButton) -> void:
	button.set_file(save_file)
#endregion


#region saving
func _make_new_save(button:SaveFileButton) -> void:
	var saveFile = null
	print("creating new save....")
	_change_state(SCENE_STATE.SAVING)
	cursor.visible = false
	button.label_text = StringGetter.get_string("saving_file")
	#emit new_save signal and then retrieve the save file
	print("This is where I'd put saving code, IF I HAD ANY")
	button.label_text = StringGetter.get_string("save_complete")
	
	saved_once = true
	await get_tree().create_timer(0.5).timeout
	print("Done Saving")
	_format_save(saveFile, button)
	_new_state_chain()
#endregion


#func _on_deny_button_focus_entered(button):
	#pass # Replace with function body.
#
#
#func _on_continue_button_focus_entered(button):
	#pass # Replace with function body.
