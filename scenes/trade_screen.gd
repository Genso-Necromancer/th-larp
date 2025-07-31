extends Control
class_name TradeScreen

signal item_list_filled(buttons)
signal item_selected
signal new_btn_added
signal trade_closed
signal trd_focus_changed



@export var nFSize = 30
@export var iFSize = 30


#Node references
@onready var box1 = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/TradeBox1
@onready var box2 = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/TradeBox2
@onready var list1 :InventoryPanel= $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/TradeBox1/TradePnl1
@onready var list2 :InventoryPanel= $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/TradeBox2/TradePnl2
@onready var sprite1 = $CharacterArtGroup/MarginContainer/PrtPnl1/MarginContainer/UnitPrt1
@onready var sprite2 = $CharacterArtGroup/MarginContainer/PrtPnl2/MarginContainer/UnitPrt2
@onready var prtPanel1 = $CharacterArtGroup/MarginContainer/PrtPnl1
@onready var prtPanel2 = $CharacterArtGroup/MarginContainer/PrtPnl2
@onready var infoPanel = $TradeContainer/MarginContainer/TradeScreenVBox/InfoPanel
@onready var supplyPanel = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/ConvoyPnl
#@onready var tabContainer = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer2/MarginContainer/tabContainer
@onready var optionsPop :OptionsPopUp = $OptionsPopUp
#@onready var effTitle = $TradeContainer/MarginContainer/TradeScreenVBox/ItemInfoPanel/MarginContainer/VBoxContainer/EffectTitleBox
var list_snap : Array = []
#Trade tracking
var firstBtn : ItemButton
var firstUnit : Unit
var secondUnit : Unit

#cursorTracking
var lastClicked : BaseButton
var swapIndx = null

#trade states
enum tStates {
	DEFAULT,
	TRADE,
	SUPPLY,
	MANAGE,
	ITEMOP,}
	
var tState := tStates.DEFAULT:
	set(value):
		tState = value

#tabs
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
		

#Supply Tracking
var supplyStats = PlayerData.supplyStats

#func _init():
	#toggle_visible()


func _ready():
	_connect_signals()
	_connect_tabs()
	_hide_panels()
	_refresh_count()


func _init():
	visible = false


func toggle_visible():
	visible = !visible
	infoPanel.call_deferred("open_popup")
	infoPanel.toggle_focus_signal()


func _hide_panels():
	box1.visible = false
	box2.visible = false
	supplyPanel.visible = false


func _connect_signals():
	var parent = get_parent()
	self.item_selected.connect(parent._on_item_selected)
	self.new_btn_added.connect(parent._connect_btn_to_cursor)
	self.trade_closed.connect(parent._on_trade_closed)
	self.item_list_filled.connect(parent._on_item_list_filled)
	self.trd_focus_changed.connect(parent._on_trd_focus_changed)
	
	


func _reparent_info(mode:int) -> void:
	var oldParent = infoPanel.get_parent()
	var newParent
	match mode:
		0: newParent = $TradeContainer/MarginContainer/TradeScreenVBox
		_: newParent = box1
	
	if !oldParent:
		pass
	elif oldParent == newParent:
		return
	else:
		oldParent.remove_child(infoPanel)
	newParent.add_child(infoPanel)
	#var newPath = get_path_to(infoPanel)
	#infoPanel = get_node(newPath)

func _refresh_count():
	var countLabel = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/ConvoyPnl/VBoxContainer/SupplyCountPanel/MarginContainer/HBoxContainer/SupplyCount
	var capLabel = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/ConvoyPnl/VBoxContainer/SupplyCountPanel/MarginContainer/HBoxContainer/SupplyCap
	var supply : Dictionary = PlayerData.supply
	supplyStats.Count = 0
	
	for key in supply.keys():
		supplyStats.Count += supply[key].size()
	
	capLabel.set_text(str(supplyStats.Max))
	countLabel.set_text(str(supplyStats.Count))
	if supplyStats.Count >= supplyStats.Max:
		_font_state_change(countLabel, "Capped")
	else:
		_font_state_change(countLabel)


func _font_state_change(node, state := ""):
	var fColor
	match state:
		"Capped": fColor = Color(0.604, 0, 0)
		_: 
			node.remove_theme_color_override("font_color")
			node.remove_theme_color_override("font_pressed_color")
			node.remove_theme_color_override("font_hover_color")
			node.remove_theme_color_override("font_focus_color")
			node.remove_theme_color_override("font_hover_pressed_color")
			return
	node.add_theme_color_override("font_color", fColor)
	node.add_theme_color_override("font_pressed_color", fColor)
	node.add_theme_color_override("font_hover_color", fColor)
	node.add_theme_color_override("font_focus_color", fColor)
	node.add_theme_color_override("font_hover_pressed_color", fColor)
	
	
func open_trade_menu(unit1, unit2):
	firstUnit = unit1
	secondUnit = unit2
	toggle_visible()
	box1.visible = true
	box2.visible = true
	tState = tStates.TRADE
	_load_sprites([unit1, unit2])
	_load_names([unit1, unit2])
	_reparent_info(0)
	list1.set_meta("Unit", unit1)
	list2.set_meta("Unit", unit2)
	call_deferred("_refresh_list")
	#_refresh_list()
	
	
func _close_trade_menu():
	firstUnit = null
	secondUnit = null
	box1.visible = false
	box2.visible = false
	_hide_sprites()
	toggle_visible()
	_clear_item_list(list1)
	_clear_item_list(list2)
	tState = tStates.DEFAULT
	emit_signal("trade_closed")
	
func open_supply_menu(unit): #HERE
	var tab = _get_first_valid_category()
	_load_names([unit])
	_load_sprites([unit])
	firstUnit = unit
	toggle_visible()
	box1.visible = true
	supplyPanel.visible = true
	
	_reparent_info(1)
	tState = tStates.SUPPLY
	list1.set_meta("Unit", unit)
	_change_tab(tab)


func _close_supply_menu():
	firstUnit = null
	box1.visible = false
	supplyPanel.visible = false
	_hide_sprites()
	toggle_visible()
	_clear_item_list(list1)
	_clear_item_list(supplyPanel)
	tState = tStates.DEFAULT
	emit_signal("trade_closed")
	
	
func open_manage_menu(unit:Unit):
	_load_names([unit])
	_load_sprites([unit])
	firstUnit = unit
	box1.visible = true
	toggle_visible()
	_reparent_info(1)
	tState = tStates.MANAGE
	list1.set_meta("Unit", unit)
	#_refresh_list()
	call_deferred("_refresh_list")


func close_manage_menu():
	firstUnit = null
	box1.visible = false
	toggle_visible()
	_clear_item_list(list1)
	tState = tStates.DEFAULT
	emit_signal("trade_closed")


#Sprite Functions
func _load_sprites(units:Array):
	var sprites = [sprite1, sprite2]
	var panels = [prtPanel1, prtPanel2]
	var i = 0
	for unit in units:
		var path = "res://sprites/character/%s/portrait_full.png" 
		var fallBack = "debug"
		var texture = load(path % [unit.unit_name])
		if !texture:
			texture = load(path % [fallBack])
		sprites[i].set_texture(texture)
		panels[i].visible = true
		i += 1


func _hide_sprites():
	var panels = [prtPanel1, prtPanel2]
	for p in panels:
		p.visible = false

func _load_names(units:Array):
	var name1 = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/TradeBox1/NamePnl1/MarginContainer/NameLb1
	var name2 = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/TradeBox2/NamePnl2/MarginContainer/NameLb2
	var names = [name1, name2]
	var i = 0
	for unit in units:
		names[i].set_text(unit.unit_name)
		names[i].add_theme_font_size_override("font_size", nFSize)
		i += 1

func get_trade_list(i) -> Node: #call only after opening trade screen
	var list
	match i:
		1: list = list1
		2: list = list2
	return list
	
func get_buttons() -> Array:
	var btns : Array = []
	var children : Array
	
	match tState:
		tStates.TRADE: children = list1.itemList.get_children() + list2.itemList.get_children()
		tStates.SUPPLY: children = list1.itemList.get_children() + list2.itemList.get_children() + supplyPanel.itemList.get_children() + supplyPanel.tabs
		tStates.MANAGE:  children = list1.itemList.get_children()
		
	
	for child in children:
		var b := child as Button
		if not b:
			btns.append(child.button)
		else:
			btns.append(child)
		
	return btns
	
func get_items(list) -> Array:
	var items = list.itemList.get_children()
	return items
	
func _fill_item_list(list):
	var isTrade = false
	if tState == tStates.TRADE:
		isTrade = true
	var items = list.fill_items(isTrade)
	for b in items:
		_connect_item(b.get_button())
	
		
func _connect_supply(items):
	for b in items:
		_connect_item(b.get_button(), true)


func _clear_item_list(list):
	list.clear_items()
	
	
func _refresh_list(useLastItem := false, resetList = list1):
	var lists := []
	var i : int
	if tState == tStates.SUPPLY: 
		_connect_supply(supplyPanel.sort_supply())
	if box1.visible: lists.append(list1)
	if box2.visible: lists.append(list2)
	if useLastItem and swapIndx:
		i = swapIndx
		swapIndx = null
	elif useLastItem and firstBtn:
		i = firstBtn.get_meta("Index")
	for l in lists:
		_clear_item_list(l)
		_fill_item_list(l)
	_assign_neighbors()
	emit_signal("item_list_filled", get_buttons(), useLastItem)
	if useLastItem:
		_find_valid_cursor_focus(resetList, i)
		firstBtn = null
	elif lastClicked:
		lastClicked.call_deferred("grab_focus")
		lastClicked = null
	
	
	
func _assign_neighbors():
	var neighbor
	var isConvoy : bool = false
	if tState == tStates.SUPPLY: 
		neighbor = supplyPanel
		isConvoy = true
	else: neighbor = list2
	var l1Empty = false
	var l2Empty = false
	var size1 = list1.itemList.get_children().size()
	var size2 = neighbor.itemList.get_children().size()
	
	if size2 == 0:
		l2Empty = true
	if size1 == 0:
		l1Empty = true
		
	if !l1Empty:
		#call_deferred("_assign_vertical_neighbors", list1)
		#call_deferred("_assign_horizontal_neighbors", l2Empty)
		_assign_vertical_neighbors(list1)
		#_assign_horizontal_neighbors(l2Empty)
	if !l2Empty:
		#call_deferred("_assign_vertical_neighbors", list2)
		#call_deferred("_assign_horizontal_neighbors", l1Empty)
		_assign_vertical_neighbors(neighbor, isConvoy)
		#_assign_horizontal_neighbors(l1Empty)
	if isConvoy:
		_assign_tab_neighbor()


func _assign_vertical_neighbors(list, isConvoy = false):
	var i = 0
	var n = 0
	var btns : Array = list.itemList.get_children()
	var size1 = btns.size()
	var iMax1 = size1 - 1
	
	if size1 <= 0:
		return
	for b in btns:
		#if size1 == 1:
			#b.button.focus_neighbor_bottom = b.button.get_path_to(b.button)
			#break
		if i - 1 < 0:
			n = iMax1
		else:
			n = i - 1
		b.button.focus_neighbor_top = b.button.get_path_to(btns[n].button)
		if i + 1 > iMax1:
			n = 0
		else:
			n = i + 1
		b.button.focus_neighbor_bottom = b.button.get_path_to(btns[n].button)
		i += 1
		#b.button.focus_neighbor_right = b.button.get_path_to(b.button)
		#b.button.focus_neighbor_left = b.button.get_path_to(b.button)
	if isConvoy:
		var goheiTab = $TradeContainer/MarginContainer/TradeScreenVBox/HBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer2/MarginContainer/tabContainer/GoheiBtn
		
		btns[0].button.focus_neighbor_top = btns[0].get_path_to(goheiTab)
	
func _assign_horizontal_neighbors(empty):
	var neighbor
	if tState == tStates.SUPPLY:
		neighbor = supplyPanel
	else: neighbor = list2
	var i := 0
	var n := 0
	var btns1 : Array = list1.itemList.get_children()
	var btns2 : Array = neighbor.itemList.get_children()
	
	
	var size2 = btns2.size()
	var iMax2 = size2 - 1
	var nList = btns2
	if empty:
		nList = btns1
	for b in btns1:
		if !empty and i > iMax2:
			n = iMax2
		else:
			n = i
		b.button.focus_neighbor_right = b.button.get_path_to(nList[n].button)
		b.button.focus_neighbor_left = b.button.get_path_to(nList[n].button)
		i += 1


func _assign_tab_neighbor():
	#var tabKeys = tabTypes.keys()
	#var supply = PlayerData.supply[tabKeys[openTab]]
	var tabs = supplyPanel.tabs
	var supplyHasItems = supplyPanel.itemList.get_children()
	var unitHasItems = list1.itemList.get_children()
	
	
	for tab in tabs:
		#var isValid = false
		if !tab.get_meta("NeedNeighbor"):
			continue
		if supplyHasItems:
			var n = supplyPanel.itemList.get_child(0)
			tab.focus_neighbor_bottom = tab.get_path_to(n.button)
		elif unitHasItems: 
			var n = list1.itemList.get_child(0)
			tab.focus_neighbor_bottom = tab.get_path_to(n.button)
		else:
			tab.focus_neighbor_bottom = tab.get_path_to(tab)


func increment_tabs(isIncrease, inc = 1): #Not yet used. tab incrementing hotkey
	var tabSize = tabTypes.size()
	var newTab = supplyPanel.openTab
	if !isIncrease:
		inc = inc - (inc * 2)
	newTab += inc
	if newTab > tabSize:
		newTab = 0
	elif newTab < 0:
		newTab = tabSize
	_change_tab(newTab)
		

func _change_tab(newTab):
	supplyPanel.openTab = newTab
	call_deferred("_refresh_list")
	#_refresh_list()
	


func _connect_tabs():
	var tabs = supplyPanel.tabs
	for t in tabs:
		t.pressed.connect(self._on_tab_pressed.bind(t))


func _connect_item(b, isSupply := false):
	
	if b.pressed.is_connected(self._item_pressed.bind(b.get_parent())):
		b.pressed.disconnect(self._item_pressed.bind(b.get_parent()))
		
	elif b.pressed.is_connected(self._supply_item_pressed.bind(b.get_parent())):
		b.pressed.disconnect(self._supply_item_pressed.bind(b.get_parent()))
		
	if isSupply: b.pressed.connect(self._supply_item_pressed.bind(b.get_parent()))
	else: b.pressed.connect(self._item_pressed.bind(b.get_parent()))
	
func _check_empty_unit_inv(unit):
	var inv = unit.inventory
	var count = inv.size()
	if count > 0:
		return false
	else:
		return true
		
func _check_full_unit_inv(unit):
	var inv = unit.inventory
	var count = inv.size()
	var maxInv = unit.max_inv
	if count < maxInv:
		return false
	else:
		return true


func _check_empty_supply():
	var supply = PlayerData.supply
	var allTabs = PlayerData.supply.keys()
	var noItems = true
	for tab in allTabs:
		var count = supply[tab].size()
		if count > 0:
			noItems = false
			break
	return noItems


#func _check_usable_inv(unit): #Old Delete
	#var inv = unit.inventory
	#
	#var noUse = true
	#for instance in inv:
		#
		#if _check_usable(instance):
			#noUse = false
			#break
	#return noUse
#
#
#func _check_usable(item:Item):
	#if iData.MANAGE:
		#return true
	#else:
		#return false


func _item_pressed(b):
	match tState:
		tStates.TRADE:
			if b.get_meta("CanTrade"):
				b.state = "Selected"
				_trade_select(b)
		tStates.SUPPLY:
			if b.get_meta("CanTrade"):
				_give_select(b)
		tStates.DEFAULT:
			pass
		tStates.MANAGE:
			_open_item_options(b)
			b.state = "Selected"
			firstBtn = b
			


func _supply_item_pressed(b):
	_take_select(b)


func _open_item_options(b) -> void:
	var list = optionsPop.list
	list_snap = list1.items
	optionsPop.deploy_pop(b)
	optionsPop.validate_buttons(b)
	tState = tStates.ITEMOP
	optionsPop.connect_signal(self)
	emit_signal("trd_focus_changed", list)


func _close_item_options():
	var useLast := false
	tState = tStates.MANAGE
	optionsPop.hide_pop()
	if list_snap == list1.items: useLast = true
	list_snap.clear()
	call_deferred("_refresh_list", useLast)
	#_refresh_list(true)
	
	
	#_item_deselected()
	#var mngMenu = $SupplyOpPnl2
	#var list = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	#mngMenu.visible = false
	##_toggle_group_filter("unitInv", true)
	#emit_signal("trd_focus_changed", list)
	#tState = tStates.DEFAULT

func _on_selection_made(selection:String, item:Item):
	PlayerData.item_used = true
	_close_item_options()
	match selection:
		"Use": _play_item_anim(item)
		#"Equip": 
		#"Unequip": 


func _play_item_anim(item) -> void:
	if tState == tStates.DEFAULT:
		return
	var itemFx = load("res://scenes/animations/item_effects/item_fx.tscn").instantiate()
	itemFx.itemfx_complete.connect(self._on_itemfx_complete)
	GameState.change_state(get_parent(), GameState.gState.ACCEPT_PROMPT)
	$CharacterArtGroup/MarginContainer/PrtPnl1/MarginContainer/UnitPrt1/ItemFxNode.add_child(itemFx)
	itemFx.play_item(item, true)


func _on_itemfx_complete():
	#GameState.change_state(get_parent(), GameState.previousState)
	GameState.change_state()


func _trade_select(b):
	var unit
	var list
	var hasSpace = false
	if b.get_meta("Unit") == firstUnit:
		unit = secondUnit
		list = get_trade_list(2)
	else:
		unit = firstUnit
		list = get_trade_list(1)
	if !firstBtn:
		hasSpace = _check_i_space(unit, list)
	if hasSpace:
		_add_empty(unit, list)
	if !firstBtn:
		firstBtn = b
		emit_signal("item_selected", b)
	else:
		swapIndx = b.get_meta("Index")
		_trade_initiated(firstBtn, b)
	
	
func _give_select(b) -> void:
	var unit :Unit = b.get_meta("Unit")
	var item :Item = b.button.get_meta("Item")
	var iType = Enums.WEAPON_CATEGORY.keys()[item.category]
	var iInd = b.get_meta("Index")
	var inv = unit.inventory
	var supplyInv = PlayerData.supply[iType]
	var wasEquipped := false
	
	
	if supplyStats.Count >= supplyStats.Max: return
	
	firstBtn = b
	
	if item == unit.get_equipped_weapon():
		wasEquipped = true
	
	if iType != tabTypes.find_key(supplyPanel.openTab):
		_change_tab(tabTypes.get(iType))
	supplyInv.append(item)
	
	inv.remove_at(iInd)
	list1.remove_child(b)

	if item.equipped == true:
		item.equipped = false
	
	if wasEquipped:
		unit.set_equipped()
		
	#if !_check_empty_unit_inv(unit):
		#_find_valid_cursor_focus(list1, iInd)
		
	#_refresh_list()
	call_deferred("_refresh_list",true)
	_refresh_count()
	
	
func _take_select(b): 
	var unit :Unit= firstUnit
	var item :Item = b.button.get_meta("Item")
	var iType = Enums.WEAPON_CATEGORY.keys()[item.category]
	var iInd = b.get_meta("Index")
	var inv = unit.inventory
	var supply = PlayerData.supply
	var supplyInv = supply[iType]
	
	firstBtn = b
	inv.append(item)
	supplyInv.remove_at(iInd)
	
	if unit.get_equipped_weapon() == unit.unarmed:
		unit.set_equipped()

	#if !_check_full_unit_inv(unit):
		#_find_valid_cursor_focus(supplyList, iInd)
		
	#_refresh_list()
	call_deferred("_refresh_list", true, supplyPanel)
	_refresh_count()


func regress_trade():
	match tState:
		tStates.DEFAULT: _close_supply_menu()
		tStates.TRADE:
			if firstBtn and is_instance_valid(firstBtn):
				_item_deselected(true)
			else:
				_close_trade_menu()
		tStates.SUPPLY: _close_supply_menu()
		tStates.MANAGE: close_manage_menu()
		tStates.ITEMOP: _close_item_options()


func _item_deselected(snap = false):
	firstBtn.state = "Default"
	_remove_empty()
	if snap:
		firstBtn.call_deferred("grab_focus")
	firstBtn = null
 

func _find_valid_cursor_focus(l, i):
	var btns = l.itemList.get_children()
	var newFocus = null
	var backup = 0
	
	while btns.size() < 1:
		match backup:
			0: btns = list1.itemList.get_children()
			1: btns = list2.itemList.get_children()
			2: btns = supplyPanel.itemList.get_children()
			3: btns = supplyPanel.tabs
			_: return
		backup += 1
	
	while newFocus == null:
		for b in btns:
			var bInd = b.get_meta("Index")
			if bInd == i:
				newFocus = btns[i]
				break
		if i-1 < 0: 
			newFocus = btns[0]
			break
		i -= 1
		
	newFocus.button.call_deferred("grab_focus")
	
	
func find_cursor_destionation(b):
	var children1 = list1.itemList.get_children()
	var children2 = list2.itemList.get_children()
	
	if children1.has(b):
		return children2[0]
		
		
	elif children2.has(b):
		return children1[0]
	
	
func _add_empty(unit, list):
	var b : ItemButton = list.add_empty(unit)
	_connect_item(b.get_button())
	_assign_neighbors()
	emit_signal("new_btn_added", b.get_button())
	#b.add_to_group("unitInv")
	
	
func _remove_empty():
	list1.remove_empty()
	list2.remove_empty()
	list1.reindex_buttons()
	list2.reindex_buttons()


func _check_i_space(unit, list):
	var iLimit = unit.max_inv
	var iCount = list.itemList.get_children().size()
	
	if iCount < iLimit:
		return true
	else:
		return false

		
func _trade_initiated(b1, b2):
	_swap_items(b1, b2)
	_item_deselected()
	


func _swap_items(b1, b2):
	var unit1 = b1.get_meta("Unit")
	var item1 = b1.button.get_meta("Item")
	var i1 = b1.get_meta("Index")
	var inv1 = unit1.inventory
	#var btns1 = list1.itemList.get_children()
	var unit2 = b2.get_meta("Unit")
	var item2 = b2.button.get_meta("Item")
	var i2 = b2.get_meta("Index")
	var inv2 = unit2.inventory
	#var home
#
	#if btns1.has(b1):
		#home = list1
	#else:
		#home = list2
	item1.equipped = false
	if item2:
		#home.add_child(b2)
		#home.move_child(b2, i1)
		item2.equipped = false
		inv1[i1] = item2
		inv2[i2] = item1
	else:
		inv2.append(item1)
		inv1.remove_at(i1)
		
	unit1.set_equipped()
	unit2.set_equipped()
	
	_flag_trade()
	_remove_empty()
	call_deferred("_refresh_list", true)


func _flag_trade():
	if !PlayerData.traded:
		PlayerData.traded = true

func _get_first_valid_category() -> int:
	var valid := tabTypes.BLADE
	var supply = PlayerData.supply
	var keys = tabTypes.keys()
	for key in keys:
		var count = supply[key].size()
		if count > 0:
			valid = tabTypes[key]
			break
	return valid


func _on_tab_pressed(b):
	var c = b.get_meta("Category")
	lastClicked = b
	_change_tab(tabTypes[c])

#func _on_use_btn_pressed():
	#var item = firstBtn.button.get_meta("Item")
	#
	#emit_signal("trd_item_used",firstUnit, item)
	#_refresh_list()
	#_close_item_manage()


#func _on_equip_btn_pressed():
	#var item = firstBtn.button.get_meta("Item")
	#var i = firstBtn.get_meta("Index")
	#var isEquipped = false
	#var unequip = false
	#
	#if firstUnit.get_equipped_weapon() != null:
		#isEquipped = true
	#if isEquipped and item == firstUnit.get_equipped_weapon():
		#unequip = true
	#if !unequip:
		#firstUnit.set_equipped(i)
		#_refresh_list()
	#else:
		#firstUnit.unequip()
	#_close_item_manage()



	
	
	
