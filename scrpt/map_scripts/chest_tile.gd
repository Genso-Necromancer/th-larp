extends EnviornmentTile
class_name ChestTile

@export var _is_locked:=false:
	set(value):
		is_locked = value
		_is_locked = is_locked
@export var contents:Array[Item]=[]
var is_covered:= false
var covered_by:Unit


func unlock():
	super()
	SignalTower.chest_opened.emit(cell)


func stolen():
	if !is_locked: return
	is_locked = false
	SignalTower.chest_stolen.emit(cell)


func _on_tile_area_area_entered(area:AreaUnit):
	var unit:= area.get_master()
	is_covered = true
	covered_by = unit
	if unit.FACTION_ID == Enums.FACTION_ID.ENEMY and unit.can_pick(): stolen()
	elif unit.FACTION_ID == Enums.FACTION_ID.PLAYER and unit.can_pick(): unit.on_chest = true


func _on_tile_area_area_exited(area:AreaUnit):
	var unit:= area.get_master()
	covered_by = null
	is_covered = false
	unit.on_chest = false


func get_save_data()->Dictionary:
	var data :Dictionary= super()
	data["contents"] = contents
	return data


func load_save_data(data:Dictionary):
	super(data)
	contents = data.contents
