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
	var i = 0
	var invPanel = $M/G/VB/MC2/MC/VB
	var expLbl = $M/G/UnitExp
	var eqpLabel = $M/G/VB/MC2/VB/BG/MC/Eqp
	var itemData = UnitData.itemData
	
	
	var unitInv 
	var combatData
	var equipped
	var eqData 
	
	var unitData = focusUnit.unitData
	var unitStats = focusUnit.activeStats
	var unitBuffs = focusUnit.activeBuffs
	if focusUnit.is_in_group("Enemy"):
		expLbl.set_text("0")
	elif focusUnit.is_in_group("Player"):
		expLbl.set_text(str(unitData["Profile"]["EXP"]))
	focusUnit.update_combatdata()
	combatData = focusUnit.combatData
	$M/G/UnitName.set_text(unitData["Profile"]["UnitName"])
	$M/G/VB/MC/MC/UnitPrt.set_texture(unitData["Profile"]["Prt"])
	$M/G/VStats/UnitLevel.set_text(str(unitData["Profile"]["Level"]))
	$M/G/VStats/UnitHp.set_text(str(unitStats["CLIFE"]) + "/" + str(unitStats["LIFE"]))
	$M/G/VStats/UnitStr.set_text(str(unitStats["PWR"]))
	$M/G/VStats/UnitMag.set_text(str(unitStats["MAG"]))
	$M/G/VStats/UnitEle.set_text(str(unitStats["ELEG"]))
	$M/G/VStats/UnitCele.set_text(str(unitStats["CELE"]))
	$M/G/VStats/UnitBar.set_text(str(unitStats["BAR"]))
	$M/G/VStats/UnitCha.set_text(str(unitStats["CHA"]))
	$M/G/VB/G2/VB/MC2/MC/VB/VStats/UnitAcc.set_text(str(combatData.ACC))
	$M/G/VB/G2/VB/MC2/MC/VB/VStats/UnitAvd.set_text(str(combatData.AVOID))
	$M/G/VB/G2/VB/MC2/MC/VB/VStats/UnitDmg.set_text(str(combatData.DMG))
	$M/G/VB/G2/VB/MC2/MC/VB/VStats/UnitGrz.set_text(str(combatData.GRAZE) + " %" + str(combatData.GRZPRC))
	$M/G/VB/G2/VB/MC2/MC/VB/VStats/UnitCrit.set_text(str(combatData.CRIT))
	$M/G/VB/G2/VB/MC2/MC/VB/VStats/UnitCritAvd.set_text(str(combatData.CRTAVD))
	unitInv = unitData.Inv
	if unitData.EQUIP:
		equipped = unitData.Inv[0]
		eqData = itemData[equipped.Data]
		eqpLabel.set_text(str(eqData.NAME) + " [" + str(equipped.DUR) + "/" + str(eqData.MAXDUR)+"]")
		eqpLabel.set_meta("data_key", eqData)
	else:
		eqData = itemData["NONE"]
		eqpLabel.set_text(str(eqData.NAME))
		eqpLabel.set_meta("data_key", "NONE")
	
	
	for item in unitInv:
		if item == equipped:
			continue
		var iData = itemData[item.Data]
		var l = Label.new()
		l.set_text(str(iData.NAME) + " [" + str(item.DUR) + "/" + str(iData.MAXDUR)+"]")
		l.set_meta("data_key", item.Data)
		invPanel.add_child(l)
		

func _clear_inv():
	var inv = $M/G/VB/MC2/MC/VB
	var children = inv.get_children()
	for child in children:
		child.queue_free()
