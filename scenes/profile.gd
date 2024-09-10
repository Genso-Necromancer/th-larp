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

	
	focusUnit.update_combatdata()
	if focusUnit.is_in_group("Enemy"):
		$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitExp.set_text("0/100")
	elif focusUnit.is_in_group("Player"):
		$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitExp.set_text(str(unitData["Profile"]["EXP"]) + "/100")
	$M/HBoxContainer/G/NameBox/VBoxContainer/UnitName.set_text(unitData["Profile"]["UnitName"])
	$M/HBoxContainer/PortraitBox/MC/MC/UnitPrt.set_texture(unitData["Profile"]["Prt"])
	$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitLevel.set_text(str(unitData["Profile"]["Level"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitHp.set_text(str(unitStats.CLIFE) + "/" + str(unitData.Stats.LIFE))
	$M/HBoxContainer/G/StatBox/VBoxContainer/LevelBox/VStats/UnitCmp.set_text(str(unitStats.CCOMP) + "/" + str(unitData.Stats.COMP))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitStr.set_text(str(unitStats["PWR"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitMag.set_text(str(unitStats["MAG"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitEle.set_text(str(unitStats["ELEG"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitCele.set_text(str(unitStats["CELE"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitBar.set_text(str(unitStats["BAR"]))
	$M/HBoxContainer/G/StatBox/VBoxContainer/StatBox/VStats/UnitCha.set_text(str(unitStats["CHA"]))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitAcc.set_text(str(focusUnit.combatData.ACC))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitAvd.set_text(str(focusUnit.combatData.AVOID))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitDmg.set_text(str(focusUnit.combatData.Dmg))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitGrz.set_text(str(focusUnit.combatData.GRAZE) + " (" + str(focusUnit.combatData.GRZPRC)) + "%)"
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitCrit.set_text(str(focusUnit.combatData.Crit))
	$M/HBoxContainer/InventoryBox/G2/VB/MC2/MC/VB/VStats/UnitCritAvd.set_text(str(focusUnit.combatData.CRTAVD))
	
	_fill_inv(focusUnit)

func _fill_skills(unit):
	pass
		
func _fill_inv(unit):
	var invPanel = $M/HBoxContainer/InventoryBox/MC2/MC/InvGrid
	var eqpLabel = $M/HBoxContainer/InventoryBox/MC2/VB/BG/MC/Eqp
	var equipped = unit.get_equipped_weapon()
	var eqStats = UnitData.itemData[equipped.ID]
	var unitInv = unit.unitData.Inv
	var durString : String
	
	if equipped.DUR <= -1 or eqStats.MAXDUR <= -1:
		durString = str(" --")
	else:
		durString = str(" [" + str(equipped.DUR) + "/" + str(eqStats.MAXDUR)+"]")
	
	eqpLabel.set_text(str(eqStats.Name) + durString)
	eqpLabel.set_meta("data_key", eqStats)
	
	
	for item in unitInv:
		if item == equipped:
			continue
		var gStats = UnitData.itemData[item.ID]
		var l = Label.new()
		equipped.DUR = item.DUR
		eqStats.MAXDUR = gStats.MAXDUR
		if equipped.DUR <= -1 or eqStats.MAXDUR <= -1:
			durString = str(" --")
		else:
			durString = str(" [" + str(equipped.DUR) + "/" + str(eqStats.MAXDUR)+"]")
		l.set_text(str(gStats.Name) + durString)
		l.set_meta("data_key", item.ID)
		invPanel.add_child(l)

func _clear_inv():
	var inv = $M/HBoxContainer/InventoryBox/MC2/MC/InvGrid
	var children = inv.get_children()
	for child in children:
		child.queue_free()
