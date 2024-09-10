extends Control


func show_fc():
	self.visible = true
	
func hide_fc():
	self.visible = false
	
func update_fc(cmbData): #Not full functioning. Just placeholder. Add GRAZE and an effect loading function
	var groups : Dictionary = {}
	var units : Array = cmbData.keys()
	var i := 0
	
	var sprites: Array = []
	
	sprites.append($GC/BGA1/MC/AtkFull)
	sprites.append($GC/BGA2/MC/TrgtFull)
	groups["LEFT"] = $GC/HBC/AtkPanel/AMa/AVB.get_children()
	groups["RIGHT"] = $GC/HBC/TargetPanel/TMa/TVB.get_children()
	
	for g in groups:
		var hit := "--"
		var dmg := "--"
		var crit := "--"
		var remaining : String = ""
		var active : Dictionary = units[i].activeStats
		var cStats : Dictionary = cmbData[units[i]].combat
		if cStats.ACC and cmbData[units[i]].counter and cmbData[units[i]].reach: hit = str(cStats.ACC)
		elif !cStats.ACC and cmbData[units[i]].counter and cmbData[units[i]].reach: hit = "TRUE" 
		if cStats.Dmg and cmbData[units[i]].counter and cmbData[units[i]].reach: dmg = str(cStats.Dmg)
		if cStats.Crit and cmbData[units[i]].counter and cmbData[units[i]].reach: crit = str(cStats.Crit)
		
		#if cStats.Dmg and (units[i].baseStats.LIFE - cStats.Dmg) != active.CLIFE: #ITS FUCKING WRONG FIX IT. YOU CANOT FUCKING GET THE DAMAGE LIKE THIS IT ONLY HAS ACCESS TO THE FUCKING SELF STATS, YOU JUST REMOVED ITS OWN DAMAGE FROM ITS HEALTH JUST LIKE LAST TIME IN A DIFFERENT FUNCTION YOU ABSOLUTE FUCKING BAFOON. HERE
			#var rLife : int = units[i].baseStats.LIFE - cStats.Dmg
			#remaining = " [[color=#FF2400]%d[/color] ]" % [rLife]
		var lifeText : String = "[center]%s%d/%d[/center]" % [remaining, active.CLIFE, units[i].baseStats.LIFE]
		sprites[i].set_texture(units[i].unitData.Profile.Prt)
		groups[g][0].set_text(units[i].unitName)
		groups[g][1].set_text(lifeText)

		groups[g][2].set_text(hit)
		groups[g][3].set_text(dmg)
		groups[g][4].set_text(crit)
		i += 1
	
func _load_effects(cmbData):
	var l : Control = $GC/HBC/AtkEfPanel
	var c : Control = $GC/HBC/Labels2
	var r : Control = $GC/HBC/TargetEfPanel
	var all : Array = [l,c,r]
	var eff = UnitData.effectData
	#HERE Unfinished, awaiting effects overhaul
	
func _get_effect_string(effectType): #Time to create the string XML and string getter, eh?
	
	
	
	match effectType:
		Enums.EFFECT_TYPE.ADD_PASSIVE: pass
		Enums.EFFECT_TYPE.ADD_SKILL: pass
		Enums.EFFECT_TYPE.BUFF: pass
		Enums.EFFECT_TYPE.CURE: pass
		Enums.EFFECT_TYPE.DAMAGE: pass
		Enums.EFFECT_TYPE.DASH: pass
		Enums.EFFECT_TYPE.DEBUFF: pass
		Enums.EFFECT_TYPE.HEAL: pass
		Enums.EFFECT_TYPE.SHOVE: pass
		Enums.EFFECT_TYPE.STATUS: pass
		Enums.EFFECT_TYPE.TIME: pass
		Enums.EFFECT_TYPE.TOSS: pass
		Enums.EFFECT_TYPE.WARP: pass
	
func _on_gameboard_cmbData_updated(cmbData):
	update_fc(cmbData)
