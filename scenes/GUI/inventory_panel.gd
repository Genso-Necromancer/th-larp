@tool
extends PanelContainer

class_name InventoryPanel


@export var itemList : VBoxContainer
@export var equipContainer : MarginContainer
@export_category("Bag Style")
@export var styleNodes : Array[NinePatchRect]
var _style : String = "NONE" :
	get:
		return _style
	set(value):
		if value != "NONE":
			print(value)
			_style = value
			_set_style_style(_style)
		
			
const _styles: Array[String] = ["Trade", "Profile", "Preview"]

var items : Array = []

func _get_property_list():
	var properties = []
	
	properties.append({
		"name" : "_style",
		"type" : TYPE_STRING,
		"hint" : PROPERTY_HINT_ENUM,
		"hint_string" : _array_to_string(_styles)
		#"hint_string" : _array_to_string(UnitData.get_item_keys())
	})
		
		
	return properties

func _array_to_string(arr: Array, seperator = ",") -> String:
	var string = ""
	for i in arr:
		string += str(i)+seperator
	return string

func _set_style_style(mode:String):
	if styleNodes:
		for node in styleNodes:
			node.visible = false
		match mode:
			_styles[0]:
				styleNodes[0].visible = true
			_styles[1]:
				styleNodes[1].visible = true
				


func _ready():
	if not Engine.is_editor_hint():
		_ready_style()


func _ready_style():
		_set_style_style(_style)



func fill_items(isTrade : = false, reach = [0,0]) -> Array:
	var unit = get_meta("Unit")
	var inv = unit.unitData.Inv
	var iData = UnitData.itemData
	var i := 0
	var bPath = load("res://scenes/GUI/item_button.tscn")
	var equipped = unit.get_equipped_weapon()
	var b
	var displayItem = null
	
	if _style == _styles[1] and equipped.ID != "Unarmed":
		b = _generate_item_button(bPath, equipped, i, unit, isTrade)
		_display_weapon(b)
		displayItem = equipped
		i += 1
			
	for item in inv:
		if _style == _styles[1] and item == displayItem:
			continue
		if !reach[0]: pass
		elif !unit.check_valid_equip(item): continue
		elif iData[item.ID].MinRange > reach[0] or iData[item.ID].MaxRange < reach[1]: 
			continue
			
		b = _generate_item_button(bPath, item, i, unit, isTrade)
		
		_add_item(b)
		i += 1
	return items
	



func _generate_item_button(bPath, item : Dictionary, i : int, unit : Unit, isTrade : bool) -> ItemButton:
	
	var itemData = UnitData.itemData[item.ID]
	var b = bPath.instantiate()
	var dur = item.Dur
	var mDur = itemData.MaxDur
	var durString
	if dur == -1 or mDur == -1:
		durString = str(" --")
	else:
		durString = (str(dur) + "/" + str(mDur))
		
	b.set_item_text(str(itemData.Name), durString)
	b.set_item_icon(itemData.Icon)
	b.set_meta_data(item, unit, i, itemData.Trade)
	b.get_button().add_to_group("ItemTT")
	if isTrade and !itemData.Trade:
		b.state = "Disabled"
	elif _style == _styles[1] and !unit.check_valid_equip(item):
		b.state = "Disabled"
	
	#does this work still like this? HERE
	#b.get_button().set_focus_neighbor(SIDE_LEFT, b.get_path_to(b.get_button()))
	#b.get_button().set_focus_neighbor(SIDE_RIGHT, b.get_path_to(b.get_button()))
	
	
	return b


func _add_item(b: ItemButton):
	items.append(b)
	itemList.add_child(b)


func _check_display() -> bool:
	var isFilled := false
	if equipContainer.get_children().size() > 0:
		isFilled = true
	return isFilled


func _display_weapon(button : ItemButton):
	items.append(button)
	equipContainer.add_child(button)


func add_empty(unit) -> ItemButton:
	var b = load("res://scenes/GUI/item_button.tscn").instantiate()
	
	var i = items.size()
	b.set_item_text("", "")
	b.toggle_icon()
	b.set_meta_data(false, unit, i, true)
	_add_item(b)
	return b


func remove_empty():
	#var i := 0
	#var killList := []
	#while i < items.size():
		#if items[i].button.get_meta("Item"):
			#continue
		#else:
			#killList.append(i)
		#i += 1
		#
	#for k in killList:
		#var b = items.pop_at(k)
		#b.queue_free()
	for b in itemList.get_children():
		if b.button.get_meta("Item"):
			continue
		else:
			itemList.remove_child(b)
			b.queue_free()
	items = itemList.get_children()
	

func reindex_buttons():
	var i = 0
	for b in itemList.get_children():
		b.set_meta("Index", i)
		i += 1

func clear_items():
	if equipContainer and equipContainer.get_children().size() > 0:
		for kid in equipContainer.get_children():
			kid.queue_free()
	for b in itemList.get_children():
		itemList.remove_child(b)
		b.queue_free()
	items.clear()

func get_item_buttons() -> Array:
	var buttons := []
	for i in items:
		buttons.append(i.button)
	return buttons
