extends Resource
class_name PlayerSupply

@export var BLADE :Array[Item] = []
@export var BLUNT :Array[Item] = []
@export var STICK :Array[Item] = []
@export var GOHEI :Array[Item] = []
@export var BOOK :Array[Item] = []
@export var OFUDA :Array[Item] = []
@export var BOW :Array[Item] = []
@export var GUN :Array[Item] = []
@export var ACC :Array[Item] = []
@export var ITEM :Array[Item] = []
@export var player_mon:int=0
var BLADE_DEFAULT :Array[Item] = []
var BLUNT_DEFAULT :Array[Item] = []
var STICK_DEFAULT :Array[Item] = []
var GOHEI_DEFAULT :Array[Item] = []
var BOOK_DEFAULT :Array[Item] = []
var OFUDA_DEFAULT :Array[Item] = []
var BOW_DEFAULT :Array[Item] = []
var GUN_DEFAULT :Array[Item] = []
var ACC_DEFAULT :Array[Item] = []
var ITEM_DEFAULT :Array[Item] = []
var player_mon_DEFAULT :int=0
var supply_stats:={"Max": 180, "Count": 0}
var pages :Array[String] =[
		"BLADE",
		"BLUNT",
		"STICK",
		"GOHEI",
		"BOOK",
		"OFUDA",
		"BOW",
		"GUN",
		"ACC",
		"ITEM",
		]


func _init():
	_set_reset_values()
	
	
func _set_reset_values():
	BLADE_DEFAULT = BLADE
	BLUNT_DEFAULT = BLUNT
	STICK_DEFAULT = STICK
	GOHEI_DEFAULT = GOHEI
	BOOK_DEFAULT = BOOK
	OFUDA_DEFAULT = OFUDA
	BOW_DEFAULT = BOW
	GUN_DEFAULT = GUN
	ACC_DEFAULT = ACC
	ITEM_DEFAULT = ITEM
	player_mon_DEFAULT = player_mon


func _reset_state():
	BLADE= BLADE_DEFAULT
	BLUNT= BLUNT_DEFAULT
	STICK= STICK_DEFAULT
	GOHEI= GOHEI_DEFAULT
	BOOK= BOOK_DEFAULT
	OFUDA= OFUDA_DEFAULT
	BOW= BOW_DEFAULT
	GUN= GUN_DEFAULT
	ACC= ACC_DEFAULT
	ITEM= ITEM_DEFAULT
	player_mon= player_mon_DEFAULT
	supply_stats={"Max": 180, "Count": 0}


func get_supply_as_save_data()->Dictionary:
	var sdSupply:={}
	var RC:=ResourceConverter.new()
	for page in pages:
		sdSupply[page] = RC.resources_to_save_data(self.get(page))
	return sdSupply


func load_supply(save_data:Dictionary):
	var RC:=ResourceConverter.new()
	for page in save_data:
		self.set(page,RC.inventory_to_resource(save_data[page]))
