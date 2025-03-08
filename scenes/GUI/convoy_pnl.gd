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
	FAN,
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
var supplyStats = UnitData.supplyStats

func _ready():
	var container := $VBoxContainer/PanelContainer2/MarginContainer/tabContainer
	tabs = container.get_children()
	
	
func fill_items(_isTrade := false, reach = [0,0], useBorder = false) -> Array:
	var tabKeys = tabTypes.keys()
	var supply = UnitData.supply[tabKeys[openTab]]
	var i = 0
	var bPath = load("res://scenes/GUI/item_button.tscn")
	for item in supply:
		var itemData = UnitData.itemData[item.ID]
		var b = bPath.instantiate()
		var dur = item.Dur
		var mDur = itemData.MaxDur
		var durString
		if dur == -1 or mDur == -1:
			durString = str(" --")
		else:
			durString = str(dur) + "/" + str(mDur)
		b.set_item_text(str(itemData.Name), durString)
		b.set_item_icon(itemData.Icon)
		b.set_meta_data(item, "Supply", i, itemData.Trade)
		b.useBorder = useBorder
		i += 1
		_add_item(b)
	return items

func _change_tab():
	clear_items()

func sort_supply() -> Array:
	var tabKeys = tabTypes.keys()
	var supply = UnitData.supply[tabKeys[openTab]]
	supply.sort_custom(_sort_items)
	clear_items()
	return fill_items()
	

func _sort_items(a, b):
	var itemData = UnitData.itemData
	var aName = itemData[a.ID].Name
	var bName = itemData[b.ID].Name
	var aDur = a.Dur
	var bDur = b.Dur
	var checkDur = false
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

	
