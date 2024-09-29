extends MarginContainer
signal jobs_done_prf

func _ready():
	var parent = get_parent()
	self.jobs_done_prf.connect(parent._on_jobs_done)
	parent.profile_called.connect(self._on_update_prof)
	emit_signal("jobs_done_prf", "Profile", self)

func _on_update_prof():
	var focusUnit = Global.focusUnit
	var valid = false
	_clear_inv()
	if focusUnit:
		valid = true
	if !valid:
		return
	
	var unitData = focusUnit.unitData
	var unitStats = focusUnit.activeStats
	var unitBuffs = focusUnit.activeBuffs

	
	focusUnit.update_stats()
	if focusUnit.is_in_group("Enemy"):
		$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitExp.set_text("0/100")
	elif focusUnit.is_in_group("Player"):
		$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitExp.set_text(str(unitData["Profile"]["EXP"]) + "/100")
	$M/HBoxContainer/G/NameBox/VBoxContainer/UnitName.set_text("[center]%s[/center]" % [focusUnit.unitName])
	$M/HBoxContainer/PortraitBox/MC/MC/UnitPrt.set_texture(unitData["Profile"]["Prt"])
	$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitLevel.set_text(str(unitData["Profile"]["Level"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitHp.set_text(str(unitStats.CurLife) + "/" + str(unitData.Stats.Life))
	$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitCmp.set_text(str(unitStats.CurComp) + "/" + str(unitData.Stats.Comp))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitStr.set_text(str(unitStats["Pwr"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitMag.set_text(str(unitStats["Mag"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitEle.set_text(str(unitStats["Eleg"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitCele.set_text(str(unitStats["Cele"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitBar.set_text(str(unitStats["Bar"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitCha.set_text(str(unitStats["Cha"]))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitAcc.set_text(str(focusUnit.combatData.Hit))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitAvd.set_text(str(focusUnit.combatData.Avoid))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitDmg.set_text(str(focusUnit.combatData.Dmg))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitGrz.set_text(str(focusUnit.combatData.Graze) + " (" + str(focusUnit.combatData.GrzPrc) + "%)")
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitCrit.set_text(str(focusUnit.combatData.Crit))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitCritAvd.set_text(str(focusUnit.combatData.CrtAvd))
	
	_fill_inv(focusUnit)

func _fill_skills(unit):
	pass
		
func _fill_inv(unit):
	unit.update_stats()
	var invPanel = $M/HBoxContainer/InventoryBox/MC2/MC/InvGrid
	var eqpLabel = $M/HBoxContainer/InventoryBox/MC2/VB/BG/MC/Eqp
	var equipped = unit.get_equipped_weapon()
	var id = equipped.ID
	var dur = equipped.DUR
	var maxDur = UnitData.itemData[id].MaxDur
	var iName = UnitData.itemData[id].Name
	var unitInv = unit.unitData.Inv
	var durString : String
	var subProf = unit.unitData.Weapons.Sub
	
	if dur <= -1 or maxDur <= -1:
		durString = str(" --")
	else:
		durString = str(" [" + str(dur) + "/" + str(maxDur)+"]")
	
	eqpLabel.set_text(str(iName) + durString)
	eqpLabel.set_meta("data_key", id)
	
	if subProf and subProf.has("NATURAL") and id != unit.natural.ID:
		var item = unit.natural
		id = item.ID
		var iStats = UnitData.itemData[id]
		var l = Label.new()
		
		dur = item.DUR
		maxDur = iStats.MaxDur
		iName = iStats.Name
		durString = str(" --")
		_add_item_label(invPanel,l,iName,durString,id)
	
	for item in unitInv:
		if item.Equip:
			continue
		var iStats = UnitData.itemData[item.ID]
		var l = Label.new()
		dur = item.DUR
		maxDur = iStats.MaxDur
		iName = iStats.Name
		
		if dur <= -1 or maxDur <= -1:
			durString = str(" --")
		else:
			durString = str(" [" + str(dur) + "/" + str(maxDur)+"]")
		_add_item_label(invPanel,l,iName,durString,id)

func _add_item_label(panel, label, iName, durString, id):
	label.set_text(str(iName) + durString)
	label.set_meta("data_key", id)
	panel.add_child(label)

func _clear_inv():
	var inv = $M/HBoxContainer/InventoryBox/MC2/MC/InvGrid
	var children = inv.get_children()
	for child in children:
		child.queue_free()
