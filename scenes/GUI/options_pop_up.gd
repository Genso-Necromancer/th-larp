extends PopUp
class_name OptionsPopUp

signal selection_made

@export var list : VBoxContainer
@export var firstFocus : Button
var item : Item
var unit : Unit
var index : int

	

func validate_buttons(b) -> bool:
	var isValid = false
	var eq = $OptionsPanel/MarginContainer/OptionsList/EquipBtn
	var use = $OptionsPanel/MarginContainer/OptionsList/UseBtn
	var unEq = $OptionsPanel/MarginContainer/OptionsList/UnequipBtn
	var isSelfHealing := false
	item = b.button.get_meta("Item")
	unit = b.get_meta("Unit")
	index = b.get_meta("Index")
	
	unEq.disabled = !item.equipped
	use.disabled = !item.use

	if item is Consumable:
		for effect in item.effects:
			if effect.type == Enums.EFFECT_TYPE.HEAL and effect.target == Enums.EFFECT_TARGET.SELF: 
				isSelfHealing = true
				break
	if isSelfHealing and unit.active_stats.CurLife >= unit.active_stats.Life: 
		use.disabled = true
	
		
	
	if item.equipped or !unit.check_valid_equip(item): 
		eq.disabled = true
	else: eq.disabled = false
	
	if !eq.disabled or !use.disabled or !unEq.disabled:
		isValid = true
	return isValid


func connect_signal(host):
	self.selection_made.connect(host._on_selection_made)

	
func _on_equip_btn_pressed():
	unit.set_equipped(item)
	emit_signal("selection_made", "Equip", item)

func _on_use_btn_pressed():
	unit.use_item(item)
	emit_signal("selection_made", "Use", item)


func _on_unequip_btn_pressed():
	unit.unequip(item)
	emit_signal("selection_made", "Unequip", item)
