extends Control
signal jobs_done_trd
signal item_selected
signal item_deselected
signal new_btn_added
signal trade_closed
signal trd_focus_changed
signal convoy_opened
signal convoy_closed
signal tab_selected
signal profile_request
signal trd_item_used


@export var nFSize = 18
@export var iFSize = 14
var firstBtn : Button
var firstUnit : Unit
var secondUnit : Unit
enum tStates {
	DEFAULT,
	TRADE,
	GIVE,
	TAKE,
	USE}

var tState := tStates.DEFAULT:
	set(value):
		tState = value
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
var openTab := tabTypes.BLADE:
	set(value):
		
		if tabTypes.find_key(value) == null:
			print("Invalid Tab Enum")
			return
		_change_tab(value)
		openTab = value

func _ready():
	var parent = get_parent()
	self.jobs_done_trd.connect(parent._on_jobs_done)
	self.item_selected.connect(parent._on_item_selected)
	self.item_deselected.connect(parent._on_item_deselected)
	self.new_btn_added.connect(parent._connect_btn_to_cursor)
	self.trade_closed.connect(parent._on_trade_closed)
	self.trd_focus_changed.connect(parent._on_trd_focus_changed)
	self.tab_selected.connect(parent._on_tab_selected)
	self.profile_request.connect(parent._on_profile_request)
	self.trd_item_used.connect(parent._on_item_used)
	emit_signal("jobs_done_trd", "Trade", self)
	
func open_trade_menu(unit1, unit2):
	var box1 = $VBoxContainer/TradeBox1
	var box2 = $VBoxContainer/TradeBox2
	var list1 = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	var list2 = $VBoxContainer/TradeBox2/TradePnl2/MarginContainer/ItemList2
	var sprite1 = $VBoxContainer/TradeBox1/PrtPnl1/MarginContainer/UnitPrt1
	var sprite2 = $VBoxContainer/TradeBox2/PrtPnl2/MarginContainer/UnitPrt2
	var name1 = $VBoxContainer/TradeBox1/NamePnl1/MarginContainer/NameLb1
	var name2 = $VBoxContainer/TradeBox2/NamePnl2/MarginContainer/NameLb2
	firstUnit = unit1
	secondUnit = unit2
	self.visible = true
	box1.visible = true
	box2.visible = true
	sprite1.set_texture(unit1.unitData["Profile"]["Prt"])
	sprite2.set_texture(unit2.unitData["Profile"]["Prt"])
	name1.set_text(unit1.unitData.Profile.UnitName)
	name1.add_theme_font_size_override("font_size", nFSize)
	name2.set_text(unit2.unitData.Profile.UnitName)
	name2.add_theme_font_size_override("font_size", nFSize)
	_fill_item_list(list1, unit1)
	_fill_item_list(list2, unit2)
	_assign_neighbors(list1, list2)
	tState = tStates.TRADE
	
	
func _close_trade_menu():
	var box1 = $VBoxContainer/TradeBox1
	var box2 = $VBoxContainer/TradeBox2
	var list1 = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	var list2 = $VBoxContainer/TradeBox2/TradePnl2/MarginContainer/ItemList2
	
	box1.visible = false
	box2.visible = false
	self.visible = false
	_clear_item_list(list1)
	_clear_item_list(list2)
	tState = tStates.DEFAULT
	emit_signal("trade_closed")
	
func open_supply_menu(unit):
	var box = $VBoxContainer/TradeBox1
	var sprite = $VBoxContainer/TradeBox1/PrtPnl1/MarginContainer/UnitPrt1
	var nameLb = $VBoxContainer/TradeBox1/NamePnl1/MarginContainer/NameLb1
	var list = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	var supplyBox = $VBoxContainer/ConvoyPnl
	#var supplyList = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	firstUnit = unit
	self.visible = true
	box.visible = true
	supplyBox.visible = true
	sprite.set_texture(unit.unitData["Profile"]["Prt"])
	nameLb.set_text(unit.unitData.Profile.UnitName)
	nameLb.add_theme_font_size_override("font_size", nFSize)
	_fill_item_list(list, unit)
	_open_supply_options(unit)
	openTab = tabTypes.BLADE
	
func _close_supply_menu():
	var box = $VBoxContainer/TradeBox1
	var supplyBox = $VBoxContainer/ConvoyPnl
	_close_supply_options()
	firstUnit = null
	self.visible = false
	box.visible = false
	supplyBox.visible = false
	emit_signal("trade_closed")
	
	
func _open_supply_options(unit):
	var supplyPnl = $SupplyOpPnl
	var supplyOp = $SupplyOpPnl/MarginContainer/supplyOpList
	var storeBtn = $SupplyOpPnl/MarginContainer/supplyOpList/StoreBtn
	var retrieveBtn = $SupplyOpPnl/MarginContainer/supplyOpList/RetrieveBtn
	
	var list = get_trade_list(1)
	
	
	supplyPnl.visible = true
	_toggle_group_filter("convoyTabs", false)
	_toggle_group_filter("unitInv", false)
	_toggle_group_filter("convoyInv", false)
	storeBtn.disabled = _check_empty_unit_inv(unit)
	if _check_full_unit_inv(unit) or _check_empty_supply():
		retrieveBtn.disabled = true
	else:
		retrieveBtn.disabled = false
	
		

		
	_clear_item_list(list)
	_fill_item_list(list, unit)
	emit_signal("trd_focus_changed", supplyOp)
	
	
func _close_supply_options():
	var supplyPnl = $SupplyOpPnl
	supplyPnl.visible = false
	
func open_use_menu(unit):
	#var container = $VBoxContainer
	var box = $VBoxContainer/TradeBox1
	var sprite = $VBoxContainer/TradeBox1/PrtPnl1/MarginContainer/UnitPrt1
	var nameLb = $VBoxContainer/TradeBox1/NamePnl1/MarginContainer/NameLb1
	var list = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	firstUnit = unit
	self.visible = true
	box.visible = true
	sprite.set_texture(unit.unitData["Profile"]["Prt"])
	nameLb.set_text(unit.unitData.Profile.UnitName)
	nameLb.add_theme_font_size_override("font_size", nFSize)
	_refresh_list(false, list, firstUnit)
	_toggle_group_filter("unitInv", true)
#	emit_signal("profile_request", container)
	emit_signal("trd_focus_changed", list)
	
	
	
func _close_use_menu():
	var box = $VBoxContainer/TradeBox1
	firstUnit = null
	self.visible = false
	box.visible = false
	emit_signal("trade_closed")
	_toggle_group_filter("unitInv", false)
	tState = tStates.DEFAULT
	
func get_trade_list(i) -> Node: #call only after opening trade screen
	var list1 = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	var list2 = $VBoxContainer/TradeBox2/TradePnl2/MarginContainer/ItemList2
	var list
	match i:
		1: list = list1
		2: list = list2
	return list
	
func get_items(list) -> Array:
	var items = list.get_children()
	return items
	
func _fill_item_list(list, unit):
	var inv = unit.unitData.Inv
	var i = 0
	for item in inv:
		var itemData = UnitData.itemData[item.ID]
		var b = Button.new()
		var dur = item.DUR
		var mDur = itemData.MAXDUR
		var durString
		if dur == -1 or mDur == -1:
			durString = str(" --")
		else:
			durString = str(" [" + str(dur) + "/" + str(mDur)+"]")
		b.set_text(str(itemData.Name) + durString)
		b.add_theme_font_size_override("font_size", iFSize)
		b.set_meta("item", item)
		b.set_meta("unit", unit)
		b.set_meta("index", i)
		i += 1
		b.set_button_icon(itemData.Icon)
		b.set_expand_icon(false)
		b.set_action_mode(BaseButton.ACTION_MODE_BUTTON_PRESS)
		b.set_focus_neighbor(SIDE_LEFT, b.get_path_to(b))
		b.set_focus_neighbor(SIDE_RIGHT, b.get_path_to(b))
		list.add_child(b)
		_connect_item(b)
		b.add_to_group("unitInv")
		
func _fill_supply_list(s):
	var list = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	var tabKeys = tabTypes.keys()
	var supply = UnitData.supply[tabKeys[s]]
	var i = 0
	for item in supply:
		var itemData = UnitData.itemData[item.ID]
		var b = Button.new()
		var dur = item.DUR
		var mDur = itemData.MAXDUR
		var durString
		if dur == -1 or mDur == -1:
			durString = str(" --")
		else:
			durString = str(" [" + str(dur) + "/" + str(mDur)+"]")
		b.set_text(str(itemData.Name) + durString)
		b.add_theme_font_size_override("font_size", iFSize)
		b.set_meta("item", item)
		b.set_meta("unit", "supply")
		b.set_meta("index", i)
		b.set_button_icon(itemData.Icon)
		b.set_expand_icon(false)
		b.set_action_mode(BaseButton.ACTION_MODE_BUTTON_PRESS)
		list.add_child(b)
		_connect_item(b)
		b.add_to_group("convoyInv")
		if tState == tStates.GIVE:
			b.set_mouse_filter(Control.MOUSE_FILTER_PASS)
		
func _clear_item_list(list):
	var btns = list.get_children()
	for b in btns:
		list.remove_child(b)
		b.queue_free()
	
func _refresh_list(isSupply, list = null, unit = null):
	if isSupply:
		_sort_supply()
	else:
		_clear_item_list(list)
		_fill_item_list(list, unit)
	
func increment_tabs(isIncrease, inc = 1):
	var tabSize = tabTypes.size()
	var newTab = openTab
	if !isIncrease:
		inc = inc - (inc * 2)
	newTab += inc
	if newTab > tabSize:
		newTab = 0
	elif newTab < 0:
		newTab = tabSize
	
	openTab = newTab
		

func _change_tab(s):
	var list = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	_clear_item_list(list)
	_fill_supply_list(s)
	if tState == tStates.TAKE:
		var tabs = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer2/MarginContainer/GridContainer
		var parents = [tabs, list]
		_assign_vertical_neighbors(list, true)
		_assign_tab_neighbor()
		emit_signal("tab_selected", parents)

func _connect_item(b):
	if b.button_down.is_connected(self._item_selected.bind(b)):
		b.button_down.disconnect(self._item_selected.bind(b))
	b.button_down.connect(self._item_selected.bind(b))
	
func _check_empty_unit_inv(unit):
	var inv = unit.unitData.Inv
	var count = inv.size()
	if count > 0:
		return false
	else:
		return true
		
func _check_full_unit_inv(unit):
	var inv = unit.unitData.Inv
	var count = inv.size()
	var maxInv = unit.unitData.MaxInv
	if count < maxInv:
		return false
	else:
		return true
		
func _check_empty_supply():
	var supply = UnitData.supply
	var allTabs = UnitData.supply.keys()
	var noItems = true
	for tab in allTabs:
		var count = supply[tab].size()
		if count > 0:
			noItems = false
			break
	return noItems
	
func _check_usable_inv(unit):
	var inv = unit.unitData.Inv
	
	var noUse = true
	for instance in inv:
		
		if _check_usable(instance):
			noUse = false
			break
	return noUse
	
func _check_usable(item):
	var itemData = UnitData.itemData
	var iData = itemData[item.ID]
	if iData.USE:
		return true
	else:
		return false

func _item_selected(b):
	match tState:
		tStates.TRADE:
			_trade_select(b)
		tStates.GIVE:
			_give_select(b)
		tStates.TAKE:
			_take_select(b)
		tStates.DEFAULT:
			_open_item_manage(b)
			
func _open_item_manage(b):
	var mngMenu = $SupplyOpPnl2
	var list = $SupplyOpPnl2/MarginContainer/supplyOpList
	var eBtn = $SupplyOpPnl2/MarginContainer/supplyOpList/EquipBtn
	var uBtn = $SupplyOpPnl2/MarginContainer/supplyOpList/UseBtn
	var item = b.get_meta("item")
	var usable = false
	var equippable = false
	firstBtn = b
	mngMenu.visible = true
	equippable = firstUnit.check_valid_weapon(item)
	usable = _check_usable(item)
	if !usable:
		uBtn.disabled = true
	else:
		uBtn.disabled = false
	if !equippable:
		eBtn.disabled = true
	else:
		eBtn.disabled = false
	_toggle_group_filter("unitInv", false)
	emit_signal("trd_focus_changed", list)
	tState = tStates.USE
	
	
func _close_item_manage():
	var mngMenu = $SupplyOpPnl2
	var list = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	mngMenu.visible = false
	_toggle_group_filter("unitInv", true)
	emit_signal("trd_focus_changed", list)
	tState = tStates.DEFAULT
	
	
func _trade_select(b):
	var unit
	var list
	var hasSpace = false
	if b.get_meta("unit") == firstUnit:
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
		_trade_initiated(firstBtn, b)
	
func _give_select(b): 
	var unit = b.get_meta("unit")
	var item = b.get_meta("item")
	var iData = UnitData.itemData[item.ID]
	var iType = iData.CATEGORY
	var iInd = b.get_meta("index")
	var inv = unit.unitData.Inv
	var list = get_trade_list(1)
	
	var supply = UnitData.supply
	var supplyInv = supply[iType]
	var supplyList = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	
	if iType != tabTypes.find_key(openTab):
		openTab = tabTypes.get(iType)
	supplyInv.append(item)
	
		
	inv.remove_at(iInd)
	list.remove_child(b)
	
	var btns = list.get_children()
	
	supplyList.add_child(b)
	_reindex_buttons(btns)
	iInd = b.get_meta("index")
	_assign_vertical_neighbors(list)
	_sort_supply()
	if item == unit.get_equipped_weapon():
		unit.set_equipped()
	if _check_empty_unit_inv(unit):
		_end_store()
	else:
		_find_valid_cursor_focus(list, iInd)
	
	
func _take_select(b): 
	var unit = firstUnit
	var item = b.get_meta("item")
	var iData = UnitData.itemData[item.ID]
	var iType = iData.CATEGORY
	var iInd = b.get_meta("index")
	var inv = unit.unitData.Inv
	var list = get_trade_list(1)
	
	var supply = UnitData.supply
	var supplyInv = supply[iType]
	var supplyList = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	
#	if iType != tabTypes.find_key(openTab):
#		openTab = tabTypes.get(iType)
		
	inv.append(item)
	supplyInv.remove_at(iInd)
		
	
	supplyList.remove_child(b)
	list.add_child(b)
	
	var btns = supplyList.get_children()
	_reindex_buttons(btns)
	iInd = b.get_meta("index")
#	_assign_vertical_neighbors(list)
	_sort_supply()
	if unit.get_equipped_weapon() == null:
		unit.set_equipped()
	if btns.size() == 0: #not really functioning right yet. place holder
		increment_tabs(true)
	if _check_full_unit_inv(unit):
		_end_store()
	else:
		_find_valid_cursor_focus(supplyList, iInd)
	
	
func regress_trade():
	match tState:
		tStates.DEFAULT: _close_supply_menu()
		tStates.TRADE:
			if firstBtn:
				_item_deselected(true)
			else:
				_close_trade_menu()
		tStates.GIVE: _end_store()
		tStates.TAKE: _end_retrieve()
		tStates.USE: _close_item_manage()
		
		

func _item_deselected(snap = false):
	_remove_empty()
	emit_signal("item_deselected", firstBtn, snap)
	firstBtn = null
		
func _find_valid_cursor_focus(l, i):
	var btns = l.get_children()
	if btns.size() < 1:
		_end_store()
		return
		
	var newFocus = btns[0]
	for b in btns:
		var bInd = b.get_meta("index")
		if bInd == i:
			newFocus = btns[i]
	newFocus.grab_focus()
		
	
func find_cursor_destionation(b):
	var list1 = get_trade_list(1)
	var list2 = get_trade_list(2)
	var children1 = list1.get_children()
	var children2 = list2.get_children()
	
	if children1.has(b):
		return children2[0]
		
		
	elif children2.has(b):
		return children1[0]
		
	
	
func _add_empty(unit, list):
	var b = Button.new()
	var i = list.get_children().size()
	b.set_text(" ")
	b.add_theme_font_size_override("font_size", iFSize)
	b.set_meta("item", false)
	b.set_meta("unit", unit)
	b.set_meta("index", i)
	b.set_action_mode(BaseButton.ACTION_MODE_BUTTON_PRESS)
	list.add_child(b)
	_connect_item(b)
	_assign_neighbors(get_trade_list(1), get_trade_list(2))
	emit_signal("new_btn_added", b)
	
func _remove_empty():
	var btns1 = get_trade_list(1).get_children()
	var btns2 = get_trade_list(2).get_children()
	for b in btns1:
		if b.get_meta("item"):
			continue
		else:
			b.queue_free()
	for b in btns2:
		if b.get_meta("item"):
			continue
		else:
			b.queue_free()
	_reindex_buttons(btns1)
	_reindex_buttons(btns2)
	
func _check_i_space(unit, list):
	var iLimit = unit.unitData.MaxInv
	var iCount = list.get_children().size()
	
	if iCount < iLimit:
		return true
	else:
		return false
	
func _assign_neighbors(list1, list2):
	var l1Empty = false
	var l2Empty = false
	var size1 = list1.get_children().size()
	var size2 = list2.get_children().size()
	if size2 == 0:
		l2Empty = true
	if size1 == 0:
		l1Empty = true
	if !l1Empty:
		_assign_vertical_neighbors(list1)
		_assign_horizontal_neighbors(list1, list2, l2Empty)
	if !l2Empty:
		_assign_vertical_neighbors(list2)
		_assign_horizontal_neighbors(list2, list1, l1Empty)
		
func _assign_vertical_neighbors(list1, isConvoy = false):
	var i = 0
	var n = 0
	var btns = list1.get_children()
	var size1 = btns.size()
	var iMax1 = size1 - 1
	
	if size1 <= 0:
		return
	for b in btns:
		if i - 1 < 0:
			n = iMax1
		else:
			n = i - 1
		b.focus_neighbor_top = b.get_path_to(btns[n])
		if i + 1 > iMax1:
			n = 0
		else:
			n = i + 1
		b.focus_neighbor_bottom = b.get_path_to(btns[n])
		i += 1
		b.focus_neighbor_right = b.get_path_to(b)
		b.focus_neighbor_left = b.get_path_to(b)
	if isConvoy:
		var goheiTab = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer2/MarginContainer/GridContainer/GoheiBtn
		
		btns[0].focus_neighbor_top = btns[0].get_path_to(goheiTab)
	
func _assign_horizontal_neighbors(list1, list2, empty):
	var i = 0
	var n = 0
	var btns1 = list1.get_children()
	var btns2 = list2.get_children()
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
		b.focus_neighbor_right = b.get_path_to(nList[n])
		b.focus_neighbor_left = b.get_path_to(nList[n])
		i += 1
	
		
func _trade_initiated(b1, b2):
	_swap_items(b1, b2)
	_item_deselected()
	
		
func _reindex_buttons(btns):
	var i = 0
	for b in btns:
		b.set_meta("index", i)
		i += 1
	
	

func _swap_items(b1, b2):
	var unit1 = b1.get_meta("unit")
	var item1 = b1.get_meta("item")
	var i1 = b1.get_meta("index")
	var inv1 = unit1.unitData.Inv
	var list1 = get_trade_list(1)
	var btns1 = list1.get_children()
	var unit2 = b2.get_meta("unit")
	var item2 = b2.get_meta("item")
	var i2 = b2.get_meta("index")
	var inv2 = unit2.unitData.Inv
	var list2 = get_trade_list(2)
	#var btns2 = get_trade_list(2).get_children()
	var home
	var destination
	
	
	
	if btns1.has(b1):
		home = list1
	else:
		home = list2
	if btns1.has(b2):
		destination = list1
	else:
		destination = list2
		
	b1.set_meta("unit", unit2)
	b2.set_meta("unit", unit1)
	home.remove_child(b1)
	destination.remove_child(b2)
	destination.add_child(b1)
	destination.move_child(b1, i2)
	
	
	if item2:
		home.add_child(b2)
		home.move_child(b2, i1)
		inv1[i1] = item2.duplicate()
		inv2[i2] = item1.duplicate()
	else:
		inv2.append(item1.duplicate())
		inv1.remove_at(i1)
		
	if item1 and item1 == unit1.get_equipped_weapon():
		unit1.set_equipped()
	if item2 and item2 == unit2.get_equipped_weapon():
		unit2.set_equipped()
		
	_remove_empty()
	
	
	#print("Inv1: " + str(inv1) + "
	#Inv2: " + str(inv2))


func _sort_supply():
	var tabKeys = tabTypes.keys()
	var supply = UnitData.supply[tabKeys[openTab]]
	var list = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	supply.sort_custom(_sort_items)
	_clear_item_list(list)
	_fill_supply_list(openTab)
	
func _sort_items(a, b):
	var itemData = UnitData.itemData
	var aName = itemData[a.ID].Name
	var bName = itemData[b.ID].Name
	var aDur = a.DUR
	var bDur = b.DUR
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

func _end_store():
	tState = tStates.DEFAULT
	_open_supply_options(firstUnit)
	

	
func _end_retrieve():
	tState = tStates.DEFAULT
	_open_supply_options(firstUnit)
	
func _toggle_group_filter(group, enable = false):
	var nodes = get_tree().get_nodes_in_group(group)
	for node in nodes:
		#var mode = node.get_mouse_filter()
		if enable:
			node.set_mouse_filter(0)
		else: 
			node.set_mouse_filter(2)


func _on_store_btn_pressed():
	var list = $VBoxContainer/TradeBox1/TradePnl1/MarginContainer/ItemList1
	var btns = list.get_children()
	tState = tStates.GIVE
	_close_supply_options()
	_reindex_buttons(btns)
	_assign_vertical_neighbors(list, true)
	_toggle_group_filter("unitInv", true)
	emit_signal("trd_focus_changed", list)
	

func _on_retrieve_btn_pressed():
	tState = tStates.TAKE
	_close_supply_options()
	_toggle_group_filter("convoyTabs", true)
	_toggle_group_filter("convoyInv", true)
	openTab = tabTypes.BLADE
	


func _assign_tab_neighbor():
	var list = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer
	var tabGrid = $VBoxContainer/ConvoyPnl/VBoxContainer/PanelContainer2/MarginContainer/GridContainer
	var tabs = tabGrid.get_children()
	var hasItems = true
	
	var lKids = list.get_children()
	var lKidCount = list.get_child_count()
	if lKidCount == 0:
		hasItems = false
	for tab in tabs:
		#var isValid = false
		if !tab.get_meta("NeedNeighbor"):
			continue
		if hasItems:
			tab.focus_neighbor_bottom = tab.get_path_to(lKids[0])
		else:
			tab.focus_neighbor_bottom = tab.get_path_to(tab)
			
func _on_blade_btn_pressed():
	openTab = tabTypes.BLADE


func _on_blunt_btn_pressed():
	openTab = tabTypes.BLUNT


func _on_pole_btn_pressed():
	openTab = tabTypes.STICK


func _on_bow_btn_pressed():
	openTab = tabTypes.BOW


func _on_gun_btn_pressed():
	openTab = tabTypes.GUN


func _on_gohei_btn_pressed():
	openTab = tabTypes.GOHEI


func _on_book_btn_pressed():
	openTab = tabTypes.BOOK


func _on_fan_btn_pressed():
	openTab = tabTypes.FAN


func _on_acc_btn_pressed():
	openTab = tabTypes.ACC


func _on_item_btn_pressed():
	openTab = tabTypes.ITEM

func _on_use_btn_pressed():
	var item = firstBtn.get_meta("item")
	var list = get_trade_list(1)
	emit_signal("trd_item_used",firstUnit, item)
	_refresh_list(false, list, firstUnit)
	_close_item_manage()

func _on_equip_btn_pressed():
	var item = firstBtn.get_meta("item")
	var i = firstBtn.get_meta("index")
	var isEquipped = false
	var unequip = false
	var list = get_trade_list(1)
	if firstUnit.get_equipped_weapon() != null:
		isEquipped = true
	if isEquipped and item == firstUnit.get_equipped_weapon():
		unequip = true
	if !unequip:
		firstUnit.set_equipped(i)
		_refresh_list(false, list, firstUnit)
	else:
		firstUnit.unequip()
	_close_item_manage()
