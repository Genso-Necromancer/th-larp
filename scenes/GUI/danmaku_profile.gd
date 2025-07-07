extends UnitProfile

class_name DanmakuProfile


func update_prof():
	var focusDmk = Global.focusDanmaku
	#var dmkData : Dictionary
	
	if !focusDmk: return
	#focusDmk.update_stats()
	#dmkData = focusDmk.dmkData
	focusLabels.clear()
	_clear_skills()
	focusLabels = get_tree().get_nodes_in_group("ToolTipLabels")
	get_tree().call_group("ProfileLabels", "set_meta","Unit", focusDmk)
	
	if statusTray:
		statusTray.update(focusDmk)
		statusTray.connect_icons(self)
		focusLabels.append_array(statusTray.get_icons())
	
	#var unitStats = focusDmk.active_stats
	#var unitBuffs = focusDmk.active_buffs
	
	if inventory: focusLabels += _update_inventory(focusDmk)
	if fBox: focusLabels += _update_features(focusDmk)
	if !isPreview: portrait.set_texture(focusDmk.texture)
	elif isPreview and portrait: portrait.set_texture(focusDmk.texture)
	get_tree().call_group("ProfileLabels", "you_need_to_update_yourself_NOW", focusDmk)
