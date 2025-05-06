extends VBoxContainer
class_name OfudaBox



func fill_ofuda(unit:Unit) -> Array:
	var iPath = load("res://scenes/GUI/item_button.tscn")
	var i : ItemButton
	var buttons := []
	#var buttons : Array = []
	for item in unit.inventory:
		if item is not Ofuda: continue
		i = generate_ofudabutton(iPath, item)
		buttons.append(i.get_button())
		i.get_button().add_to_group("ItemTT")
		i.set_meta_data(item, unit, false)
		if !_check_composure(unit, item): i.state = "Disabled"
		add_child(i)
	buttons[0].call_deferred("grab_focus")
	return buttons


func generate_ofudabutton(path, data) -> ItemButton:
	var b : ItemButton
	var iconPath : String = "res://sprites/icons/items/ofuda/%s.png" % [data.id]
	b = path.instantiate()
	b.isIconMode = false
	b.set_item_text(data)
	b.set_item_icon(iconPath)
	#_connect_focus_signals(b)
	return b


func _check_composure(unit : Unit, ofuda : Ofuda) -> bool:
	var valid : bool = unit.has_enough_comp(ofuda.cost)
	return valid
