extends PanelContainer

class_name CombatForecast

var animationsLoaded = false



func _ready():
	self.visible = false
	$ForecastMargin/ForecastBox/EffectRow.visible = false
	SignalTower.forecast_predicted.connect(self.update_fc)
	SignalTower.sequence_complete.connect(self._on_animation_handler_sequence_complete)

func show_fc() -> void:
	self.visible = true
	
func hide_fc() -> void:
	var effectPanels = [$ForecastMargin/ForecastBox/EffectRow, $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel, $ForecastMargin/ForecastBox/EffectRow/Labels2, $ForecastMargin/ForecastBox/EffectRow/TargetEfPanel]
	self.visible = false
	for p in effectPanels:
		p.visible = false
	_close_effects()
	if animationsLoaded: _free_animations()


func update_fc(payload) -> void:
	# New model:
	# payload = {
	#   "results": CombatResults,
	#   "attacker_unit": Unit,
	#   "defender_unit": Unit,
	#   "attacker_action": Dictionary (optional; only for display name fallback)
	# }
	#
	# Legacy model:
	# payload is Dictionary keyed by units

	if payload is Dictionary and payload.has("results") and payload["results"] is CombatResults:
		_update_from_results(payload)
		return

	push_warning("CombatForecast.update_fc: unsupported payload type: %s" % [typeof(payload)])

#update from funcs
func _update_from_results(data: Dictionary) -> void:
	var cr: CombatResults = data["results"]
	var atk_unit: Unit = data.get("attacker_unit", null)
	var def_unit: Unit = data.get("defender_unit", null)

	# Safety
	if cr == null or cr.rounds.size() == 0:
		hide_fc()
		return

	# We need live Units for names/HP and for animation handler
	if atk_unit == null or def_unit == null:
		push_warning("CombatForecast: missing attacker_unit/defender_unit in payload; cannot render names/HP safely.")
		hide_fc()
		return

	_call_animations([atk_unit, def_unit])

	var atkPanel := $ForecastMargin/ForecastBox/StatRow/AtkPanel/AMa/AVB
	var trgtPanel := $ForecastMargin/ForecastBox/StatRow/TargetPanel/TMa/TVB
	var atkLabels := atkPanel.get_children()
	var defLabels := trgtPanel.get_children()

	# First round drives forecast UI
	var round: Dictionary = cr.rounds[0]
	var actions: Array = round.get("actions", [])

	# Find initiator action and optional counter action
	var init_action: Dictionary
	var counter_action: Dictionary
	for a in actions:
		if bool(a.get("is_initiator", false)):
			init_action = a
		else:
			counter_action = a

	# If no initiator action exists, hide
	if init_action == null:
		hide_fc()
		return

	# Always show left panel (attacker preview)
	_fill_side_panel(atkLabels, atk_unit, init_action)

	# Right panel depends on whether a counter preview exists OR counter_possible flag
	var show_counter := false
	if counter_action != null:
		show_counter = true
	elif bool(init_action.get("counter_possible", false)):
		# Eligible but no explicit counter action included (should be rare)
		show_counter = true

	if show_counter:
		trgtPanel.visible = true
		if counter_action != null:
			_fill_side_panel(defLabels, def_unit, counter_action)
		else:
			# Fallback: show defender name/HP with blanks
			_fill_empty_side_panel(defLabels, def_unit)
	else:
		trgtPanel.visible = false

	# Effects row
	_load_effects_from_results(cr, atk_unit, def_unit, init_action, counter_action)

func _fill_side_panel(labels: Array, unit: Unit, action: Dictionary) -> void:
	# labels index assumption (from your old code):
	# 0 name, 1 hp, 2 hit, 3 dmg, 4 crit, 5 action name
	if labels.size() < 6:
		return

	var swing: Dictionary = {}
	var swings: Array = action.get("swings", [])
	if swings.size() > 0:
		swing = swings[0]

	# Name
	labels[0].set_text(unit.unit_name)

	# HP display (optionally show remaining)
	var lifeTemplate: String = StringGetter.get_template("combat_hp")
	var remainTemplate: String = StringGetter.get_template("combat_hp_remain")
	var lifeText: String = "[center]%s[/center]"

	
	#var active := unit.active_stats
	var hp := lifeTemplate % [unit.current_life, unit.active_stats.Life]

	# If you already patched forecast_service to compute remaining HP somewhere,
	# you can pipe it into swing["remaining_life"] later. For now compute here.
	var swing_count := int(action.get("swing_count", 1))
	var dmg := int(swing.get("dmg", 0))
	var remaining := _get_remaining_life_from_unit(unit, dmg, swing_count)

	if remaining != unit.current_life:
		lifeText = lifeText % [remainTemplate]
		lifeText = lifeText % [remaining, hp]
	else:
		lifeText = lifeText % [hp]

	labels[1].set_text(lifeText)

	# Hit/Crit/Dmg are already in CombatResults for forecast
	var hit_text := "--"
	var dmg_text := "--"
	var crit_text := "--"

	hit_text = str(int(swing.get("hit_chance", 0)))
	dmg_text = str(int(swing.get("dmg", 0)))
	crit_text = str(int(swing.get("crit_chance", 0)))

	# Multi-swing icon uses swing_count; you used "dmg xN" previously
	if swing_count > 1:
		dmg_text = dmg_text + " x" + str(swing_count)

	labels[2].set_text(hit_text)
	labels[3].set_text(dmg_text)
	labels[4].set_text(crit_text)

	# Action name (still needs Unit + equipped weapon/skill/item context)
	labels[5].set_text(_get_action_string_for_unit(unit, action))


func _fill_empty_side_panel(labels: Array, unit: Unit) -> void:
	if labels.size() < 6:
		return
	labels[0].set_text(unit.unit_name)
	labels[1].set_text("[center]--[/center]")
	labels[2].set_text("--")
	labels[3].set_text("--")
	labels[4].set_text("--")
	labels[5].set_text("--")


func _get_remaining_life_from_unit(unit: Unit, dmg: int, swings: int = 1) -> int:
	var cur := int(unit.current_life)
	if dmg <= 0:
		return cur
	var total :int= dmg * max(1, swings)
	return clampi(cur - total, 0, 9999)


func _get_action_string_for_unit(unit: Unit, action: Dictionary) -> String:
	# Your old display logic: weapon unless skill/item; only show if counter/eligible.
	# Now: always show.
	var path := ""
	var skill = action.get("Skill", null)
	var item = action.get("Item", null)
	if skill != null and skill.get("id"):
		path = "skill_name_%s" % [skill.id]
	elif item != null and item.get("id"):
		path = "ofuda_%s" % [item.id]
	else:
		var wep = unit.get_equipped_weapon()
		if wep != null:
			path = "weapon_%s" % [wep.id]
		else:
			return StringGetter.get_string("unarmed") if StringGetter.has_string("unarmed") else "--"

	return StringGetter.get_string(path)

func _load_effects_from_results(
	cr: CombatResults,
	atk_unit: Unit,
	def_unit: Unit,
	init_action: Dictionary,
	counter_action: Dictionary
) -> void:
	$ForecastMargin/ForecastBox/EffectRow.visible = true

	var atkList = $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel/AMa/AVB
	var defList = $ForecastMargin/ForecastBox/EffectRow/TargetEfPanel/TMa/TVB

	# Panels visible only if that side exists
	$ForecastMargin/ForecastBox/EffectRow/AtkEfPanel.visible = true
	$ForecastMargin/ForecastBox/EffectRow/Labels2.visible = true
	$ForecastMargin/ForecastBox/EffectRow/TargetEfPanel.visible = (counter_action != null)

	_clear_old(atkList)
	_clear_old(defList)

	_add_effects_for_action(atkList, init_action)

	if counter_action != null:
		_add_effects_for_action(defList, counter_action)
	else:
		# If no counter action, show "void" on defender side by hiding target panel
		pass

func _add_effects_for_action(list_node: Node, action: Dictionary) -> void:
	if action == null:
		return

	var swings: Array = action.get("swings", [])
	if swings.size() == 0:
		_add_void_effect_label(list_node)
		return

	var swing: Dictionary = swings[0]
	var effs: Array = swing.get("effects", [])
	if effs.size() == 0:
		_add_void_effect_label(list_node)
		return

	var selfEff: Array = []
	var targEff: Array = []
	var globEff: Array = []

	for rec in effs:
		var e: Effect = rec.get("effect", null)
		if e == null:
			continue
		var s: String = "[center]%s[/center]" % StringGetter.get_combat_effect_string(e)

		match int(e.target):
			Enums.EFFECT_TARGET.GLOBAL: globEff.append(s)
			Enums.EFFECT_TARGET.SELF: selfEff.append(s)
			Enums.EFFECT_TARGET.TARGET: targEff.append(s)
			_:
				# ignore EQUIPPED/NONE for combat forecast
				pass

	if globEff.size() > 0:
		_add_effect_labels(list_node, globEff)

	if targEff.size() > 0:
		_add_effect_labels(list_node, targEff)

	if selfEff.size() > 0:
		var lbl := RichTextLabel.new()
		var selfString := "[center]%s[/center]" % StringGetter.get_string("effect_target_self")
		Global.set_rich_text_params(lbl)
		lbl.set_text(selfString)
		list_node.add_child(lbl)
		_add_effect_labels(list_node, selfEff)


func _add_void_effect_label(list_node: Node) -> void:
	var string : String = "[center]%s[/center]" % [StringGetter.get_string("void_value")]
	var lbl := RichTextLabel.new()
	Global.set_rich_text_params(lbl)
	lbl.set_text(string)
	list_node.add_child(lbl)

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
	var lists : Array = [$ForecastMargin/ForecastBox/EffectRow/TargetEfPanel/TMa/TVB, $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel/AMa/AVB]
	var panels : Array = [$ForecastMargin/ForecastBox/EffectRow, $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel, $ForecastMargin/ForecastBox/EffectRow/Labels2, $ForecastMargin/ForecastBox/EffectRow/TargetEfPanel]
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
