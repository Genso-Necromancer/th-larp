extends VBoxContainer

class_name ActionBox


func _ready():
	_disable_hide_all()


func _disable_hide_all():
	var buttons : Array = get_children()
	
	for b in buttons:
		b.visible = false
		b.disabled = true


func connect_signals(parent:ActionMenu): #HERE, coded this all wrong. Way too early to be sending off a "selection" I am dumb. Tackle this first.
	var buttons : Array = get_children()
	for b in buttons:
		var bName = b.get_name()
		b.pressed.connect(parent._on_button_pressed.bind(bName))

##Checks context of unit and actives that appropriate buttons. Buttons Not Implemented: Talk, Open, Steal
func display_unit_actions(unit : Unit):
	var buttons : Array = get_children()
	var itemFlags : Dictionary = _check_inv(unit)
	var inReach : Dictionary = _check_reach(unit)
	var hasSkills := false
	var noFocus := true
	
	if unit.skills:
		hasSkills = true
	
	for b in buttons:
		var bName = b.get_name()
		match bName:
			"TalkBtn": pass
			"VisitBtn": pass
			"ShopBtn": pass
			"SeizeBtn":
				b.visible = Global.map_ref.is_seize(unit.cell)
				b.disabled = !b.visible
					
			"AtkBtn": 
				if itemFlags.hasWeapons and inReach.Hostiles:
					b.visible = true
					b.disabled = false
				else:
					b.visible = true
					b.disabled = true
			"SklBtn": 
				if hasSkills:
					b.visible = true
					b.disabled = false
				else:
					b.visible = false
					b.disabled = true
			"OpenBtn": pass
			"StealBtn": pass
			"OfudaBtn": 
				if itemFlags.canOfuda:
					b.visible = true
					b.disabled = false
				else:
					b.visible = false
					b.disabled = true
			"ItmBtn": 
				if itemFlags.hasItems: 
					b.visible = true
					b.disabled = false
				else:
					b.visible = true
					b.disabled = true
			"TrdBtn": 
				if inReach.Trades:
					b.visible = true
					b.disabled = false
				else:
					b.visible = true
					b.disabled = true
			"WaitBtn": 
				b.visible = true
				b.disabled = false
			_:
				b.visible = false
				b.disabled = true
		if noFocus and !b.disabled:
			noFocus = false
			b.call_deferred("grab_focus")
	
func display_player_options():
	var buttons : Array = get_children()
	var noFocus := true
	for b in buttons:
		var bName = b.get_name()
		match bName:
			"EndBtn", "StatBtn", "OpBtn", "SusBtn": 
				b.visible = true
				b.disabled = false
			_:
				b.visible = false
				b.disabled = true
		if noFocus and !b.disabled:
				noFocus = false
				b.call_deferred("grab_focus")

func _check_inv(unit:Unit) -> Dictionary:
	var uInv = unit.inventory
	var itemFlags := {"hasWeapons":false, "hasItems":false, "canOfuda":false}
	
	if unit.get_equipped_weapon() != unit.unarmed:
		itemFlags.hasWeapons = true
		itemFlags.hasItems = true
	if uInv.size() > 0:
		itemFlags.hasItems = true
		for item in uInv:
			if item is Weapon and unit.check_valid_equip(item):
				itemFlags.hasWeapons = true
			elif item is Ofuda and unit.is_proficient(item.category, item.sub_group):
				itemFlags.canOfuda = true
			if itemFlags.hasWeapons and itemFlags.canOfuda: break
	return itemFlags


func _check_reach(unit:Unit) -> Dictionary:
	var inReach := {"Hostiles":false, "Trades": false}
	var aHex = AHexGrid2D.new(Global.map_ref)
	var reach = unit.get_weapon_reach()
	if aHex.find_units_in_reach(unit, reach, Enums.FACTION_ID.ENEMY):
		inReach.Hostiles = true
	
	reach = {"Max":1,"Min":1}
	if aHex.find_units_in_reach(unit, reach, Enums.FACTION_ID.PLAYER):
		inReach.Trades = true
	
	return inReach
