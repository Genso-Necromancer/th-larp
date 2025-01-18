extends Control

var animationsLoaded = false

func show_fc() -> void:
	self.visible = true
	
func hide_fc() -> void:
	var effectPanels = [$ForecastBox/EffectRow/AtkEfPanel, $ForecastBox/EffectRow/Labels2, $ForecastBox/EffectRow/TargetEfPanel]
	self.visible = false
	for p in effectPanels:
		p.visible = false
	_close_effects()
	if animationsLoaded: _free_animations()
	
func update_fc(foreCast) -> void: #HERE labels need updating to using StringGetter AND "unarmed" doesn't appear correct
	var groups : Dictionary = {}
	var units : Array = foreCast.keys()
	var i := 0
	#var sprites: Array = []
	var atkPanel = $ForecastBox/StatRow/AtkPanel/AMa/AVB
	var trgtPanel = $ForecastBox/StatRow/TargetPanel/TMa/TVB
	
	
	_call_animations(units)
		
	#sprites.append($GC/BGA1/MC/AtkFull)
	#sprites.append($GC/BGA2/MC/TrgtFull)
	groups[atkPanel] = atkPanel.get_children()
	groups[trgtPanel] = trgtPanel.get_children()
	
	
	
	for g in groups:
		if i >= units.size():
			g.visible = false
			break
		else: g.visible = true
		var hit := "--"
		var dmg := "--"
		var crit := "--"
		var active : Dictionary = units[i].activeStats
		var fcCombat : Dictionary = foreCast[units[i]].Combat
		var fcCounter = foreCast[units[i]].Counter
		var fcReach = foreCast[units[i]].Reach
		var fcSwings = foreCast[units[i]].Swings
		var lifeTemplate : String = StringGetter.get_template("combat_hp")
		var remainTemplate : String = StringGetter.get_template("combat_hp_remain")
		var lifeText : String = "[center]%s[/center]"
		var hp = lifeTemplate % [active.CurLife, units[i].baseStats.Life]
		
		
		if !fcCombat.CanMiss and fcCounter and fcReach: hit = "TRUE" 
		elif fcCombat.CanMiss and fcCounter and fcReach: hit = str(fcCombat.Hit)
		
		if fcCombat.CanDmg and fcCounter and fcReach: dmg = str(fcCombat.Dmg)
		
		if fcCombat.CanCrit and fcCounter and fcReach:  crit = str(fcCombat.Crit)
		
		if fcSwings and fcCounter and fcReach and fcSwings > 1: dmg = dmg + " x" + str(fcSwings)
		
		
		if fcCombat.has("Rlife") and active.CurLife != fcCombat.Rlife:
			lifeText = lifeText % [remainTemplate]
			lifeText = lifeText % [fcCombat.Rlife, hp]
		else: lifeText = lifeText % [hp]
		
		#sprites[i].set_texture(units[i].unitData.Profile.Prt)
		groups[g][0].set_text(units[i].unitName)
		groups[g][1].set_text(lifeText)
		groups[g][2].set_text(hit)
		groups[g][3].set_text(dmg)
		groups[g][4].set_text(crit)
		#HERE check for swing count for visual representation
		i += 1
	if foreCast[units[0]].Effects or foreCast[units[(i-1)]].Effects:
		_load_effects(foreCast)
	
func _load_effects(cmbData) -> void:
	var units : Array = cmbData.keys()
	var lists : Dictionary
	var panels : Array 
	
	if units.size() < 2: 
		lists = {units[0]:$ForecastBox/EffectRow/AtkEfPanel/AMa/AVB}
		panels = [$ForecastBox/EffectRow/AtkEfPanel, $ForecastBox/EffectRow/Labels2]
	else: 
		lists = {units[0]:$ForecastBox/EffectRow/AtkEfPanel/AMa/AVB, units[1]:$ForecastBox/EffectRow/TargetEfPanel/TMa/TVB}
		panels = [$ForecastBox/EffectRow/AtkEfPanel, $ForecastBox/EffectRow/Labels2, $ForecastBox/EffectRow/TargetEfPanel]
		
		
	
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
	var lists : Array = [$ForecastBox/EffectRow/TargetEfPanel/TMa/TVB, $ForecastBox/EffectRow/AtkEfPanel/AMa/AVB]
	var panels : Array = [$ForecastBox/EffectRow/AtkEfPanel, $ForecastBox/EffectRow/Labels2, $ForecastBox/EffectRow/TargetEfPanel]
	for l in lists:
		for child in l.get_children():
				child.queue_free()
	for p in panels:
		p.visible = false
	

func _call_animations(units):
	var animHandler = $AnimationHandler
	if !animationsLoaded:
		animHandler.load_animations(units)
		animationsLoaded = true
	return

func _free_animations():
	var animHandler = $AnimationHandler
	animHandler._clear_sequence()
	animationsLoaded = false

func _on_animation_handler_sequence_complete():
	animationsLoaded = false
