
const UNIT_ID := Enums.UNIT_ID

#these three are used in combination to create the data on a single enemy unit.
const MOVE_TYPE = Enums.MOVE_TYPE
const SPEC_ID = Enums.SPEC_ID
#, Human, Kappa, Lunarian, Oni, Doll, Devil, Yukionna, Zombie, Hermit, Magician, Spirit
const JOB_ID = Enums.JOB_ID

const WEP_ID = Enums.WEP_ID


static func get_named_unit_data():
	var units = {
		"Remilia": {
				"CurLife": 1,
				"Profile": {
					"UnitName": "Remilia",
					"Prt": "res://sprites/RemiliaPrt.png",
					"FullPrt":"res://sprites/character/remilia/portrait_full.png",
					"Sprite": load("res://sprites/RemiliaTest.png"),
					"Level": 1,
					"EXP": 0,
					"Role": "Lady",
					"Species": SPEC_ID.VAMPIRE,
					},
				"Stats": {
					"Move": 5,
					"Life": 22,
					"Comp": 100,
					"Pwr": 15,
					"Mag": 6,
					"Eleg": 6,
					"Cele": 6,
					"Def": 5,
					"Cha": 8
					},
				"Growths": {
					"Move": 0,
					"Life": 1,
					"Comp": 0,
					"Pwr": 1,
					"Mag": 1,
					"Eleg": 0.4,
					"Cele": 0.4,
					"Def": 0.2,
					"Cha": 0.6
					},
				"Caps": {
					"Move": 10,
					"Life": 60,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"SpawnGear":["GNG"],
				"Skills":["LifeStealRem"],
				"Passives":["RemAura", "Fated"],
				"Weapons": {
					"Blade": false,
					"Blunt": false,
					"Stick": true,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": false},
				"MoveType": MOVE_TYPE.FLY
			},
		"Sakuya": {
				"CurLife": 1,
				"Profile": {
					"UnitName": "Sakuya",
					"Prt": "res://sprites/SakuyaPrt.png",
					"FullPrt":"res://sprites/character/sakuya/portrait_full.png",
					"Sprite": load(("res://sprites/SakuyaTest.png")),
					"Level": 1,
					"EXP": 0,
					"Role": "Maid",
					"Species": SPEC_ID.HUMAN,
					},
				"Stats": {
					"Move": 6,
					"Life": 19,
					"Comp": 100,
					"Pwr": 7,
					"Mag": 2,
					"Eleg": 7,
					"Cele": 8,
					"Def": 4,
					"Cha": 7
					},
				"Growths": {
					"Move": 0.02,
					"Life": 0.5,
					"Comp": 0,
					"Pwr": 0.3,
					"Mag": 0.2,
					"Eleg": 0.55,
					"Cele": 0.55,
					"Def": 0.2,
					"Cha": 0.7
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"SpawnGear":["SLVKNF","PWRELIX","DGR","TESTACC",],
				"Skills":["ST05","LockedCorpse"],
				"Passives":["NightPerson",],
				"Weapons": {
					"Blade": true,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": ["KNIVES"]},
				"MoveType": MOVE_TYPE.RANGER
			},
		"Patchouli": {
			"CurLife": 1,
				"Profile": {
					"UnitName": "Patchouli",
					"Prt": "res://sprites/PatchouliPrt.png",
					"FullPrt":"res://sprites/character/patchouli/portrait_full.png",
					"Sprite": load(("res://sprites/RemiliaTest.png")),
					"Level": 1,
					"EXP": 0,
					"Role": "Mage",
					"Species": SPEC_ID.MAGICIAN,
					},
				"Stats": {
					"Move": 4,
					"Life": 18,
					"Comp": 100,
					"Pwr": 2,
					"Mag": 7,
					"Eleg": 6,
					"Cele": 3,
					"Def": 1,
					"Cha": 6
					},
				"Growths": {
					"Move": 0.02,
					"Life": 0.5,
					"Comp": 0,
					"Pwr": 0.3,
					"Mag": 0.2,
					"Eleg": 0.55,
					"Cele": 0.55,
					"Def": 0.2,
					"Cha": 0.7
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"SpawnGear":["PZA",],
				"Skills":[],
				"Passives":[],
				"Weapons": {
					"Blade": false,
					"Blunt": false,
					"Stick": false,
					"Book": true,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": false},
				"MoveType": MOVE_TYPE.FOOT
			},
		"Meiling": {"CurLife": 1,
				"Profile": {
					"UnitName": "Meiling",
					"Prt": "res://sprites/MeilingPrt.png",
					"FullPrt":"res://sprites/character/meiling/portrait_full.png",
					"Sprite": load(("res://sprites/RemiliaTest.png")),
					"Level": 1,
					"EXP": 0,
					"Role": "Guard",
					"Species": SPEC_ID.DRAGON,
					},
				"Stats": {
					"Move": 4,
					"Life": 18,
					"Comp": 100,
					"Pwr": 5,
					"Mag": 2,
					"Eleg": 6,
					"Cele": 3,
					"Def": 6,
					"Cha": 4
					},
				"Growths": {
					"Move": 0.02,
					"Life": 0.5,
					"Comp": 0,
					"Pwr": 0.3,
					"Mag": 0.2,
					"Eleg": 0.55,
					"Cele": 0.55,
					"Def": 0.2,
					"Cha": 0.7
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"SpawnGear":[],
				"Passives":["Martial"],
				"Skills":["EnemyShove1", "EnemyToss1", "Rest"],
				"Weapons": {
					"Blade": false,
					"Blunt": true,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": ["NATURAL"]},
				"MoveType": MOVE_TYPE.FOOT
			},
		"Reimu": {
				"CurLife": 1,
				"Profile": {
					"UnitName": "Reimu",
					"Prt": "res://sprites/ReimuPrt.png",
					"FullPrt":"res://sprites/character/reimu/portrait_full.png",
					"Sprite": load(("res://sprites/SakuyaTest.png")),
					"Level": 1,
					"EXP": 0,
					"Role": "Miko",
					"Species": SPEC_ID.HUMAN,
					},
				"Stats": {
					"Move": 4,
					"Life": 19,
					"Comp": 100,
					"Pwr": 7,
					"Mag": 2,
					"Eleg": 7,
					"Cele": 8,
					"Def": 4,
					"Cha": 7
					},
				"Growths": {
					"Move": 0.02,
					"Life": 0.5,
					"Comp": 0,
					"Pwr": 0.3,
					"Mag": 0.2,
					"Eleg": 0.55,
					"Cele": 0.55,
					"Def": 0.2,
					"Cha": 0.7
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"SpawnGear":["SMPLGOHEI"],
				"Skills":["SlayFairy"],
				"Passives":["DodgeAura"],
				"Weapons": {
					"Blade": false,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": true,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": ["OFUDA"]},
				"MoveType": MOVE_TYPE.FOOT
			},
		"Cirno": {
				"CurLife": 1,
				"Profile": {
					"UnitName": "Cirno",
					"Prt": "res://sprites/character/cirno/cirno_prt.png",
					"FullPrt":"res://sprites/character/cirno/portrait_full.png",
					"Sprite": load(("res://sprites/SakuyaTest.png")),
					"Level": 4,
					"EXP": 0,
					"Role": "Bandit",
					"Species": SPEC_ID.FAIRY,
					},
				"Stats": {
					"Move": 4,
					"Life": 19,
					"Comp": 100,
					"Pwr": 7,
					"Mag": 2,
					"Eleg": 7,
					"Cele": 8,
					"Def": 4,
					"Cha": 7
					},
				"Growths": {
					"Move": 0.02,
					"Life": 0.5,
					"Comp": 0,
					"Pwr": 0.3,
					"Mag": 0.2,
					"Eleg": 0.55,
					"Cele": 0.55,
					"Def": 0.2,
					"Cha": 0.7
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"Skills":[],
				"Passives":[],
				"Weapons": {
					"Blade": false,
					"Blunt": true,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": false},
				"MoveType": MOVE_TYPE.FLY
			}
		}
	return units

static func get_spec(specInd):
	match specInd:
		SPEC_ID.FAIRY: 
			return {
			"Spec": SPEC_ID.FAIRY,
			"StatGroups":{
				"Stats": {
					"Move": 4,
					"Life": 0,
					"Comp": 100,
					"Pwr": 0,
					"Mag": 1,
					"Eleg": 0,
					"Cele": 2,
					"Def": 0,
					"Cha": 2
					},
				"Growths": {
					"Move": 0,
					"Life": 0.0,
					"Comp": 0,
					"Pwr": 0.0,
					"Mag": 0.1,
					"Eleg": 0.0,
					"Cele": 0.1,
					"Def": 0.0,
					"Cha": 0.1
					},
				"Caps": {
					"Move": 0,
					"Life": 0,
					"Comp": 0,
					"Pwr": 0,
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0
					}
					},
			"Passives":[],
			"Skills":[],
			"MoveType": MOVE_TYPE.FLY
				}
		SPEC_ID.YOUKAI:
			return {
			"Spec": SPEC_ID.YOUKAI,
			"StatGroups":{
				"Stats": {
					"Move": 4,
					"Life": 0,
					"Comp": 100,
					"Pwr": 1,
					"Mag": 0,
					"Eleg": 1,
					"Cele": 0,
					"Def": 1,
					"Cha": 1
					},
				"Growths": {
					"Move": 0,
					"Life": 0.0,
					"Comp": 0,
					"Pwr": 0.1,
					"Mag": 0.1,
					"Eleg": 0.1,
					"Cele": 0.0,
					"Def": 0.0,
					"Cha": 0.0
					},
				"Caps": {
					"Move": 0,
					"Life": 0,
					"Comp": 0,
					"Pwr": 0,
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0
					}
					},
			"Passives":[],
			"Skills":[],
			"MoveType": MOVE_TYPE.FOOT
				}
		SPEC_ID.HUMAN:
			return {
			"Spec": SPEC_ID.HUMAN,
			"StatGroups":{
				"Stats": {
					"Move": 4,
					"Life": 0,
					"Comp": 100,
					"Pwr": 0,
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 0
					},
				"Growths": {
					"Move": 0,
					"Life": 0.1,
					"Comp": 0.0,
					"Pwr": 0.1,
					"Mag": 0.0,
					"Eleg": 0.1,
					"Cele": 0.1,
					"Def": 0.0,
					"Cha": 0.3
					},
				"Caps": {
					"Move": 0,
					"Life": 0,
					"Comp": 0,
					"Pwr": 0,
					"Mag": 0,
					"Eleg": 0,
					"Cele": 0,
					"Def": 0,
					"Cha": 2
					}
					},
			"Passives":[],
			"Skills":[],
			"MoveType": MOVE_TYPE.FOOT
				}
	
static func get_job(jobInd):
	match jobInd:
		JOB_ID.TRBLR: 
			return {
			"Role": "Troublemaker",
			"StatGroups":{
				"Stats": {
					"Move": 0, #Unintuitive handling of move. Race should give bonus, not job
					"Life": 20,
					"Comp": 10,
					"Pwr": 6,
					"Mag": 0,
					"Eleg": 4,
					"Cele": 2,
					"Def": 4,
					"Cha": 0
					},
				"Growths": {
					"Move": 0,
					"Life": 0.4,
					"Comp": 0.3,
					"Pwr": 0.3,
					"Mag": -0.1,
					"Eleg": 0.2,
					"Cele": 0.0,
					"Def": 0.2,
					"Cha": 0.0
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					}
					},
				"Passives":[],
				"Skills":[],
				"Weapons": {
					"Blade": false,
					"Blunt": true,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": [],
				}
				}
		JOB_ID.THIEF: return {
			"Role": "Cointaker",
			"StatGroups":{
				"Stats": {
					"Move": 1,
					"Life": 14,
					"Comp": 10,
					"Pwr": 4,
					"Mag": 0,
					"Eleg": 4,
					"Cele": 5,
					"Def": 0,
					"Cha": 0
					},
				"Growths": {
					"Move": 0,
					"Life": 0.4,
					"Comp": 0.3,
					"Pwr": 0.3,
					"Mag": -0.1,
					"Eleg": 0.2,
					"Cele": 0.45,
					"Def": 0.2,
					"Cha": 0.0
					},
				"Caps": {
					"Move": 10,
					"Life": 20,
					"Comp": 20,
					"Pwr": 20,
					"Mag": 20,
					"Eleg": 20,
					"Cele": 20,
					"Def": 20,
					"Cha": 20
					}
					},
				"Passives":[],
				"Skills":[],
				"Weapons": {
					"Blade": true,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": ["KNIVES"],
					}
				}

static func get_art(unit):
	#"Prt":load(("res://sprites/character/%s/Prt.png" % [unit])),
	var p = {
		"Prt":("res://sprites/%sPrt.png" % [unit]),
		"FullPrt":("res://sprites/character/%s/FullPrt.png" % [unit])
		}
	return p
	
static func load_generated_sprite(species, job):
	var specKeys : Array = SPEC_ID.keys()
	var specPath : String = specKeys[species]
	var jobKeys : Array = JOB_ID.keys()
	var jobPath : String = jobKeys[job]
	var s = load(("res://sprites/%s/%sSpr.png" % [specPath, jobPath]))
	return s
	
	
static func get_terrain_data():
	var terrainData : Dictionary = {
			"Flat":{
				},
			"Ground":{
				"GrzBonus": 3,
				"DefBonus": 0,
				},
			"River":{
				"GrzBonus": 10,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 3,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 2,
				},
			"Water":{
				"GrzBonus": 20,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 5,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 5,
				},
			"Sanzu":{
				"GrzBonus": 20,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 5,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 5,
				},
			"HotSpring":{
				"GrzBonus": 0,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 1,
				},
			"Rough":{
				"GrzBonus": 5,
				"DefBonus": 1,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 0.5,
				},
			"OpenRough":{
				"GrzBonus": -3,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 0.5,
				},
			"HellSand":{
				"GrzBonus": 3,
				"DefBonus": 1,
				Enums.MOVE_TYPE.FOOT: 2,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 2,
				},
			"Fort":{
				"GrzBonus": 20,
				"DefBonus": 3,
				Enums.MOVE_TYPE.FOOT: 2,
				Enums.MOVE_TYPE.FLY: 1,
				Enums.MOVE_TYPE.RANGER: 2,
			},
			"Bridge":{
				"GrzBonus": -5,
				"DefBonus": 0,
			},
			"Hill":{
				"GrzBonus": 10,
				"HitBonus": 10,
				Enums.MOVE_TYPE.FOOT: 2,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 1,
				},
			"Woodland":{
				"GrzBonus": 15,
				"DefBonus": 1,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 0.5,
				},
			"House":{
				"GrzBonus": 10,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 1,
				},
			"Shrine":{
				"GrzBonus": 10,
				"MagBonus": 1,
				"HpRegen": 5,
				"Price": -100,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 1,
				},
			"Shop":{
				"GrzBonus": 10,
				"DefBonus": 0,
				Enums.MOVE_TYPE.FOOT: 1,
				Enums.MOVE_TYPE.FLY: 0,
				Enums.MOVE_TYPE.RANGER: 1,
				},
			"Wall":{
				Enums.MOVE_TYPE.FOOT: 99,
				Enums.MOVE_TYPE.FLY: 99,
				Enums.MOVE_TYPE.RANGER: 99,
				},
			"WallShoot":{
				Enums.MOVE_TYPE.FOOT: 99,
				Enums.MOVE_TYPE.FLY: 99,
				Enums.MOVE_TYPE.RANGER: 99,
				},
			"WallFly":{
				Enums.MOVE_TYPE.FOOT: 99,
				Enums.MOVE_TYPE.FLY: 1,
				Enums.MOVE_TYPE.RANGER: 99,
				},
}
	return terrainData


static func get_items():
	var iData = {"NONE":{
				"Name":"--",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 0,
				"Hit": 0,
				"Crit": 0,
				"Barrier": 0,
				"MinRange": 0,
				"MaxRange": 0,
				"Category": "NONE",
				"MaxDur": -1,
				"Equip":true,
				"SubGroup": false,
				},
				## Weapons
				"GNG":{
				"Name":"Gungnir",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": -1,
				"Dmg": 15,
				"Hit": 85,
				"Crit": 10,
				"Barrier": 3,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Stick",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"SLVKNF":{
				"Name":"Silver Knife",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 24,
				"Hit": 90,
				"Crit": 0,
				"Barrier": 2,
				"MinRange": 1,
				"MaxRange": 2,
				"Category": "Blade",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": "KNIVES",
				},
				
				"CLB": {
				"Name":"Club",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 7,
				"Hit": 60,
				"Crit": 0,
				"Barrier": 4,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Blunt",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"DGR": {
				"Name":"Dagger",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 4,
				"Hit": 85,
				"Crit": 0,
				"Barrier": 1,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Blade",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"THKN":{
				"Name":"Throwing Knife",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 3,
				"Hit": 0,
				"Crit": 5,
				"Barrier": 1,
				"MinRange": 2,
				"MaxRange": 2,
				"Category": "Blade",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": "KNIVES",
				},
				
				"BK":{
				"Name":"Book",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 1,
				"Hit": 70,
				"Crit": 0,
				"Barrier": 0,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Book",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				"Effects":["GrantFire1"],
				},
				
				"NaturalMartial":{
				"Name": "PUNCH",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": -1,
				"Dmg": 0,
				"Hit": 0,
				"Crit": 0,
				"Barrier": 0,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "",
				"MaxDur": -1,
				"Expendable": false,
				"Equip": true,
				"Trade": false,
				"SubGroup": "NATURAL",
				"Effects": ["MultiStrike2"],
				},
				
				"SMPLGOHEI": {
				"Name":"Simple Gohei",
				"Icon": "res://sprites/gungnir.png",
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Level": 1,
				"Dmg": 5,
				"Hit": 70,
				"Crit": 5,
				"Barrier": 4,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Gohei",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				## Consumables
				"PZA":{
				"Name":"Pizza",
				"Icon": "res://sprites/gungnir.png",
				"Category": "ITEM",
				"MaxDur": 3,
				"Use": true,
				"Effects": ["Pizza01"] },
				
				"PWRELIX":{
				"Name":"Power Elixir",
				"Icon": "res://sprites/gungnir.png",
				"Category": "ITEM",
				"MaxDur": 1,
				"Use": true,
				"Effects": ["PwrBuff01"] },
				## Accessories
				"TESTACC":{
				"Name": "STR Ring",
				"Icon": "res://sprites/gungnir.png",
				"Category": "ACC",
				"Equip": true,
				"Effects": ["PwrAcc01"] },
				
				
				}
	return iData
	
	
static func get_effects():
	var skillEffects : Dictionary
	skillEffects = {
			"ChaHit":{
				"Type": Enums.EFFECT_TYPE.BUFF,
				"SubType": Enums.SUB_TYPE.HIT, 
				"Target": Enums.EFFECT_TARGET.EQUIPPED, 
				"Value": 10,
			},
			"Ter":{
				"Type": Enums.EFFECT_TYPE.DEBUFF,
				"SubType": Enums.SUB_TYPE.GRAZE, 
				"Target": Enums.EFFECT_TARGET.EQUIPPED, 
				"Value": -10,
			},
			"Thirst50":{
				"Type": Enums.EFFECT_TYPE.LIFE_STEAL,
				"Target": Enums.EFFECT_TARGET.SELF, 
				"OnHit": true, 
				"Value": 0.5, 
			},
			"MultiStrike2":{
				"Type": Enums.EFFECT_TYPE.MULTI_SWING,
				"Target": Enums.EFFECT_TARGET.EQUIPPED,
				"Value": 2,
			},
			"Shove1":{
				"Type": Enums.EFFECT_TYPE.RELOC,
				"SubType": Enums.SUB_TYPE.SHOVE,
				"Target": Enums.EFFECT_TARGET.TARGET,
				"Value": 1,
				"Hostile": true,
			},
			"Toss1":{
				"Type": Enums.EFFECT_TYPE.RELOC,
				"SubType": Enums.SUB_TYPE.TOSS, 
				"Target": Enums.EFFECT_TARGET.TARGET,
				"Hostile": true,
			},
			"SelfSleep" :{
				"Type": Enums.EFFECT_TYPE.STATUS,
				"SubType": Enums.SUB_TYPE.SLEEP, #Use Enums.SUB_TYPE. For Damage, use Damage Enums. Just how it's gotta be.
				"Target": Enums.EFFECT_TARGET.SELF,
				"Duration": 2, #Unit turns the effect lasts, -1 causes the effect to be permanent. Duration is ignored entirely for on-equip effects of items.
				"DurationType": Enums.DURATION_TYPE.TURN,
			},
			"Heal2" :{
				"Type": Enums.EFFECT_TYPE.HEAL,
				"Target": Enums.EFFECT_TARGET.SELF,
				"Value": 2, 
			},
			"Graze5":{
				"Type": Enums.EFFECT_TYPE.BUFF,
				"SubType": Enums.SUB_TYPE.GRAZE, 
				"Target": Enums.EFFECT_TARGET.EQUIPPED,
				"Stack": true, 
				"Value": 5,
			},
			"FairySlayer":{
				"Type": Enums.EFFECT_TYPE.SLAYER,
				"SubType": false, 
				"Instant": true,
				"Target": Enums.EFFECT_TARGET.TARGET,
				"RuleType": Enums.RULE_TYPE.TARGET_SPEC,
				"Rule": Enums.SPEC_ID.FAIRY,
			},
			"Buff":{
				"Type": Enums.EFFECT_TYPE.BUFF,
				"SubType": Enums.SUB_TYPE.GRAZE, 
				"Target": Enums.EFFECT_TARGET.SELF,
				"Value": 5,
				"Duration": 2,
				"Stack": true,
				"DurationType": Enums.DURATION_TYPE.TURN,
			},
			"DebuffMove04":{
				"Type": Enums.EFFECT_TYPE.DEBUFF,
				"SubType": Enums.SUB_TYPE.MOVE, 
				"Target": Enums.EFFECT_TARGET.TARGET,
				"Value": -4,
				"Duration": 1,
				"Stack": false,
				"DurationType": Enums.DURATION_TYPE.TURN,
			},
			"SlowTime05": {
				"Type": Enums.EFFECT_TYPE.TIME,
				"SubType": Enums.SUB_TYPE.SLOW_DOWN,
				"Target": Enums.EFFECT_TARGET.GLOBAL,
				"OnHit": false,
				"Proc": -1,
				"Duration": 2,
				"DurationType": Enums.DURATION_TYPE.ROUND,
				"Value": 0.5
			},
			"Pizza01": {
				"Type": Enums.EFFECT_TYPE.HEAL,
				"Target": Enums.EFFECT_TARGET.SELF,
				"Value": 8, 
			},
			"PwrBuff01":{
				"Type": Enums.EFFECT_TYPE.BUFF,
				"SubType": Enums.SUB_TYPE.PWR, 
				"Target": Enums.EFFECT_TARGET.SELF,
				"DurationType": Enums.DURATION_TYPE.PERMANENT,
				"Stack": true, 
				"Value": 1,
			},
			"PwrAcc01":{
				"Type": Enums.EFFECT_TYPE.BUFF,
				"SubType": Enums.SUB_TYPE.PWR, 
				"Target": Enums.EFFECT_TARGET.EQUIPPED,
				"Stack": true, 
				"Value": 1,
			},
			"GrantFire1":{
				"Type": Enums.EFFECT_TYPE.ADD_SKILL,
				"SubType": false, #Use Enums.SUB_TYPE. For Damage, use Damage Enums. Just how it's gotta be.
				"Target": Enums.EFFECT_TARGET.EQUIPPED, #Self, Target, Global, Equipped
				#effect: Reloc
				"Hostile": false, #If movement should be treated as "hostile"
				"Skill": "FireBasic", #Not used yet. Temporarily adds skills via on-equip effects
			}
	}
	return skillEffects
	
static func get_skills():
	var skills : Dictionary
	skills = {
		"LifeStealRem":{
			"SkillName": "Scarlet Thirst",
			"Icon": "res://sprites/icons/features/camp_skill_danmaku_mg.png",
			"Augment": true, #Set true if weapon stats should be used instead.
			##Only if Augment
			"WepCat": Enums.WEAPON_CATEGORY.STICK, #Set to required weapon category, or sub type, for skill use.
			##If !augment, these are the parameters used as if it was a weapon. If Augment, these values are added as bonus/penalty if altered.
			"Hit": 15, #Int only. negative values acceptable for Hit penalties to the skill
			"Dmg": 0, #set an int value for damage
			"Crit": 0, #set an int value for crit bonus
			"Type": false, #use enum types. Set False if augment should use weapon's type.
			##Used regardless of Augment
			"Cost": 15,
			"Effects": ["Thirst50"], #any attacking effects for an augment skill must be set to instant.
			"RuleType": Enums.RULE_TYPE.TIME,
			"Rule": Enums.TIME.NIGHT,
		},
		"EnemyShove1":{
			"SkillName": "Shove",
			"Icon": "res://sprites/icons/features/yuugi.ability.one.png",
			"CanCrit": false,
			"CanDmg": false,
			"Hit": 95,
			"Cost": 4,
			"Effects": ["Shove1"], 
		},
		"EnemyToss1":{
			"SkillName": "Toss",
			"Icon": "res://sprites/icons/features/yuugi.ability.five.png",
			"Target": "Enemy",
			"CanCrit": false,
			"Hit": 65,
			"Dmg": 5,
			"Cost": 5,
			"Effects": ["Toss1"], 
		},
		"Rest": {
			"SkillName": "Rest",
			"Icon": "res://sprites/icons/features/yuugi.ability.two.png",
			"Target": "Self",
			"CanMiss": false, 
			"CanCrit": false,
			"CanDmg": false,
			##Used regardless of Augment
			"MinRange": 0, #if 0, ignored by Augment. Set value to require specific weapon reach.
			"MaxRange": 0,
			"Cost": 0,
			"Effects": ["SelfSleep","Heal2"], #any attacking effects for an augment skill must be set to instant.
		},
		"SlayFairy": {
			"SkillName": "Fairy Slayer",
			"Icon": "res://sprites/icons/features/miko.ability.four.png",
			"Category": "Augment",
			"Augment": true,
			"Type": false,
			"Cost": 5,
			"Effects": ["FairySlayer"], #any attacking effects for an augment skill must be set to instant.
			#"RuleType": Enums.RULE_TYPE.TARGET_SPEC,
			#"Rule": Enums.SPEC_ID.FAIRY,
		},
		"FireBasic": {
			"SkillName": "Fire Ball",
			"Icon": "res://sprites/icons/features/camp_skill_bomb_brew_mg.png",
			"Augment": false,
			"Type": Enums.DAMAGE_TYPE.MAG,
			"Hit": 70,
			"Dmg": 6,
			"MinRange": 1, #if 0, ignored by Augment. Set value to require specific weapon reach.
			"MaxRange": 2,
			"Cost": 3,
			"Effects": ["Buff"], #any attacking effects for an augment skill must be set to instant.
			
		},
		"ST05": {
			"SkillId": "ST05",
			"SkillName": "Slow Time",
			"Category": "Time",
			"Icon": "res://sprites/icons/features/camp_skill_luna_dial.png",
			"Target": "Self", #Enemy, Self, Ally
			"CanMiss": true,
			"Hit": 0,
			"MinRange": 0,
			"MaxRange": 0,
			"Cost": 10,
			"Effects": ["SlowTime05"]
		},
		"LockedCorpse": {
		"SkillId": "LockedCorpse",
		"SkillName": "Locked Corpse",
		"Category": "Sabotage",
		"Icon": "res://sprites/icons/features/maid.ability.six.png",
		"Target": "Enemy", #Enemy, Self, Ally
		"CanMiss": false,
		"Hit": 100,
		"MinRange": 1,
		"MaxRange": 3,
		"Cost": 20,
		"Effects": ["DebuffMove04"]
		}
	}
	return skills

static func get_passives():
	var passives = {
		"RemAura":{
			"Type": Enums.PASSIVE_TYPE.AURA,
			"NameDay":"Charisma",
			"NameNight":"Terror",
			"IconDay": "res://sprites/icons/features/magician.ability.four.png",
			"IconNight": "res://sprites/icons/features/maid.ability.four.png",
			"RuleType": Enums.RULE_TYPE.MORPH,
			"IsTimeSens": true,
			"Day": "Charisma",
			"Night": "Terror",
		},
		"Fated":{
			"Type": Enums.PASSIVE_TYPE.FATED,
			"Name":"Fated",
			"Icon": "res://sprites/icons/features/maid.ability.two.png",
			"Value": 10
		},
		"Martial":{
			"Type": Enums.PASSIVE_TYPE.SUB_WEAPON,
			"Name":"Unarmed Strike",
			"SubType": Enums.WEAPON_CATEGORY.NATURAL,
			"Icon": "res://sprites/icons/features/yuugi.ability.five.png",
			"String": "NaturalMartial",
		},
		"DodgeAura":{
			"Type": Enums.PASSIVE_TYPE.AURA,
			"Name":"Plot Armor",
			"Icon": "res://sprites/icons/features/miko.ability.six.png",
			"Aura": "AdjAvd",
		},
		"NightPerson":{
			"Type": Enums.PASSIVE_TYPE.NIGHT_PROT,
			"Name":"Night Owl",
			"Icon": "res://sprites/icons/features/maid.ability.five.png",
			"RuleType": Enums.RULE_TYPE.SELF_SPEC,
			"Rule": Enums.SPEC_ID.HUMAN,
		},
	}
	return passives
	
static func get_auras():
	var auras = {
		"Charisma":{
			"Range": 2,
			"Effects":["ChaHit"]
		},
		"Terror":{
			"Range": 2,
			"TargetTeam": Enums.TARGET_TEAM.ENEMY,
			"Effects":["Ter"],
		},
		"AdjAvd":{
			"Range": 1,
			"TargetTeam": Enums.TARGET_TEAM.ENEMY,
			"Target": Enums.EFFECT_TARGET.SELF,
			"Effects":["Graze5"],
		}
	}
	return auras

static func get_time_mods():
	var timeMods = {
		SPEC_ID.VAMPIRE:{
						Enums.TIME.DAY:{
							"Move": -1,
							"Life": 0,
							"Comp": 0,
							"Pwr": -2,
							"Mag": -2,
							"Eleg": 0,
							"Cele": 0,
							"Def": -2,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
							"MoveType": Enums.MOVE_TYPE.FOOT,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
							"MoveType": Enums.MOVE_TYPE.FLY,
						}
		},
		Enums.SPEC_ID.HUMAN:{
						Enums.TIME.DAY:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						}
		},
		Enums.SPEC_ID.DRAGON:{
						Enums.TIME.DAY:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						}
		},
		Enums.SPEC_ID.MAGICIAN:{
						Enums.TIME.DAY:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						}
		},
		Enums.SPEC_ID.FAIRY:{
						Enums.TIME.DAY:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						}
		},
		Enums.SPEC_ID.YOUKAI:{
						Enums.TIME.DAY:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Def": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"": 0, 
							"Barrier": 0, 
							"BarPrc": 0, 
							"Crit": 0, 
							"Luck": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"DRes": 0,
						}
		},
	}
	return timeMods
