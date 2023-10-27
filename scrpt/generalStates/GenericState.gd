extends Node
class_name GenericState

var slaves = []
var keyBinds = ["ui_accept", "ui_info", "ui_return"]
var heldBinds =["ui_scroll_left", "ui_scroll_right", "ui_right", "ui_up", "ui_left", "ui_down"]
var uiCooldown = 0.2
var timer
var direction

func setup(newSlaves):
#	var i = 0
	if timer:
		timer.queue_free()
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	self.slaves.clear()
	if newSlaves == null or newSlaves.size() <= 0:
		print("NO NEW SLAVES")
		return
	for slave in newSlaves:
		self.slaves.append(slave)
#		i += 1

#	print(slaves)

func mouse_motion(event):
	pass
	
func mouse_pressed(event: InputEvent) -> void:
	var bind
	bind = _find_key_bind(event)
	_handle_bind(bind)
	
func event_key(event: InputEvent) -> void:
	var bind
	bind = _find_key_bind(event)
	if _handle_held_key(event, bind) == false:
		return
	_handle_bind(bind)
	timer.start()
	
func _find_key_bind(event):
	var bind = "invalid"
	for key in keyBinds:
		if event.is_action_pressed(key):
			bind = key
			break
	for key in heldBinds:
		if event.is_action(key):
			bind = key
			break
	return bind
	
func _handle_held_key(event: InputEvent, bind):
	var shouldMove := event.is_pressed()
	if event.is_echo():
		shouldMove = shouldMove and timer.is_stopped()
		timer.wait_time -= 0.05
		timer.wait_time = clampf(timer.wait_time, 0.05, 0.2)
	elif !event.is_echo():
		timer.wait_time = uiCooldown
	if not shouldMove:
		return false
	
		

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": pass
		"ui_return": pass
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
