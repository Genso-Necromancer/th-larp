extends Control

signal jobs_done_act
signal action_selected(selection)
signal menu_opened(container)
signal weapon_selected(weapon)
signal weapon_changed(weapon)
signal item_pressed
signal trade_pressed
signal item_used
signal denied
signal menu_closed

@onready var actFrame = $VFlowContainer/ActComCon/Count
@onready var subFrame = $m
@onready var frames = [actFrame, subFrame]

enum MENU_STATES {ACTION, ITEM_OPEN, AUX_OPEN, SKILL_OPEN}
var state = MENU_STATES.ACTION
var prevState = []
var activeItem = null

func _ready():
	var parent = get_parent()
	self.jobs_done_act.connect(parent._on_jobs_done)
	self.weapon_selected.connect(parent._on_weapon_selected)
	self.item_used.connect(parent._on_item_used)
	emit_signal("jobs_done_act", "Action", self)
	

func _gui_input(event: InputEvent) -> void:
	if state != MENU_STATES.ACTION and event.is_action_pressed("ui_return"):
		close_menu()
		accept_event()
		

#func get_options_menu():
	#var menu = $VFlowContainer/ActComCon/Count/ActionBox/VBoxContainer
	#return menu

func _open_menu():
	state = MENU_STATES.ACTION
	self.visible = true
	#print(state)
	
func close_menu():
	
	var aUnit = Global.activeUnit
	
	match state:
		MENU_STATES.ACTION:
			_close_all()
		MENU_STATES.ITEM_OPEN:
			_close_sub()
			open_action_menu(aUnit)
		MENU_STATES.AUX_OPEN:
			var item = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
			_close_aux()
			emit_signal("menu_opened", item)
		MENU_STATES.SKILL_OPEN:
			_close_sub()
			open_action_menu(aUnit)
			
func _close_all():
	var generic = $VFlowContainer/ActComCon/Count/ActionBox/GenericContainer
	var action = $VFlowContainer/ActComCon/Count/ActionBox/ActionContainer
	var item = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
	var skill = $VFlowContainer/ActComCon/Count/ActionBox/SkillContainer
	_close_sub()
	_close_aux()
	prevState.clear()
	self.visible = false
	generic.visible = false
	action.visible = false
	item.visible = false
	skill.visible = false
	prevState.clear()
	_clear_items()
	_clear_skills()
	emit_signal("menu_closed")
	
func open_generic_menu():
	var container = $VFlowContainer/ActComCon/Count/ActionBox/GenericContainer
	_open_sub_menu(container)
	#_close_all_others(container)
	_open_menu()
	#container.visible = true
	##container.set_deferred("visible", true)
	#emit_signal("menu_opened", container)
	
func open_action_menu(unit):
	var action = $VFlowContainer/ActComCon/Count/ActionBox/ActionContainer
	var aBtn = $VFlowContainer/ActComCon/Count/ActionBox/ActionContainer/AtkBtn
	var sBtn = $VFlowContainer/ActComCon/Count/ActionBox/ActionContainer/SklBtn
	#var wBtn = $VFlowContainer/ActComCon/Count/ActionBox/ActionContainer/WaitBtn
	_close_all_others(action)
	var uInv = unit.unitData.Inv
	if unit != null:
		for item in uInv:
			if unit.check_valid_equip(item, 1):
				aBtn.disabled = false
				break
			elif !aBtn.disable:
				aBtn.disabled = true
		
	if unit != null and unit.unitData.Skills.size() != null and unit.unitData.Skills.size() > 0:
		sBtn.disabled = false
	else: 
		sBtn.disabled = true
			
	if unit != null and unit.check_status("Sleep"):
		aBtn.disabled = true
		sBtn.disabled = true
	#print("open_menu:")
	#print("Button: " + str(aBtn.get_global_position()))
	_open_menu()
	action.visible = true
	#_fill_items()
	#_fill_skills()
	emit_signal("menu_opened", action)
	
func open_skill_menu():
	var skills = $VFlowContainer/ActComCon/Count/ActionBox/SkillContainer
	_open_menu()
	_fill_skills()
	_open_sub_menu(skills)
	_progress_state(MENU_STATES.SKILL_OPEN)

func _on_end_btn_pressed():
	var selection = "End"
	accept_event()
	close_menu()
	emit_signal("action_selected", selection)
	

func _on_atk_btn_pressed():
	var selection = "Attack"
	var action = {"Weapon": true, "Skill": false}
	accept_event()
	close_menu()
	emit_signal("action_selected", selection, action)
	
func _on_skill_pressed(b):
	var selection = "Skill"
	var action = b.get_meta("action")
	accept_event()
	_close_all()
	if action.Weapon:
		selection = "Augment"
	emit_signal("action_selected", selection, action)

func _close_all_others(menu):
	var generic = $VFlowContainer/ActComCon/Count/ActionBox/GenericContainer
	var action = $VFlowContainer/ActComCon/Count/ActionBox/ActionContainer
	var item = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
	var skill = $VFlowContainer/ActComCon/Count/ActionBox/SkillContainer
	var containers = [generic, action, item, skill]
	for c in containers:
		if c != menu:
			c.visible = false

func _on_wait_btn_pressed():
	var selection = "Wait"
	accept_event()
	close_menu()
	emit_signal("action_selected", selection)


func open_weapons(range: Array = [-1, -1], augment = false): #Don't pass a distance value to open in "item mode" for use/equip.
	var itemFrame = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
	_close_all_others(itemFrame)
	_open_menu()
	itemFrame.visible = true
	#itemFrame.set_deferred("visible", true)
	_fill_items(range, augment)
	emit_signal("menu_opened", itemFrame)

func _open_sub_menu(menu: Control):
	_close_all_others(menu)
	#_open_menu()
	menu.visible = true
	emit_signal("menu_opened", menu)

func _fill_items(range: Array = [-1, -1], augment = false):
	var itemFrame = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
	var unitData
	var inv
	var aUnit = Global.activeUnit
	var itemData = UnitData.itemData
	var iMode = false
	var minR = range[0]
	var maxR = range[1]
	
	if minR <= -1 or maxR <= -1:
		iMode = true
		_progress_state(MENU_STATES.ITEM_OPEN)
	unitData = aUnit.unitData
	inv = unitData.Inv
	for wep in inv: #needs "weapon selected" signal
		var b : Button
		var wepData = itemData[wep.ID]
		var wepName = itemData[wep.ID].Name
		var disable = false
		var dur = wep.DUR
		var mDur = wepData.MaxDur
		var durString
		var valid = true
		var i = inv.find(wep)
		#var action := {"weapon": true, "skill": false}
		if !iMode and wepData.Category == "ITEM":
			continue
		elif !iMode and wepData.Category == "ACC":
			continue
		elif !iMode and !valid:
			continue
		elif iMode and wepData.Category != "ITEM":
			valid = aUnit.check_valid_equip(wep)
		if maxR == 0 and minR == 0:
			pass
		elif maxR < wepData.MaxRange and minR > wepData.MinRange:
			disable = true
		if !valid:
			disable = true
		if dur == -1 or mDur == -1:
			durString = str(" --")
		else:
			durString = str(" [" + str(dur) + "/" + str(mDur)+"]")
		b = Button.new()
		b.set_text(str(wepName) + durString)
		b.set_button_icon(wepData.Icon)
		b.set_expand_icon(false)
		#b.set_meta("action", action)
		b.set_meta("weapon", wep)
		b.set_meta("index", i)
		b.set_meta("action", {"Weapon": wep, "Skill": augment})
		b.set_mouse_filter(Control.MOUSE_FILTER_PASS)
		b.set_focus_neighbor(SIDE_LEFT, b.get_path_to(b))
		b.set_focus_neighbor(SIDE_RIGHT, b.get_path_to(b))
		
		if !iMode and disable == true:
			b.set_disabled(true)
			
		if !iMode:
			b.pressed.connect(self._on_weapon_pressed.bind(b))
			b.focus_entered.connect(self._on_weapon_hovered.bind(b))
			b.mouse_entered.connect(self._on_weapon_hovered.bind(b))
		else:
			b.pressed.connect(self._on_item_pressed.bind(b))
			
		itemFrame.add_child(b)
		print("Item Added: " + b.get_text() + " | " + str(b))
		
func _fill_skills():
	var p = $VFlowContainer/ActComCon/Count/ActionBox/SkillContainer
	var aUnit = Global.activeUnit
	var skills = aUnit.unitData.Skills
	for id in skills:
		var b : Button
		var skill = UnitData.skillData[id]
		var cost := str(skill.Cost)
		var sName : String = skill.SkillName #switch to parser
		var isAugment : bool = skill.Augment
		var action := {"Weapon": isAugment, "id": id}
		var icon = skill.Icon
		
		b = Button.new()
		b.set_text(str(sName) + " " + cost)
		b.set_button_icon(icon)
		b.set_expand_icon(false)
		b.set_meta("action", action)
		#b.set_meta("index", i)
		b.set_mouse_filter(Control.MOUSE_FILTER_PASS)
		b.set_focus_neighbor(SIDE_LEFT, b.get_path_to(b))
		b.set_focus_neighbor(SIDE_RIGHT, b.get_path_to(b))
		p.add_child(b)
		b.pressed.connect(self._on_skill_pressed.bind(b))
		if !validate_skill(skill):
			b.disabled = true
		print("id Added: " + b.get_text() + " | " + str(b))
	#print("Skills filled")

func validate_skill(skill) -> bool:
	var time = Global.timeOfDay
	var isValid := false
	if skill.RuleType:
		match skill.RuleType:
			Enums.RULE_TYPE.TIME:
				if skill.Rule == time:
					isValid = true
				
	return isValid

func _clear_items():
	var itemFrame = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
	for button in itemFrame.get_children():
		button.queue_free()
	print("Items Cleared")
	

func _clear_skills():
	var skillFrame = $VFlowContainer/ActComCon/Count/ActionBox/SkillContainer
	for button in skillFrame.get_children():
		button.queue_free()
	print("Skills cleared")
		
func _on_weapon_pressed(b):
	close_menu()
	emit_signal("weapon_selected", b)
	
func _on_weapon_hovered(b):
	if b.disabled:
		return
	emit_signal("weapon_changed", b)

func _on_itm_btn_pressed():
	var items = $VFlowContainer/ActComCon/Count/ActionBox/ItemContainer
	open_weapons()
	_open_sub_menu(items)
	
	
func _on_skl_btn_pressed():
	var skills = $VFlowContainer/ActComCon/Count/ActionBox/SkillContainer
	_fill_skills()
	_open_sub_menu(skills)
	_progress_state(MENU_STATES.SKILL_OPEN)

func _on_trd_btn_pressed():
	pass # Replace with function body.
	
func _on_item_pressed(button):
	var auxMenu = $VFlowContainer/ItmComCon
	var auxList = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer
	var eqBtn = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer/EqpBtn
	var unBtn = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer/UnEqpBtn
	var usBtn = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer/UseBtn
	var iData = UnitData.itemData
	var item = button.get_meta("weapon")
	var index = button.get_meta("index")
	var wData = iData[item.ID]
	var aUnit = Global.activeUnit
	var valid : bool = false
	
	valid = aUnit.check_valid_equip(item)
	
	if valid and !item.Equip:
		eqBtn.visible = true
		eqBtn.disabled = false
		eqBtn.set_meta("index", index)
	elif item.Equip:
		unBtn.visible = true
		unBtn.disabled = false
		unBtn.set_meta("index", index)
	if wData.USE:
		usBtn.visible = true
		usBtn.disabled = false
		usBtn.set_meta("index", index)
	if !eqBtn.visible and !unBtn.visible and !usBtn.visible:
		emit_signal("denied")
		return 
		
	auxMenu.visible = true
	_progress_state(MENU_STATES.AUX_OPEN)
	activeItem = item
	emit_signal("menu_opened", auxList)

func _close_sub():
	_regress_state()
	_clear_items()
	_clear_skills()

func _close_aux():
	var auxMenu = $VFlowContainer/ItmComCon
	var auxList = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer
	var btns = auxList.get_children()
	for btn in btns:
		btn.visible = false
		btn.disabled = true
	auxMenu.visible = false
	activeItem = null
	_regress_state()
	


func _on_eqp_btn_pressed():
	var aUnit = Global.activeUnit
	var btn = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer/EqpBtn
	var i = btn.get_meta("index")
	aUnit.set_equipped(i)
	close_menu()


func _on_un_eqp_btn_pressed():
	var aUnit = Global.activeUnit
	var btn = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer/UnEqpBtn
	var i = btn.get_meta("index")
	aUnit.unequip(i)
	close_menu()

func _on_use_btn_pressed():
	var aUnit = Global.activeUnit
	var btn = $VFlowContainer/ItmComCon/MarginContainer/MarginContainer/AuxContainer/UseBtn
	var i = btn.get_meta("index")
	emit_signal("item_used", aUnit, i)
	_close_all()
	
	
func _progress_state(newState):
	prevState.append(state)
	state = newState
	#print(state)

func _regress_state():
	var returnState = prevState.pop_back()
	state = returnState



	
	
