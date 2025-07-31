@tool
extends InventoryPanel
class_name ConvoyPanel

enum tabTypes {
	BLADE,
	BLUNT,
	STICK,
	BOW,
	GUN,
	GOHEI,
	BOOK,
	OFUDA,
	ACC,
	ITEM
}

var tabs : Array = []

var openTab := tabTypes.BLADE:
	set(value):
		if tabTypes.find_key(value) == null:
			print("Invalid Tab Enum")
			return
		openTab = value
		_change_tab()
		

#Supply Tracking
var supplyStats = PlayerData.supplyStats

func _ready():
	var container := $VBoxContainer/PanelContainer2/MarginContainer/tabContainer
	tabs = container.get_children()
	_convert_string_to_item()


func _convert_string_to_item():
	var tabKeys = tabTypes.keys()
	var supply = PlayerData.supply
	for tab in tabKeys:
		for entry in supply[tab]:
			if entry is String: entry = load(entry).duplicate()


func fill_items(_isTrade := false, _reach = [0,0], useBorder = false) -> Array:
	var tabKeys = tabTypes.keys()
	var supply = PlayerData.supply[tabKeys[openTab]]
	var i = 0
	var bPath = load("res://scenes/GUI/item_button.tscn")
	
	for item in supply:
		if item is String: item = _load_new_item(item)
		if item == null: continue
		var iconPath : String = "res://sprites/icons/items/%s/%s.png"
		var folder : String
		var b :ItemButton = bPath.instantiate()
		if item is Weapon: folder = "weapon"
		elif item is Accessory: folder = "accessory"
		elif item is Consumable: folder = "consumable"
		iconPath = iconPath % [folder, item.id]
		
		b.set_item_text(item)
		b.set_item_icon(item.id)
		b.set_meta_data(item, "Supply", i, item.trade)
		b.useBorder = useBorder
		i += 1
		_add_item(b)
	return items

func _change_tab():
	clear_items()

func sort_supply() -> Array:
	var tabKeys = tabTypes.keys()
	var supply = PlayerData.supply[tabKeys[openTab]]
	supply.sort_custom(_sort_items)
	clear_items()
	return fill_items()
	

func _sort_items(a:Item, b:Item):
	var aName :String= a.id
	var bName :String= b.id
	var aDur :int= a.dur
	var bDur :int= b.dur
	var checkDur := false
	if aName < bName:
		return true
	elif aName == bName:
		checkDur = true
	else:
		return false
	if checkDur and aDur > bDur:
		return true
	else:
		return false


func _load_new_item(path:String) -> Item:
	var res := load(path)
	var newItem : Item
	if res is WeaponResource: newItem = Weapon.new().duplicate()
	elif res is AccessoryResource: newItem = Accessory.new().duplicate()
	elif res is ConsumableResource: newItem = Consumable.new().duplicate()
	newItem.stats = res
	return newItem
