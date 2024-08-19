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
	var equipped = focusUnit.get_equipped_weapon()
	var combatData
	var eqStats = itemData[equipped.DATA]
	var unitData = focusUnit.unitData
	var unitStats = focusUnit.activeStats
	var unitBuffs = focusUnit.activeBuffs
	var unitInv = unitData.Inv
	var dur : int = equipped.DUR
	var mDur : int = eqStats.MAXDUR
	var durString : String
	
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
	
	if dur <= -1 or mDur <= -1:
		durString = str(" --")
	else:
		durString = str(" [" + str(dur) + "/" + str(mDur)+"]")
	
	eqpLabel.set_text(str(eqStats.NAME) + durString)
	eqpLabel.set_meta("data_key", eqStats)
	
	for item in unitInv:
		if item == equipped:
			continue
		var gStats = itemData[item.DATA]
		var l = Label.new()
		dur = item.DUR
		mDur = gStats.MAXDUR
		if dur <= -1 or mDur <= -1:
			durString = str(" --")
		else:
			durString = str(" [" + str(dur) + "/" + str(mDur)+"]")
		l.set_text(str(gStats.NAME) + durString)
		l.set_meta("data_key", item.DATA)
		invPanel.add_child(l)
		

func _clear_inv():
	var inv = $M/G/VB/MC2/MC/VB
	var children = inv.get_children()
	for child in children:
		child.queue_free()
