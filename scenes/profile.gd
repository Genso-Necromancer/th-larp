extends AspectRatioContainer

class_name UnitProfile

signal tooltips_on(buttons)

@onready var inventory := $ProfileMargin/ProfileHBox/SideBarMargin/SideBarVBox/InventoryPanel
@onready var fBox := $ProfileMargin/ProfileHBox/ProfileContainer/DataMargin/DataVBox/CoreMargin/CoreVBox/FeaturesMargin/FeaturesVBox/fBoxPanel/fBoxMargin/FeatLbVBox
@onready var ttPopUp := $ProfileMargin/ProfileHBox/SideBarMargin/SideBarVBox/ItemInfoPanel
@onready var fBlocker := $ProfileMargin/ProfileHBox/ProfileContainer/DataMargin/DataVBox/CoreMargin/CoreVBox/FeaturesMargin/FeaturesVBox/fBoxPanel/Panel

var tooltipMode:=false

func _init():
	self.visible = false

func _ready():
	toggle_blockers()
	ttPopUp.visible = false
	

func update_prof():
	var focusUnit = Global.focusUnit
	
	if !focusUnit:
		return
	
	var unitData = focusUnit.unitData
	#var unitStats = focusUnit.activeStats
	#var unitBuffs = focusUnit.activeBuffs
	_clear_skills()
	focusUnit.update_stats()
	_update_inventory(focusUnit)
	_update_features(focusUnit)
	_update_portrait(unitData["Profile"]["FullPrt"])
	get_tree().call_group("ProfileLabels", "you_need_to_update_yourself_NOW", focusUnit)
	

func _update_portrait(path : String):
	var texture = load(path)
	var portrait := $ProfileMargin/ProfileHBox/ProfileContainer/PortraitMargin/UnitPrt
	if !texture:
		texture = load("res://sprites/ERROR.png")
	portrait.set_texture(texture)

func _update_status(unitStatus):
	var grid := $ProfileMargin/ProfileHBox/ProfileContainer/PortraitMargin/StatusTrayMargin/StatusGridMargin/StatusGrid
	

func _update_inventory(unit) -> Array:
	inventory.set_meta("Unit", unit)
	inventory.clear_items()
	var itembuttons :Array = inventory.fill_items()
	
	return itembuttons


func _update_features(unit) -> Array:
	var skills = unit.unitData.Skills
	var sData = UnitData.skillData
	var passives = unit.unitData.Passives
	var pData = UnitData.passiveData
	var sPath = load("res://scenes/GUI/skill_button.tscn")
	var pPath = load("res://scenes/GUI/passive_button.tscn")
	var skillButtons :Array =[]
	var passiveButtons : Array =[]
	var s : SkillButton
	var p : PassiveButton
	var buttons : Array = []
	
	for passive in passives:
		p = generate_passivebutton(pPath, pData[passive])
		passiveButtons.append(p)
		fBox.add_child(p)
	
	for skill in skills:
		s = generate_skillbutton(sPath, sData[skill])
		skillButtons.append(s)
		fBox.add_child(s)
		
	buttons = [skillButtons, passiveButtons]
	return buttons
		
		
func generate_skillbutton(path, data) -> SkillButton:
	var b : SkillButton
	b = path.instantiate()
	b.set_item_text(data.SkillName, str(data.Cost))
	b.set_item_icon(data.Icon)
	return b


func generate_passivebutton(path, data) -> PassiveButton:
	var b : PassiveButton
	b = path.instantiate()
	b.set_passive_text(data)
	b.set_passive_icon(data)
	return b

#func _update_passives(unit):
	#_clear_skills()
	#var skills = unit.unitData.Skills
	#var data = UnitData.skillData
	#var path = load("res://scenes/GUI/skill_button.tscn")
	#var skillButtons :Array = []
	#var b : SkillButton
	#for skill in skills:
		#b = path.instantiate()
		#b.set_item_text(data[skill].SkillName, str(data[skill].Cost))
		#b.set_item_icon(data[skill].Icon)
		#fBox.add_child(b)
		#skillButtons.append(b)

		
func _clear_skills():
	for kid in fBox.get_children():
		fBox.remove_child(kid)
		kid.queue_free()

#tool tip code
func toggle_tooltips():
	toggle_blockers()

func toggle_blockers():
	fBlocker.visible = !fBlocker.visible
	inventory.toggle_blocker()
