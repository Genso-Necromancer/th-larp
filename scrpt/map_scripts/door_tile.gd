extends EnviornmentTile
class_name DoorTile

@export var _is_locked:= true:
	set(value):
		is_locked = value
		_is_locked = is_locked
@export var _hp:=0:
	set(value):
		hp = value
		_hp = hp
@export var _hardness:=0:
	set(value):
		hardness = value
		_hardness = hardness


func unlock():
	super()
	SignalTower.door_unlocked.emit(cell)
