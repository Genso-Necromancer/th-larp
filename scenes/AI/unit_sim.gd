extends Node
##Used to simulate units within the AI's thinking process
class_name UnitSim

var id:String
var team:Enums.FACTION_ID
var cell:Vector2i
var hp:int
var comp:int
var total_stats:Dictionary[StringName,int]
var active_stats:Dictionary[StringName,int]
var status:Dictionary
var status_data:Dictionary
var weapon:Dictionary
var inventory:Dictionary
var natural:Dictionary
var skills:Dictionary
var passives:Dictionary
var auras
var threats:Array
var move_type:Enums.MOVE_TYPE
var terrain_tags:Dictionary


func clone() -> UnitSim:
	var c = UnitSim.new()
	c.id = id
	c.team = team
	c.cell = cell
	c.hp = hp
	c.comp = comp
	c.total_stats = total_stats.duplicate(true)
	c.active_stats = active_stats.duplicate(true)
	c.status = status.duplicate(true)
	c.status_data = status_data.duplicate(true)
	c.passives = passives.duplicate()
	c.skills = skills.duplicate()
	c.inventory = inventory.duplicate(true)
	c.weapon = weapon.duplicate(true)
	c.natural = natural.duplicate(true)
	c.threats = threats.duplicate()
	c.move_type = move_type
	c.terrain_tags = terrain_tags.duplicate(true)
	return c
