extends Control
class_name TurnTracker
signal turn_changed

#@export var token_limit := 11
@onready var turnBar := $MarginContainer/TurnBar
@onready var turnToken := preload("res://scenes/turn_token.tscn")
var active_animations := []
var turn_order :Array[StringName]=[]
var turn_que := 0


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
func display_turns(turnOrder:Array[StringName]):
	var count:=0
	var nodes :Array = turnBar.get_children()
	turn_order = turnOrder.duplicate()
	free_tokens()
	while count < nodes.size():
		var token : TurnToken
		var team :StringName
		if turn_order.is_empty(): break
		team = turn_order.pop_front()
		token = _instantiate_token(team)
		nodes[count].add_child(token)
		active_animations.append(token)
		count +=1
		


func _instantiate_token(team:StringName) -> TurnToken:
	var token :TurnToken= turnToken.instantiate()
	var frame : int
	match team:
		"Player": frame = 0
		"Enemy": frame = 3
		"NPC": frame = 1
	token.add_to_group("turns")
	token.is_entering = true
	token.frame = frame
	token.set_scale = Vector2(0.25,0.25)
	token.animation_finished.connect(self._on_animation_finished)
	return token


##Progress turn tokens
func change_turn()->void:
	var tokens : Array = _get_tokens()
	var leaving : TurnToken 
	var newTeam : String
	var nodes := turnBar.get_children()
	if !active_animations.is_empty(): 
		turn_que += 1
		return
	if tokens.is_empty(): return
	leaving = tokens.pop_front()
	_set_exit(leaving)
	if !turn_order.is_empty(): 
		newTeam = turn_order.pop_front()
		nodes[-1].add_child(_instantiate_token(newTeam))
	get_tree().call_group("turns","rise_up")


func _set_exit(token:TurnToken)->void:
	token.is_exiting = true
	active_animations.append(token)
	token.set_animation("exit_list")


##Call to remove turn from list after a unit dies
func remove_turn(team:StringName)->void:
	if turn_order.has(team):
		var i := turn_order.rfind(team)
		turn_order.remove_at(i)
	else:
		var tokens : Array[TurnToken] = _get_tokens()
		var lastValid : TurnToken
		var frame : int
		match team:
			"Player": frame = 0
			"NPC": frame = 1
			"Enemy": frame = 3
		for token in tokens:
			if token.frame == frame: lastValid = token
		if lastValid:
			var i := tokens.rfind(lastValid) + 1
			_set_exit(lastValid)
			while i < tokens.size():
				tokens[i].rise_up()
				i+=1
		

##Call to add turn to list after unit appears
func add_turn(team:StringName)->void:
	var nodes :Array = turnBar.get_children()
	var tokens :Array[TurnToken] = _get_tokens()
	if turn_order.is_empty() and nodes.size() > tokens.size(): nodes[tokens.size()].add_child(_instantiate_token(team))
	else: turn_order.append(team)
		


func _animate_token(token:TurnToken, animation:StringName)->void:
	token.anim_player.play(animation)


func _on_animation_finished(animation:StringName, token:TurnToken)->void:
	active_animations.erase(token)
	if animation == "exit_list": token.queue_free()
	elif animation == "enter_list": token.is_entering = false
	_check_remaining()


func _check_remaining()->void:
	if active_animations.is_empty(): turn_changed.emit()


##frees all current tokens
func free_tokens():
	var tokens = _get_tokens()
	for token in tokens:
		token.queue_free()


func _get_tokens() -> Array[TurnToken]:
	var tokens :Array[TurnToken]=[]
	var nodes :Array = turnBar.get_children()
	for node in nodes:
		for child in node.get_children():
			tokens.append(child)
	return tokens


#region test functions
func _test_start():
	var testArray :Array[StringName]=["Player","Enemy","Player","Player","Enemy","Player","Enemy","Player","Enemy","Player","Enemy",]
	display_turns(testArray)
