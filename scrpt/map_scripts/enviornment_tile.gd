extends InteractableTile
class_name EnviornmentTile
signal was_nullified(paired_cell:Vector2i)

var hp:=0:
	set(value):
		hp = clampi(value,0,999)
var hardness:= 0
var is_locked:= false:
	set(value):
		is_locked = value
		if !value: was_nullified.emit(cell)
var is_destroyed:= false:
	set(value):
		is_destroyed = value
		if value: was_nullified.emit(cell)


func damage_object(damage:=0)->void:
	var loss := damage-hardness
	if hp <= 0:return
	loss = clampi(loss,0,hp)
	hp -= loss
	if hp <= 0: is_destroyed = true


func unlock()->void:
	if !is_locked: return
	is_locked = false


func get_save_data()->Dictionary:
	var data:Dictionary = {}
	data["enabled"] = enabled
	data["is_locked"] = is_locked
	data["hardness"] = hardness
	data["hp"] = hp
	data["is_destroyed"] = is_destroyed
	return data


func load_save_data(data:Dictionary):
	enabled = data.enabled
	is_locked = data.is_locked
	hardness = data.hardness
	hp = data.hp
	is_destroyed = data.is_destroyed
