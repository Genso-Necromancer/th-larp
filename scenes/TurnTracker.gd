extends Control
class_name TurnTracker
signal tracker_updated

#@export var token_limit := 11
@onready var turnBar := $MarginContainer/TurnBar
@onready var turnToken := preload("res://scenes/turn_token.tscn")
var active_animations := []
var turn_order :Array[StringName]=[]
var turn_que := 0
var pending_full_order : Array[StringName] = []
var rebuild_after_animation := false
var pending_append_team : StringName = &""
var pending_collapse_start_index := -1


func _process(_delta):
	if turn_que >0 and active_animations.is_empty():
		turn_que -= 1
		change_turn()


#func _ready():
	##self.visible = false
	#_test_start()
#
#
#func _unhandled_input(event):
	#if event.is_action_released("ui_accept"): add_turn("Player")
	#if event.is_action_released("ui_return"): 
		#remove_turn("Enemy")


##shifts tracker off screen
func hide_self()->void:
	get_tree().call_group("turns", "set_animation", "group_exit")


##brings tracker back after using hide_tracker()
func unhide_self()->void:
	get_tree().call_group("turns", "set_animation", "group_enter")


##Initializes turn tokens for new round
func display_turns(turnOrder:Array[StringName], animate_enter := true, animate_tail := false):
	var count:=0
	var nodes :Array = turnBar.get_children()
	active_animations.clear()
	turn_que = 0
	turn_order = turnOrder.duplicate()
	free_tokens()
	var created_tokens : Array[TurnToken] = []
	while count < nodes.size():
		var token : TurnToken
		var team :StringName
		if turn_order.is_empty(): break
		team = turn_order.pop_front()
		token = _instantiate_token(team, animate_enter)
		nodes[count].add_child(token)
		created_tokens.append(token)
		if animate_enter:
			active_animations.append(token)
		count +=1
	if animate_tail and !animate_enter and !created_tokens.is_empty():
		var tail := created_tokens[-1]
		tail.is_entering = true
		if !active_animations.has(tail):
			active_animations.append(tail)
		tail.set_animation("enter_list")
	


func _instantiate_token(team:StringName, animate_enter := true) -> TurnToken:
	var token :TurnToken= turnToken.instantiate()
	var frame : int
	match team:
		"Player": frame = 0
		"Enemy": frame = 3
		"NPC": frame = 1
	token.add_to_group("turns")
	token.is_entering = animate_enter
	token.play_enter_on_ready = animate_enter
	token.frame = frame
	token.set_scale = Vector2(0.25,0.25)
	token.animation_finished.connect(self._on_animation_finished)
	token.tween_finished.connect(self._on_tween_finished)
	return token


##Progress turn tokens
func change_turn()->void:
	var tokens : Array[TurnToken] = _get_tokens()
	if !active_animations.is_empty():
		turn_que += 1
		return
	if tokens.is_empty():
		return
	var leaving : TurnToken = tokens.pop_front()
	_set_exit(leaving)
	_shift_tokens_into_slots(tokens, 0)
	if !turn_order.is_empty():
		pending_append_team = turn_order.pop_front()
	else:
		pending_append_team = &""


func _set_exit(token:TurnToken)->void:
	token.is_exiting = true
	active_animations.append(token)
	token.set_animation("exit_list")


##Call to remove turn from list after a unit dies
func remove_turn(team:StringName)->void:
	var tokens : Array[TurnToken] = _get_tokens()
	var last_valid : TurnToken
	var frame : int = _frame_for_team(team)
	for token in tokens:
		if token.frame == frame:
			last_valid = token
	if last_valid:
		pending_collapse_start_index = last_valid.get_parent().get_index()
		_set_exit(last_valid)
		pending_append_team = &""
		if !turn_order.is_empty():
			pending_append_team = turn_order.pop_front()
	else:
		for i in range(turn_order.size() - 1, -1, -1):
			if turn_order[i] == team:
				turn_order.remove_at(i)
				break
		

##Call to add turn to list after unit appears
func add_turn(team:StringName)->void:
	var full_order := _get_full_order()
	full_order.append(team)
	display_turns(full_order, false)
		


func _animate_token(token:TurnToken, animation:StringName)->void:
	token.anim_player.play(animation)


func _on_animation_finished(animation:StringName, token:TurnToken)->void:
	active_animations.erase(token)
	if animation == "exit_list":
		if token.get_parent():
			token.get_parent().remove_child(token)
		token.queue_free()
	elif animation == "enter_list": token.is_entering = false
	_check_remaining()


func _check_remaining()->void:
	if !active_animations.is_empty():
		return
	if pending_collapse_start_index >= 0:
		var collapse_index := pending_collapse_start_index
		pending_collapse_start_index = -1
		var tokens := _get_tokens()
		if collapse_index < tokens.size():
			_shift_tokens_into_slots(tokens.slice(collapse_index), collapse_index)
			return
	if pending_append_team != &"":
		var nodes : Array = turnBar.get_children()
		var tokens : Array[TurnToken] = _get_tokens()
		if tokens.size() < nodes.size():
			var team := pending_append_team
			pending_append_team = &""
			var token := _instantiate_token(team, true)
			nodes[tokens.size()].add_child(token)
			active_animations.append(token)
			return
		pending_append_team = &""
	if rebuild_after_animation:
		var rebuild_order := pending_full_order.duplicate()
		rebuild_after_animation = false
		pending_full_order.clear()
		var should_animate_tail := rebuild_order.size() >= turnBar.get_children().size()
		display_turns(rebuild_order, false, should_animate_tail)
		tracker_updated.emit()
		return
	if _refill_visible_slots():
		return
	tracker_updated.emit()


func _queue_rise(tokens: Array[TurnToken]) -> void:
	for token in tokens:
		if token == null:
			continue
		if token.is_entering or token.is_exiting:
			continue
		if not active_animations.has(token):
			active_animations.append(token)
		token.rise_up()


func _shift_tokens_into_slots(tokens: Array[TurnToken], start_index: int) -> void:
	var nodes : Array = turnBar.get_children()
	for i in range(tokens.size()):
		var slot_index := start_index + i
		if slot_index >= nodes.size():
			break
		var token := tokens[i]
		if token == null:
			continue
		var target_parent: Control = nodes[slot_index]
		if token.get_parent() != target_parent:
			token.reparent(target_parent, false)
		if not active_animations.has(token):
			active_animations.append(token)
		token.shift_into_slot()


func _on_tween_finished(token: TurnToken) -> void:
	active_animations.erase(token)
	_check_remaining()


func _refill_visible_slots() -> bool:
	var nodes : Array = turnBar.get_children()
	var tokens : Array[TurnToken] = _get_tokens()
	if turn_order.is_empty():
		return false
	if tokens.size() >= nodes.size():
		return false
	var team : StringName = turn_order.pop_front()
	var token := _instantiate_token(team)
	nodes[tokens.size()].add_child(token)
	active_animations.append(token)
	return true


##frees all current tokens
func free_tokens():
	var tokens = _get_tokens()
	for token in tokens:
		if token.get_parent():
			token.get_parent().remove_child(token)
		token.queue_free()


func _get_tokens() -> Array[TurnToken]:
	var tokens :Array[TurnToken]=[]
	var nodes :Array = turnBar.get_children()
	for node in nodes:
		for child in node.get_children():
			tokens.append(child)
	return tokens


func _normalize_slots() -> void:
	var nodes : Array = turnBar.get_children()
	var tokens : Array[TurnToken] = _get_tokens()
	if tokens.is_empty():
		return
	tokens.sort_custom(func(a: TurnToken, b: TurnToken): return a.global_position.y < b.global_position.y)
	for i in range(tokens.size()):
		if i >= nodes.size():
			break
		var token := tokens[i]
		var target_parent: Control = nodes[i]
		if token.get_parent() != target_parent:
			token.reparent(target_parent, false)
		#token.position = Vector2.ZERO


func _get_full_order() -> Array[StringName]:
	var full : Array[StringName] = []
	for token in _get_tokens():
		full.append(_team_from_frame(token.frame))
	for team in turn_order:
		full.append(team)
	return full


func _team_from_frame(frame: int) -> StringName:
	match frame:
		0:
			return "Player"
		1:
			return "NPC"
		3:
			return "Enemy"
		_:
			return "Player"


func _frame_for_team(team: StringName) -> int:
	match team:
		"Player":
			return 0
		"NPC":
			return 1
		"Enemy":
			return 3
		_:
			return 0


#region test functions
func _test_start():
	var testArray :Array[StringName]=["Player","Enemy","Player","Player","Enemy","Player","Enemy","Player","Enemy","Player","Enemy",]
	display_turns(testArray)
