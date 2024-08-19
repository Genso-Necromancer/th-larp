extends Control


func show_fc():
	self.visible = true
	
func hide_fc():
	self.visible = false
	
func update_fc(cmbData): #Not full functioning. Just placeholder.
	var AName = $GC/HBC/AtkPanel/AMa/AVB/NAME
	var ALife = $GC/HBC/AtkPanel/AMa/AVB/LIFE
	var AAcc = $GC/HBC/AtkPanel/AMa/AVB/ACC
	var ADmg = $GC/HBC/AtkPanel/AMa/AVB/DMG
	var ACrit = $GC/HBC/AtkPanel/AMa/AVB/CRIT
	var ADef = $GC/HBC/AtkPanel/AMa/AVB/DEF
	var APrt = $GC/BGA1/MC/AtkFull
	var TPrt = $GC/BGA2/MC/TrgtFull
	var TName = $GC/HBC/TargetPanel/TMa/TVB/NAME
	var TLife = $GC/HBC/TargetPanel/TMa/TVB/LIFE
	var TAcc = $GC/HBC/TargetPanel/TMa/TVB/ACC
	var TDmg = $GC/HBC/TargetPanel/TMa/TVB/DMG
	var TCrit = $GC/HBC/TargetPanel/TMa/TVB/CRIT
	var TDef = $GC/HBC/TargetPanel/TMa/TVB/DEF
	var keys = cmbData.keys()
	var a = keys[0]
	var t = keys[1]
	var active = cmbData[a]
	var target = cmbData[t]
	AName.set_text(t.unitName)
	APrt.set_texture(t.unitData.Profile.Prt)
	ALife.set_text("%d/%d [[color=#FF2400]%d[/color]]" % [a.activeStats.CLIFE, a.baseStats.LIFE, active.RLIFE])
	AAcc.set_text(str(active.ACC))
	ADmg.set_text(str(active.DMG))
	ACrit.set_text(str(active.CRIT))
#		ADef.set_text(str(active.DEF))
	TName.set_text(t.unitName)
	TPrt.set_texture(t.unitData.Profile.Prt)
	TLife.set_text("%d/%d [[color=#FF2400]%d[/color]]" % [t.activeStats.CLIFE, t.baseStats.LIFE, target.RLIFE])
	TAcc.set_text(str(target.ACC))
	TDmg.set_text(str(target.DMG))
	TCrit.set_text(str(target.CRIT))


func _on_gameboard_cmb_data_updated(cmbData):
	update_fc(cmbData)
