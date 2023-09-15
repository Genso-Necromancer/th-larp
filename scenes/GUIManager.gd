extends Control
class_name GUIManager
@export var game_cursor_path : NodePath
#@onready var menu_cursor_path = $ActionMenu/menu_cursor
@onready var game_cursor := get_node(game_cursor_path)
@onready var originalPositionActX = $ActionMenu.position.x
@onready var originalPositionActY = $ActionMenu.position.y
@onready var originalPositionProfX = $Profile.position.x
@onready var originalPositionProfY = $Profile.position.y
@onready var opWepX = $Profile.position.x
@onready var opWepY = $Profile.position.y
@onready var weaponFrame = $ActionMenu/m/m/c/v
@onready var weaponBox = $ActionMenu/m
@onready var ActionC = $ActionMenu/Count
@onready var ActionAtk = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/AtkBtn
@onready var ActionSkl = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/SklBtn
@onready var ActionBox = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer
@onready var menu_cursor =  $ActionMenu/menu_cursor
@onready var foreCast = $CombatForecast
@onready var AName = $CombatForecast/GC/HBC/AtkPanel/AMa/AVB/NAME
@onready var ALife = $CombatForecast/GC/HBC/AtkPanel/AMa/AVB/LIFE
@onready var AAcc = $CombatForecast/GC/HBC/AtkPanel/AMa/AVB/ACC
@onready var ADmg = $CombatForecast/GC/HBC/AtkPanel/AMa/AVB/DMG
@onready var ACrit = $CombatForecast/GC/HBC/AtkPanel/AMa/AVB/CRIT
@onready var ADef = $CombatForecast/GC/HBC/AtkPanel/AMa/AVB/DEF
@onready var APrt = $CombatForecast/GC/BGA1/MC/AtkFull
@onready var TPrt = $CombatForecast/GC/BGA2/MC/TrgtFull
@onready var TName = $CombatForecast/GC/HBC/TargetPanel/TMa/TVB/NAME
@onready var TLife = $CombatForecast/GC/HBC/TargetPanel/TMa/TVB/LIFE
@onready var TAcc = $CombatForecast/GC/HBC/TargetPanel/TMa/TVB/ACC
@onready var TDmg = $CombatForecast/GC/HBC/TargetPanel/TMa/TVB/DMG
@onready var TCrit = $CombatForecast/GC/HBC/TargetPanel/TMa/TVB/CRIT
@onready var TDef = $CombatForecast/GC/HBC/TargetPanel/TMa/TVB/DEF
@onready var AtkB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/AtkBtn
@onready var SklB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/SklBtn
@onready var WaitB = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer/WaitBtn
@onready var sunDial = $HUD/SunDial
@onready var clockLabel = $HUD/Clock
var currentButton: Button = null
#@onready var _timer: Timer = $Timer

var windowMode = DisplayServer.window_get_mode()
var av = Global.actionMenu:
	set(value):
		av = value
		Global.actionMenu = value
var pv = Global.profileMenu:
	set(value):
		pv = value
		Global.profileMenu = value
var cf = Global.combatForecast:
	set(value):
		cf = value
		Global.combatForecast = value


var mouseSensitivity = 0.2
var mouseThreshold = 0.1
var profFocus
signal actionSelected(selection)
signal gui_closed
signal startTheJustice

func _ready():
	initialize()
	
	
	
func initialize():
#	_timer.wait_time = 0.1
	ActionC.visible = false
	$Profile.visible = false
	menu_cursor.visible = false
	foreCast.visible = false
	weaponBox.visible = false
	if !menu_cursor.wep_updated.is_connected(self.update_forecast):
		menu_cursor.wep_updated.connect(self.update_forecast)
	var timeRotation = Global.gameTime * 15
	sunDial.rotation_degrees = timeRotation
	clockLabel.set_text(str(Global.gameTime))
	

func _process(_delta):
	var _guiSizeAct = $ActionMenu/Count/BackgroundCenter.get_size()
	var _guiSizeProf = $Profile/BackgroundCenter.get_size()
	if game_cursor != null:
#		if game_cursor.position.x >= 237:
##			print("what")
#			$ActionMenu.global_position.x = 0 + guiSizeAct.x / 2
#		else:
#			$ActionMenu.position.x = originalPositionActX
		if game_cursor.position.x >= 137:
			$Profile.position.x = 0

		else:
			$Profile.position.x = originalPositionProfX

	else:
		return null
		
	var ActionCount = ActionBox.get_child_count()
	if ActionCount > 1:
		var adjustY = originalPositionActY - ((ActionCount - 3) * 8)
		$ActionMenu.position.y = adjustY
	else:
		$ActionMenu.position.y = originalPositionActY
	
	var wepCount = weaponFrame.get_child_count()
	if wepCount > 3:
		var adjustY = originalPositionActY - ((ActionCount - 3) * 8)
		$ActionMenu.position.y = adjustY
	else:
		$ActionMenu.position.y = originalPositionActY
	

#func _input(event):
#	if event.is_action_pressed("ui_accept") and $ActionMenu.visible== true:
#		var selectInd = ActionList.get_selected_items()
#		print(ActionList.get_selected_items())
#		var selection = ActionList.get_item_text(selectInd[0])
#		match selection:
#			"Move": $ActionMenu.visible= false
#	emit_signal("action_selected")
#	return

#func _on_action_list_item_activated(index):
#	var selection = ActionList.get_item_text(index)
#	emit_signal("actionSelected", selection)


func _on_atk_btn_pressed():
	var selection = 0
	accept_event()
	menu_cursor.visible= false
	emit_signal("actionSelected", selection)
	_on_gameboard_toggle_action()

func _on_skl_btn_pressed():
	#Establish a skill menu, switch to it when this is selected.
	
	accept_event()
	open_skills()
	Global.state = 7
#	_on_gameboard_toggle_action()


func _on_wait_btn_pressed():
	var selection = 2
	accept_event()
	_on_gameboard_toggle_action()
	emit_signal("actionSelected", selection)


func _on_gameboard_toggle_action(skillClose = false):
#	print("Size: ", $ActionMenu/Count/BackgroundCenter.get_size(), "Offset: ", $ActionMenu/Count/BackgroundCenter.get_size().x / 2)
	var actor = Global.activeUnit
	if ActionC.visible == false or skillClose:
		check_connect()
		ActionC.visible= true
		menu_cursor.state = 2
		menu_cursor.visible= true
		menu_cursor.set_cursor_from_index(0)
		ActionAtk.grab_focus()
		if actor.unitData.Skills.size() != null and actor.unitData.Skills.size() > 0:
			ActionSkl.disabled = false
		
#		print(windowMode)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	else:
		ActionSkl.disabled = true
		ActionC.visible= false
		menu_cursor.state = 0
		menu_cursor.visible= false
		weaponBox.visible = false
#		emit_signal("gui_closed")
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	return

func check_connect():
	if !AtkB.mouse_entered.is_connected(menu_cursor.mouse_entered):
		AtkB.mouse_entered.connect(menu_cursor.mouse_entered.bind(0))
	if !SklB.mouse_entered.is_connected(menu_cursor.mouse_entered):
		SklB.mouse_entered.connect(menu_cursor.mouse_entered.bind(1))
	if !WaitB.mouse_entered.is_connected(menu_cursor.mouse_entered):
		WaitB.mouse_entered.connect(menu_cursor.mouse_entered.bind(2))

func _on_gameboard_toggle_prof():
#	print("GUI",state, unitId)
	var profVis = $Profile.visible
	
	if profVis and Global.focusUnit != profFocus:
		update_prof()
		profFocus = Global.focusUnit
	else:
		
		if $Profile.visible == false:
			update_prof()
			$Profile.visible = true
			profFocus = Global.focusUnit
			
		else:
			$Profile.visible = false

func update_prof():
	var focusUnit
	var unitData 
	var wep1 = $Profile/M/G/VB/MC2/MC/VB/Wep1
	var wep2 = $Profile/M/G/VB/MC2/MC/VB/Wep2
	var wep3 = $Profile/M/G/VB/MC2/MC/VB/Wep3
	var wep4 = $Profile/M/G/VB/MC2/MC/VB/Wep4
	var weps = [wep1, wep2]
	var i = 0
	var Inv
	while i < weps.size():
		weps[i].set_text("")
		i += 1
	if Global.focusUnit.is_in_group("Enemy"):
		focusUnit = Global.focusUnit.ykTag
		$Profile/M/G/UnitExp.set_text("0")
		unitData = UnitData.unitData[focusUnit]
		Inv = UnitData.npcInv
	elif Global.focusUnit.is_in_group("Player"):
		focusUnit = Global.focusUnit.unitName.get_slice(" ", 0)
		unitData = UnitData.unitData[focusUnit]
		Inv = UnitData.plrInv
#		$Profile/M/G/UnitName.set_text(unitData["Profile"]["UnitName"])
		$Profile/M/G/UnitExp.set_text(str(unitData["Profile"]["EXP"]))
		
	$Profile/M/G/UnitName.set_text(unitData["Profile"]["UnitName"])
	$Profile/M/G/VB/MC/MC/UnitPrt.set_texture(unitData["Profile"]["Prt"])
	$Profile/M/G/VStats/UnitLevel.set_text(str(unitData["Profile"]["Level"]))
	$Profile/M/G/VStats/UnitHp.set_text(str(unitData["CLIFE"]) + "/" + str(unitData["Stats"]["LIFE"]))
	$Profile/M/G/VStats/UnitStr.set_text(str(unitData["Stats"]["PWR"]))
	$Profile/M/G/VStats/UnitMag.set_text(str(unitData["Stats"]["MAG"]))
	$Profile/M/G/VStats/UnitEle.set_text(str(unitData["Stats"]["ELEG"]))
	$Profile/M/G/VStats/UnitCele.set_text(str(unitData["Stats"]["CELE"]))
	$Profile/M/G/VStats/UnitBar.set_text(str(unitData["Stats"]["BAR"]))
	$Profile/M/G/VStats/UnitCha.set_text(str(unitData["Stats"]["CHA"]))
	
	var equipId = unitData.EQUIP
	
	var unitInv = unitData.Inv
	var eqpLabel = $Profile/M/G/VB/MC2/VB/BG/MC/Eqp
	if Inv[equipId].LIMIT:
		eqpLabel.set_text(str(Inv[equipId].NAME) + " [" + str(Inv[equipId].DUR) + "/" + str(Inv[equipId].MAXDUR)+"]")
	else:
		eqpLabel.set_text(Inv[equipId].NAME)
	
	
	i = 0
	for wep in unitInv:
		if wep == equipId:
			continue
		var l = Label.new()
		
		if Inv[wep].LIMIT:
			l.set_text(str(Inv[wep].NAME) + " [" + str(Inv[wep].DUR) + "/" + str(Inv[wep].MAXDUR)+"]")
		else:
			weps[i].set_text(Inv[wep].NAME)
		i += 1
		
#		for skill in skills.keys():
#			var b = Button.new()
#			var skillData = UnitData.skillData
#			b.set_text(skill)
#
#			b.set_meta("skill_index", skills[skill]) 
#			b.set_button_icon(skillData[skills[skill]].Icon)
#			b.set_expand_icon(false)
#			weaponFrame.add_child(b)
#			b.button_down.connect(self.skill_selected.bind(b.get_meta("skill_index")))
#			b.mouse_entered.connect(menu_cursor.mouse_entered.bind(i))
#			i += 1
#			if first == null and !b.is_disabled():
#				first = b
		
func _on_gameboard_target_focused(distance: int = 0):
	
	if !cf:
		cf = true
		foreCast.visible = cf
		open_weapons(distance)
		update_forecast()
#		TDef.set_text(str(target.DEF))
		
	else:
		open_weapons()
		menu_cursor.visible= false
		cf = false
		foreCast.visible = cf
		
		
func update_forecast():
	var active = Global.attacker
	var target = Global.defender
	var activeUnit = Global.activeUnit
	activeUnit.update_combatdata()
	AName.set_text(active.NAME)
	APrt.set_texture(active.Prt)
	ALife.set_text("%d/%d [[color=#FF2400]%d[/color]]" % [active.CLIFE, active.LIFE, active.RLIFE])
	AAcc.set_text(str(active.ACC))
	ADmg.set_text(str(active.DMG))
	ACrit.set_text(str(active.CRIT))
#		ADef.set_text(str(active.DEF))
	TName.set_text(target.NAME)
	TPrt.set_texture(target.Prt)
	TLife.set_text("%d/%d [[color=#FF2400]%d[/color]]" % [target.CLIFE, target.LIFE, target.RLIFE])
	TAcc.set_text(str(target.ACC))
	TDmg.set_text(str(target.DMG))
	TCrit.set_text(str(target.CRIT))

func open_weapons(distance: int = 0):
	#Still need conversion to unique IDs
	if !weaponBox.visible:
		var first: Button = null
		var weapons = Global.activeUnit.unitData.Inv
		var i = 0
		var unitData
		var inv
		if Global.activeUnit.is_in_group("Enemy"): 
			unitData = UnitData.unitData[Global.activeUnit.ykTag]
			inv = UnitData.npcInv
		elif Global.activeUnit.is_in_group("Player"):
			unitData = UnitData.unitData[Global.activeUnit.unitName.get_slice(" ", 0)]
			inv = UnitData.plrInv
		
		for wep in weapons:
			var b = Button.new()
			var wepName = inv[wep].NAME
			if inv[wep].LIMIT:
				b.set_text(str(wepName) + " [" + str(inv[wep].DUR) + "/" + str(inv[wep].MAXDUR)+"]")
			else:
				b.set_text(wepName)
			if distance > inv[wep].MAXRANGE or distance < inv[wep].MINRANGE:
				b.set_disabled(true)
			b.set_meta("weaponIndex", wep)
			b.set_button_icon(inv[wep].ICON)
			b.set_expand_icon(false)
			weaponFrame.add_child(b)
			b.button_down.connect(self.weapon_selected.bind(b.get_meta("weaponIndex")))
			b.mouse_entered.connect(menu_cursor.mouse_entered.bind(i))
			i += 1
			if first == null and !b.is_disabled():
				first = b
				
		weaponBox.visible = true
		menu_cursor.menu_parent = $ActionMenu/m/m/c/v
		menu_cursor.set_cursor_from_index(0)
#		await get_tree().create_timer(0.1).timeout
		menu_cursor.state = 1
		menu_cursor.visible= true
		first.grab_focus()
	elif weaponBox.visible:
		clearInventoryButtons()
		menu_cursor.menu_parent = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer
		menu_cursor.state = 0
		weaponBox.visible = false
		
func weapon_selected(index):
	var wepData 
	var unitData
	if Global.activeUnit.is_in_group("Enemy"): 
		unitData = UnitData.unitData[Global.activeUnit.ykTag]
		wepData = UnitData.npcInv
	elif Global.activeUnit.is_in_group("Player"):
		unitData = UnitData.unitData[Global.activeUnit.unitName.get_slice(" ", 0)]
		wepData = UnitData.plrInv
	accept_event()
	if wepData[index].LIMIT:
		if wepData[index].DUR == 0:
			return
		else:
			emit_signal("startTheJustice")
	else:
		emit_signal("startTheJustice")
		
#skills menu
func open_skills():
#	clearInventoryButtons()
	if !weaponBox.visible:
		var first: Button = null
		var skills = Global.activeUnit.unitData.Skills
		var i = 0
		for skill in skills:
			var b = Button.new()
			var skillData = UnitData.skillData
			b.set_text(str(skillData[skill].SkillName))
			
			b.set_meta("skill_index", skill) 
			b.set_button_icon(skillData[skill].Icon)
			b.set_expand_icon(false)
			weaponFrame.add_child(b)
			b.button_down.connect(self.skill_selected.bind(b.get_meta("skill_index")))
			b.mouse_entered.connect(menu_cursor.mouse_entered.bind(i))
			i += 1
			if first == null and !b.is_disabled():
				first = b
				
		weaponBox.visible = true
		menu_cursor.menu_parent = $ActionMenu/m/m/c/v
		menu_cursor.set_cursor_from_index(0)
#		await get_tree().create_timer(0.1).timeout
		menu_cursor.state = 2
		menu_cursor.visible= true
		first.grab_focus()
	elif weaponBox.visible:
		clearInventoryButtons()
		menu_cursor.menu_parent = $ActionMenu/Count/ActionBox/CenterContainer/VBoxContainer
		menu_cursor.state = 0
		weaponBox.visible = false
		
func _on_gameboard_toggle_skills():
	accept_event()
	open_skills()
	_on_gameboard_toggle_action(true)
	
		
func skill_selected(index):
#	var wep = Global.activeUnit.unitData.EQUIP
#	var wepData = UnitData.wepData
	var skillData = UnitData.skillData
	var skill = skillData[index]
	var selection = 1
	accept_event()
	emit_signal("actionSelected", selection, skill)
	open_skills()
	_on_gameboard_toggle_action()
#	if wepData[wep].LIMIT:
#		if wepData[wep].USES == 0:
#			return
#		else:
#			emit_signal("startTheJustice")
#	else:
#		emit_signal("startTheJustice")


func clearInventoryButtons():
	for button in weaponFrame.get_children():
		button.queue_free()


func _on_gameboard_turn_changed():
	var sunMod = 0
	var sunRot = Global.rotationFactor
#	if sunDial.rotation_degrees >= (361 - sunRot):
#		sunMod = sunDial.rotation_degrees - (361 - sunRot)
#		sunMod += sunRot
#		sunDial.rotation_degrees = sunMod
#	else: sunDial.rotation_degrees += sunRot
	sunDial.rotation_degrees += sunRot
	clockLabel.set_text(str(Global.gameTime))




