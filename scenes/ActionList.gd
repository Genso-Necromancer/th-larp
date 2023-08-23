extends ItemList

var itemInd = 0

func _process(_delta):
	for i in range(0,get_item_count()):
		set_item_tooltip_enabled(i,false)


