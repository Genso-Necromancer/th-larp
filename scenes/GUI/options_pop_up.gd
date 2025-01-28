extends PopUp
class_name OptionsPopUp

signal selection_made

@export var list : VBoxContainer
@export var firstFocus : Button
var item : Dictionary
var unit : Unit
var index : int

func validate_buttons(b) -> bool:
	var isValid = false
	var eq = $OptionsPanel/MarginContainer/OptionsList/EquipBtn
	var use = $OptionsPanel/MarginContainer/OptionsList/UseBtn
	var unEq = $OptionsPanel/MarginContainer/OptionsList/UnequipBtn
	item = b.button.get_meta("Item")
	unit = b.get_meta("Unit")
	index = b.get_meta("Index")
	var itemData = UnitData.itemData[item.ID]
	
	unEq.disabled = !item.Equip
	
	if item.Equip or !unit.check_valid_equip(item): 
		eq.disabled = true
	else: eq.disabled = false
	
	if itemData.MinRange == 0 and itemData.MaxRange == 0 and itemData.Use:
		use.disabled = !itemData.Use
	
	if !eq.disabled or !use.disabled or !unEq.disabled:
		isValid = true
	
	return isValid
	

func connect_signal(host):
	self.selection_made.connect(host._on_selection_made)

	
func _on_equip_btn_pressed():
	unit.set_equipped(index)
	emit_signal("selection_made", "Equip", item)

func _on_use_btn_pressed():
	unit.use_item(item)
	emit_signal("selection_made", "Use", item)


func _on_unequip_btn_pressed():
	unit.unequip(index)
	emit_signal("selection_made", "Unequip", item)
