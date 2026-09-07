extends PopUp
class_name OptionsPopUp

signal selection_made

@export var list : VBoxContainer
@export var firstFocus : Button
var item : Item
var unit : Unit
var index : int
var drop_only := false

	

func validate_buttons(b, force_drop_only := false) -> bool:
	var isValid = false
	var eq = $OptionsPanel/MarginContainer/OptionsList/EquipBtn
	var use = $OptionsPanel/MarginContainer/OptionsList/UseBtn
	var unEq = $OptionsPanel/MarginContainer/OptionsList/UnequipBtn
	var drop = $OptionsPanel/MarginContainer/OptionsList/DropBtn
	var isSelfHealing := false
	drop_only = force_drop_only
	item = b.button.get_meta("Item")
	unit = b.get_meta("Unit")
	index = b.get_meta("Index")

	eq.visible = !drop_only
	use.visible = !drop_only
	unEq.visible = !drop_only
	drop.visible = drop_only
	firstFocus = drop if drop_only else eq

	if drop_only:
		drop.focus_neighbor_top = drop.get_path_to(drop)
		drop.focus_neighbor_bottom = drop.get_path_to(drop)
		drop.disabled = false
		drop.call_deferred("grab_focus")
		return true
	eq.focus_neighbor_top = eq.get_path_to(use)
	use.focus_neighbor_bottom = use.get_path_to(eq)
	
	unEq.disabled = !item.equipped
	use.disabled = !item.use

	if item is Consumable:
		for effect in item.effects:
			if effect.type == Enums.EFFECT_TYPE.HEAL and effect.target == Enums.EFFECT_TARGET.SELF: 
				isSelfHealing = true
				break
	if isSelfHealing and unit.current_life >= unit.active_stats.Life: 
		use.disabled = true
	
		
	
	if item.equipped or !unit.check_valid_equip(item): 
		eq.disabled = true
	else: eq.disabled = false
	
	if !eq.disabled or !use.disabled or !unEq.disabled:
		isValid = true
	return isValid


func connect_signal(host):
	var callback := Callable(host, "_on_selection_made")
	if not self.selection_made.is_connected(callback):
		self.selection_made.connect(callback)

	
func _on_equip_btn_pressed():
	unit.set_equipped(item)
	emit_signal("selection_made", "Equip", item)

func _on_use_btn_pressed():
	unit.use_item(item)
	emit_signal("selection_made", "Use", item)


func _on_unequip_btn_pressed():
	unit.unequip(item)
	emit_signal("selection_made", "Unequip", item)


func _on_drop_btn_pressed():
	emit_signal("selection_made", "Drop", item)
