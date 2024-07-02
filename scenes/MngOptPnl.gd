extends PanelContainer
#var tradeLb
#var supplyLb
#var equipLb
#var useLb

func get_buttons():
	var vb = $M/VBMng
	var btns = vb.get_children()
	return btns
#	tradeLb = $M/VBMng/tradeLb
#	supplyLb = $M/VBMng/supplyLb
#	equipLb = $M/VBMng/equipLb
#	useLb = $M/VBMng/useLb
func get_menu():
	var vb = $M/VBMng
	return vb
