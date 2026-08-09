extends PanelContainer

class_name CombatForecast

signal weapon_selected(button)

var animationsLoaded = false
var cursorPath := preload("res://scenes/GUI/menu_cursor.tscn")
var cursor : MenuCursor
@onready var scroll_hbox:ScrollHBox=$stat_margin/center_vbox/scroll_hbox
@onready var left_name: RichTextLabel = $stat_margin/center_vbox/stat_hbox/left_name_margin/NAME
@onready var right_name: RichTextLabel = $stat_margin/center_vbox/stat_hbox/right_name_margin/NAME
@onready var left_stats: VBoxContainer = $stat_margin/center_vbox/stat_hbox/left_stat_box/MarginContainer/VBoxContainer
@onready var right_stats: VBoxContainer = $stat_margin/center_vbox/stat_hbox/right_stat_box/MarginContainer/VBoxContainer
@onready var right_stat_box: PanelContainer = $stat_margin/center_vbox/stat_hbox/right_stat_box
@onready var right_name_margin: MarginContainer = $stat_margin/center_vbox/stat_hbox/right_name_margin
@onready var inv: InventoryPanel = $stat_margin/center_vbox/TradePnl
@onready var stat_hbox: HBoxContainer = $stat_margin/center_vbox/stat_hbox


func _ready():
	self.visible = false
	inv.visible = false
	_set_tree_mouse_filter(stat_hbox, Control.MOUSE_FILTER_IGNORE)
	scroll_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#scroll_hbox.open_scrolls()
	SignalTower.forecast_predicted.connect(self.update_fc)
	SignalTower.sequence_complete.connect(self._on_animation_handler_sequence_complete)


func _process(_delta: float) -> void:
	_sync_forecast_inventory_hover_focus()


func _input(event: InputEvent) -> void:
	if not visible or not inv.visible:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		if _click_forecast_inventory_button(mouse_event.position):
			get_viewport().set_input_as_handled()

func show_fc() -> void:
	self.visible = true
	
func hide_fc() -> void:
	self.visible = false
	right_stat_box.visible = false
	right_name_margin.visible = false
	close_weapon_select()
	scroll_hbox.close_scrolls()
	if animationsLoaded: _free_animations()


func open_weapon_select(unit: Unit, reach: Array = [0, 0]) -> void:
	if unit == null:
		return
	inv.clear_items()
	inv.set_meta("Unit", unit)
	inv.fill_items(false, reach, true)
	_connect_forecast_signal(inv.get_item_buttons())
	_load_cursor()
	inv.visible = true
	_give_items_focus()


func close_weapon_select() -> void:
	inv.clear_items()
	inv.visible = false
	_free_cursor()


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

	# First cmb_round drives forecast UI
	var cmb_round: Dictionary = cr.rounds[0]
	var actions: Array = cmb_round.get("actions", [])

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
	_fill_side_panel(left_name, left_stats, atk_unit, def_unit, init_action)

	# Right panel depends on whether a counter preview exists OR counter_possible flag
	var show_counter := false
	if counter_action != null:
		show_counter = true
	elif bool(init_action.get("counter_possible", false)):
		# Eligible but no explicit counter action included (should be rare)
		show_counter = true

	if show_counter:
		right_stat_box.visible = true
		right_name_margin.visible = true
		if counter_action != null:
			_fill_side_panel(right_name, right_stats, def_unit, atk_unit, counter_action)
		else:
			# Fallback: show defender name/HP with blanks
			_fill_empty_side_panel(right_name, right_stats, def_unit)
	else:
		right_stat_box.visible = false
		right_name_margin.visible = false

	# Effects row
	_load_effects_from_results(cr, atk_unit, def_unit, init_action, counter_action)

func _fill_side_panel(name_label: RichTextLabel, stat_box: VBoxContainer, actor_unit: Unit, hp_preview_unit: Unit, action: Dictionary) -> void:
	var labels: Array = stat_box.get_children()
	# stat_box order:
	# 0 life, 1 hit, 2 dmg, 3 crit, 4 action name
	if name_label == null or labels.size() < 5 or actor_unit == null or hp_preview_unit == null:
		return

	var swing: Dictionary = {}
	var swings: Array = action.get("swings", [])
	if swings.size() > 0:
		swing = swings[0]

	# Name
	name_label.set_text(actor_unit.unit_name)

	# HP display (optionally show remaining)
	var lifeTemplate: String = StringGetter.get_template("combat_hp")
	var remainTemplate: String = StringGetter.get_template("combat_hp_remain")
	var lifeText: String = "[center]%s[/center]"

	
	#var active := unit.active_stats
	var hp := lifeTemplate % [hp_preview_unit.current_life, hp_preview_unit.active_stats.Life]
	var swing_count := int(action.get("swing_count", 1))
	var remaining := int(action.get("target_life_after", hp_preview_unit.current_life))

	if remaining != hp_preview_unit.current_life:
		lifeText = lifeText % [remainTemplate]
		lifeText = lifeText % [remaining, hp]
	else:
		lifeText = lifeText % [hp]

	labels[0].set_text(lifeText)

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

	labels[1].set_text(hit_text)
	labels[2].set_text(dmg_text)
	labels[3].set_text(crit_text)

	# Action name (still needs Unit + equipped weapon/skill/item context)
	labels[4].set_text(_get_action_string_for_unit(actor_unit, action))


func _fill_empty_side_panel(name_label: RichTextLabel, stat_box: VBoxContainer, unit: Unit) -> void:
	var labels: Array = stat_box.get_children()
	if name_label == null or labels.size() < 5:
		return
	name_label.set_text(unit.unit_name)
	labels[0].set_text("[center]--[/center]")
	labels[1].set_text("--")
	labels[2].set_text("--")
	labels[3].set_text("--")
	labels[4].set_text("--")


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
	var skill = action.get("skill_ref", null)
	var item = action.get("item_ref", null)
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
) -> void: #Waste: cr, atk_unit; def_unit don't seem to be used. Doesn't seem necessary to pass through.
	scroll_hbox.load_effect_labels(cr,atk_unit,def_unit,init_action,counter_action)
	
	#old code
	#$ForecastMargin/ForecastBox/EffectRow.visible = true
#
	#var atkList = $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel/AMa/AVB
	#var defList = $ForecastMargin/ForecastBox/EffectRow/TargetEfPanel/TMa/TVB
#
	## Panels visible only if that side exists
	#$ForecastMargin/ForecastBox/EffectRow/AtkEfPanel.visible = true
	#$ForecastMargin/ForecastBox/EffectRow/Labels2.visible = true
	#$ForecastMargin/ForecastBox/EffectRow/TargetEfPanel.visible = (counter_action != null)
#
	#_clear_old(atkList)
	#_clear_old(defList)
#
	#_add_effects_for_action(atkList, init_action)
#
	#if counter_action != null:
		#_add_effects_for_action(defList, counter_action)
	#else:
		## If no counter action, show "void" on defender side by hiding target panel
		#pass
#
#func _add_effects_for_action(list_node: Node, action: Dictionary) -> void: #old
	#if action == null:
		#return
#
	#var swings: Array = action.get("swings", [])
	#if swings.size() == 0:
		#_add_void_effect_label(list_node)
		#return
#
	#var swing: Dictionary = swings[0]
	#var effs: Array = swing.get("effects", [])
	#if effs.size() == 0:
		#_add_void_effect_label(list_node)
		#return
#
	#var selfEff: Array = []
	#var targEff: Array = []
	#var globEff: Array = []
#
	#for rec in effs:
		#var e: Effect = rec.get("effect", null)
		#if e == null:
			#continue
		#var s: String = "[center]%s[/center]" % StringGetter.get_combat_effect_string(e)
#
		#match int(e.target):
			#Enums.EFFECT_TARGET.GLOBAL: globEff.append(s)
			#Enums.EFFECT_TARGET.SELF: selfEff.append(s)
			#Enums.EFFECT_TARGET.TARGET: targEff.append(s)
			#_:
				## ignore EQUIPPED/NONE for combat forecast
				#pass
#
	#if globEff.size() > 0:
		#_add_effect_labels(list_node, globEff)
#
	#if targEff.size() > 0:
		#_add_effect_labels(list_node, targEff)
#
	#if selfEff.size() > 0:
		#var lbl := RichTextLabel.new()
		#var selfString := "[center]%s[/center]" % StringGetter.get_string("effect_target_self")
		#Global.set_rich_text_params(lbl)
		#lbl.set_text(selfString)
		#list_node.add_child(lbl)
		#_add_effect_labels(list_node, selfEff)


#func _add_void_effect_label(list_node: Node) -> void:
	#var string : String = "[center]%s[/center]" % [StringGetter.get_string("void_value")]
	#var lbl := RichTextLabel.new()
	#Global.set_rich_text_params(lbl)
	#lbl.set_text(string)
	#list_node.add_child(lbl)

#func _clear_old(list): #old
	#var old = list.get_children()
	#for l in old:
		#l.queue_free()

		
#func _add_effect_labels(lists, strings):
	#for string in strings:
		#var lbl = RichTextLabel.new()
		#Global.set_rich_text_params(lbl)
		#lbl.set_text(string)
		#lists.add_child(lbl)

#func _close_effects() -> void:
	#var lists : Array = [$ForecastMargin/ForecastBox/EffectRow/TargetEfPanel/TMa/TVB, $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel/AMa/AVB]
	#var panels : Array = [$ForecastMargin/ForecastBox/EffectRow, $ForecastMargin/ForecastBox/EffectRow/AtkEfPanel, $ForecastMargin/ForecastBox/EffectRow/Labels2, $ForecastMargin/ForecastBox/EffectRow/TargetEfPanel]
	#for l in lists:
		#for child in l.get_children():
				#child.queue_free()
	#for p in panels:
		#p.visible = false
	

func _call_animations(units):
	var animHandler = $AnimationHandler
	if !animationsLoaded:
		animHandler.load_animations(units)
		animationsLoaded = true
	return


func _connect_forecast_signal(weapons: Array) -> void:
	for w in weapons:
		if not w.focus_entered.is_connected(self._on_weapon_focus_entered.bind(w)):
			w.focus_entered.connect(self._on_weapon_focus_entered.bind(w))
		if not w.pressed.is_connected(self._on_weapon_pressed.bind(w)):
			w.pressed.connect(self._on_weapon_pressed.bind(w))


func _give_items_focus() -> void:
	if cursor == null:
		return
	var item_buttons := inv.get_item_buttons()
	cursor.resignal_cursor(item_buttons)
	cursor.setCursor = true
	if inv.items.is_empty():
		return
	var first_button = inv.items[0]
	if first_button != null and first_button.get_button() != null:
		first_button.get_button().call_deferred("grab_focus")


func _load_cursor() -> void:
	if is_instance_valid(cursor):
		return
	cursor = cursorPath.instantiate()
	add_child(cursor)


func _free_cursor() -> void:
	if not is_instance_valid(cursor):
		return
	cursor.queue_free()
	cursor = null


func _set_tree_mouse_filter(root: Control, filter_value: Control.MouseFilter) -> void:
	if root == null:
		return
	root.mouse_filter = filter_value
	for child in root.get_children():
		if child is Control:
			_set_tree_mouse_filter(child, filter_value)


func _on_weapon_focus_entered(weapon) -> void:
	SignalTower.emit_signal("inventory_weapon_changed", weapon)


func _on_weapon_pressed(weapon) -> void:
	close_weapon_select()
	weapon_selected.emit(weapon)


func _sync_forecast_inventory_hover_focus() -> void:
	if not visible or not inv.visible or cursor == null:
		return
	var mouse_pos := get_global_mouse_position()
	for button in inv.get_item_buttons():
		if button == null or button.disabled or not button.visible:
			continue
		if not button.get_global_rect().has_point(mouse_pos):
			continue
		if get_viewport().gui_get_focus_owner() != button:
			button.grab_focus()
			cursor.set_cursor(button)
		return


func _click_forecast_inventory_button(mouse_pos: Vector2) -> bool:
	for button in inv.get_item_buttons():
		if button == null or button.disabled or not button.visible:
			continue
		if not button.get_global_rect().has_point(mouse_pos):
			continue
		button.grab_focus()
		if cursor != null:
			cursor.set_cursor(button)
		button.emit_signal("pressed")
		return true
	return false

func _free_animations():
	var animHandler = $AnimationHandler
	animHandler._clear_sequence()
	animationsLoaded = false

func _on_animation_handler_sequence_complete():
	animationsLoaded = false
