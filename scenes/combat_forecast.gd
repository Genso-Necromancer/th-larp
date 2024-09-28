extends Control


func show_fc() -> void:
	self.visible = true
	
func hide_fc() -> void:
	self.visible = false
	_close_effects()
	
func update_fc(cmbData) -> void: #HERE labels need updating to using StringGetter AND "unarmed" doesn't appear correct
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
		var active : Dictionary = units[i].activeStats
		var cStats : Dictionary = cmbData[units[i]].Combat
		var lifeTemplate : String = StringGetter.get_template("combat_hp")
		var remainTemplate : String = StringGetter.get_template("combat_hp_remain")
		var lifeText : String = "[center]%s[/center]"
		var hp = lifeTemplate % [active.CurLife, units[i].baseStats.Life]
		
		if !cStats.TrueHit and cmbData[units[i]].Counter and cmbData[units[i]].Reach: hit = str(cStats.Hit)
		elif cStats.TrueHit and cmbData[units[i]].Counter and cmbData[units[i]].Reach: hit = "TRUE" 
		
		if !cStats.Dmg and cStats.Dmg != 0: pass
		elif cmbData[units[i]].Counter and cmbData[units[i]].Reach: dmg = str(cStats.Dmg)
		
		if !cStats.Crit and cStats.Crit != 0: pass
		elif cmbData[units[i]].Counter and cmbData[units[i]].Reach: crit = str(cStats.Crit)
		
		if cStats.has("Rlife") and active.CurLife != cStats.Rlife:
			lifeText = lifeText % [remainTemplate]
			lifeText = lifeText % [cStats.Rlife, hp]
		else: lifeText = lifeText % [hp]
		
		sprites[i].set_texture(units[i].unitData.Profile.Prt)
		groups[g][0].set_text(units[i].unitName)
		groups[g][1].set_text(lifeText)
		groups[g][2].set_text(hit)
		groups[g][3].set_text(dmg)
		groups[g][4].set_text(crit)
		#HERE check for swing count for visual representation
		i += 1
	if cmbData[units[0]].Effects or cmbData[units[1]].Effects:
		_load_effects(cmbData)
	
func _load_effects(cmbData) -> void:
	var units : Array = cmbData.keys()
	var lists : Dictionary = {units[0]:$GC/HBC/AtkEfPanel/AMa/AVB, units[1]:$GC/HBC/TargetEfPanel/TMa/TVB}
	var panels : Array = [$GC/HBC/AtkEfPanel, $GC/HBC/Labels2, $GC/HBC/TargetEfPanel]
	
	for p in panels:
		p.visible = true
	for unit in units:
		_clear_old(lists[unit])
		var strings : Array = []
		var selfEff : Array = []
		var targEff : Array = []
		var globEff : Array = []
		if !cmbData[unit].Effects:
			var string : String = "[center]%s[/center]" % [StringGetter.get_string("void_value")]
			strings.append(string)
			continue
		#var keys : Array = cmbData[unit].Effects.keys()
		for effId in cmbData[unit].Effects:
			var string : String = "[center]%s[/center]" % StringGetter.get_combat_effect_string(effId, cmbData[unit])
			match UnitData.effectData[effId].Target:
				Enums.EFFECT_TARGET.SELF: selfEff.append(string)
				Enums.EFFECT_TARGET.TARGET: targEff.append(string)
				Enums.EFFECT_TARGET.GLOBAL: globEff.append(string)
		
		if globEff.size() > 0:
			_add_effect_labels(lists[unit], globEff)
			
		if targEff.size() > 0:
			_add_effect_labels(lists[unit], targEff)
			
		if selfEff.size() > 0:
			var lbl = RichTextLabel.new()
			var selfString = "[center]%s[/center]" % StringGetter.get_string("effect_target_self")
			Global.set_rich_text_params(lbl)
			lbl.set_text(selfString)
			lists[unit].add_child(lbl)
			_add_effect_labels(lists[unit], selfEff)


func _clear_old(list):
	var old = list.get_children()
	for l in old:
		l.queue_free()

		
func _add_effect_labels(lists, strings):
	for string in strings:
		var lbl = RichTextLabel.new()
		Global.set_rich_text_params(lbl)
		lbl.set_text(string)
		lists.add_child(lbl)

func _close_effects() -> void:
	var lists : Array = [$GC/HBC/TargetEfPanel/TMa/TVB, $GC/HBC/AtkEfPanel/AMa/AVB]
	var panels : Array = [$GC/HBC/AtkEfPanel, $GC/HBC/Labels2, $GC/HBC/TargetEfPanel]
	for l in lists:
		for child in l.get_children():
				child.queue_free()
	for p in panels:
		p.visible = false
	



func _on_gameboard_cmbData_updated(cmbData) -> void:
	update_fc(cmbData)
