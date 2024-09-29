
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
					"Prt": load(("res://sprites/RemiliaPrt.png")),
					"Sprite": load(("res://sprites/RemiliaTest.png")),
					"Level": 1,
					"EXP": 0,
					"Role": "Lady",
					"Species": SPEC_ID.VAMPIRE,
					},
				"Stats": {
					"Move": 4,
					"Life": 22,
					"Comp": 100,
					"Pwr": 15,
					"Mag": 6,
					"Eleg": 6,
					"Cele": 6,
					"Bar": 5,
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
					"Bar": 0.2,
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
					"Bar": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[{"ID":"GNG", "Equip":true, "DUR":40, }],
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
					"Prt": load(("res://sprites/SakuyaPrt.png")),
					"Sprite": load(("res://sprites/SakuyaTest.png")),
					"Level": 1,
					"EXP": 0,
					"Role": "Maid",
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
					"Bar": 4,
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
					"Bar": 0.2,
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
					"Bar": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[{"ID":"SLVKNF", "Equip":true, "DUR":40,}, {"ID":"PWRELIX", "Equip":false, "DUR":1,}, {"ID":"DGR", "Equip":false, "DUR": 30, }, {"ID":"TESTACC", "Equip":false, "DUR": -1, }],
				
				"Skills":["ST05", "AttackTest1"],
				"Passives":[],
				"Weapons": {
					"Blade": true,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": ["KNIFE"]},
				"MoveType": MOVE_TYPE.RANGER
			},
		"Patchouli": {
			"CurLife": 1,
				"Profile": {
					"UnitName": "Patchouli",
					"Prt": load(("res://sprites/PatchouliPrt.png")),
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
					"Bar": 1,
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
					"Bar": 0.2,
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
					"Bar": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[{"ID":"BK", "Equip":true, "DUR":40, }, {"ID":"PZA", "Equip":false, "DUR":3, }],
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
					"Prt": load(("res://sprites/MeilingPrt.png")),
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
					"Bar": 6,
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
					"Bar": 0.2,
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
					"Bar": 20,
					"Cha": 20
					},
				"MaxInv": 6,
				"Inv":[],
				"Passives":["Martial"],
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
					"Sub": ["NATURAL"]},
				"MoveType": MOVE_TYPE.FOOT
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
					"Bar": 0,
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
					"Bar": 0.0,
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
					"Bar": 0,
					"Cha": 0
					}
					},
			"Passives":[],
			"MoveType": MOVE_TYPE.FLY
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
					"Bar": 4,
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
					"Bar": 0.2,
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
					"Bar": 20,
					"Cha": 20
					}
					},
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
					"Bar": 0,
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
					"Bar": 0.2,
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
					"Bar": 20,
					"Cha": 20
					}
					},
				"Passives":[],
				"Weapons": {
					"Blade": true,
					"Blunt": false,
					"Stick": false,
					"Book": false,
					"Gohei": false,
					"Fan": false,
					"Bow": false,
					"Gun": false,
					"Sub": ["KNIFE"],
					}
				}

static func get_art(prtName):
	
	var p = {"Prt":load(("res://sprites/%sPrt.png" % [prtName]))}
	return p
	
static func load_generated_sprite(species, job):
	var specKeys : Array = SPEC_ID.keys()
	var specPath : String = specKeys[species]
	var jobKeys : Array = JOB_ID.keys()
	var jobPath : String = jobKeys[job]
	var s = load(("res://sprites/%s/%sSpr.png" % [specPath, jobPath]))
	return s

static func get_terrain_costs():
	var terrainCost : Dictionary = {
		Enums.MOVE_TYPE.FOOT: {
			"Flat": 1,
			"Fort": 2,
			"Hill": 3
			},
		Enums.MOVE_TYPE.FLY:{
			"Flat": 1,
			"Fort": 1,
			"Hill": 1
			},
		Enums.MOVE_TYPE.RANGER:{
			"Flat": 1,
			"Fort": 2,
			"Hill": 2
		}
}
	return terrainCost
	
static func get_items():
	var iData = {"NONE":{
				"Name":"--",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 0,
				"Hit": 0,
				"Crit": 0,
				"Graze": 0,
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
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 5,
				"Hit": 85,
				"Crit": 10,
				"Graze": 3,
				"MinRange": 1,
				"MaxRange": 2,
				"Category": "Stick",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"SLVKNF":{
				"Name":"Silver Knife",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 4,
				"Hit": 90,
				"Crit": 0,
				"Graze": 2,
				"MinRange": 1,
				"MaxRange": 2,
				"Category": "Blade",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": "KNIVES",
				},
				
				"CLB": {
				"Name":"Club",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 7,
				"Hit": 60,
				"Crit": 0,
				"Graze": 4,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Blunt",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"DGR": {
				"Name":"Dagger",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 4,
				"Hit": 85,
				"Crit": 0,
				"Graze": 1,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Blade",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"THKN":{
				"Name":"Throwing Knife",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 3,
				"Hit": 0,
				"Crit": 5,
				"Graze": 1,
				"MinRange": 2,
				"MaxRange": 2,
				"Category": "Blade",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": "KNIVES",
				},
				
				"BK":{
				"Name":"Book",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 1,
				"Hit": 70,
				"Crit": 0,
				"Graze": 0,
				"MinRange": 1,
				"MaxRange": 1,
				"Category": "Book",
				"MaxDur": 40,
				"Equip":true,
				"SubGroup": false,
				},
				
				"NaturalMartial":{
				"Name": "PUNCH",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 0,
				"Hit": 0,
				"Crit": 0,
				"Graze": 0,
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
				
				## Consumables
				"PZA":{
				"Name":"Pizza",
				"Icon": load(("res://sprites/gungnir.png")),
				"Category": "ITEM",
				"MaxDur": 3,
				"USE": true,
				"Effects": ["Pizza01"] },
				
				"PWRELIX":{
				"Name":"Power Elixir",
				"Icon": load(("res://sprites/gungnir.png")),
				"Category": "ITEM",
				"MaxDur": 1,
				"USE": true,
				"Effects": ["StrBuff01"] },
				## Accessories
				"TESTACC":{
				"Name": "STR Ring",
				"Icon": load(("res://sprites/gungnir.png")),
				"Category": "ACC",
				"Equip": true,
				"Effects": ["StrBuff01"] },
				
				
				}
	return iData
	
	
static func get_effects():
	var skillEffects : Dictionary
	skillEffects = {
			"Test1": {
				"Target": "Target",
				"OnHit": true,
				"Proc": -1,
				"Dmg": 5,
				"Type": Enums.DAMAGE_TYPE.PHYS
			},
			"ChaHit":{
				"Type": Enums.EFFECT_TYPE.BUFF,
				"SubType": Enums.SUB_TYPE.HIT, 
				"Target": Enums.EFFECT_TARGET.EQUIPPED, 
				"Value": 10,
			},
			"TerAvoid":{
				"Type": Enums.EFFECT_TYPE.DEBUFF,
				"SubType": Enums.SUB_TYPE.AVOID, 
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
			"Test2": {
			"Target": "Target",
			"OnHit": false,
			"Proc": -1,
			"Heal": 2
			},
			"SlowTime05": {
			"Target": "Global",
			"OnHit": false,
			"Proc": -1,
			"Duration": 2,
			"Time": true,
			"Value": -0.5
			},
			"SleepTest": {
			"Type": Enums.EFFECT_TYPE.STATUS,
			"Proc": 60,
			"Duration": 1, 
			"SubType": Enums.SUB_TYPE.SLEEP,
			"Curable": true, 
			},
			"Shove1": {
			"Target": "Target", #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": -1, #Set to -1 to have gaurenteed proc chance
			"Relocate": true,
			"MoveType": "Shove", #Warp(pick a hex), Shove(moved X distance); Toss(Placed behind Actor)
			"RelocRange": 2 #Distance Shoved, or range of valid tiles to warp to. Set to 0 for Toss.
			},
			"Toss1": {
			"Target": "Target", #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": -1, #Set to -1 to have gaurenteed proc chance
			"Relocate": true,
			"MoveType": "Toss", #Warp(pick a hex), Shove(moved X distance); Toss(Placed behind Actor)
			"RelocRange": 0 #Distance Shoved, or range of valid tiles to warp to. Set to 0 for Toss.
			},
			"Warp05": {
			"Target": "Target", #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": -1, #Set to -1 to have gaurenteed proc chance
			"Relocate": true,
			"MoveType": "Warp", #Warp(pick a hex), Shove(moved X distance); Toss(Placed behind Actor)
			"RelocRange": 5 #Distance Shoved, or range of valid tiles to warp to. Set to 0 for Toss.
			},
			"Pizza01": {
			"Target": "Self",
			"OnHit": false,
			"Proc": -1,
			"Heal": 2
			}
	}
	return skillEffects
static func get_skills():
	var skills : Dictionary
	skills = {
		"LifeStealRem":{
			"SkillName": "Scarlet Thirst",
			"Icon": load(("res://sprites/gungnir.png")),
			"Augment": true, #Set true if weapon stats should be used instead.
			"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)
			"TrueHit": false, #default true
			##Only if Augment
			"WepCat": Enums.WEAPON_CATEGORY.STICK, #Set to required weapon category, or sub type, for skill use.
			"BonusMinRange": 0,
			"BonusMaxRange": 0,
			##If !augment, these are the parameters used as if it was a weapon. If Augment, these values are added as bonus/penalty if altered.
			"Hit": 15, #Int only. negative values acceptable for Hit penalties to the skill
			"Dmg": 0, #set an int value for damage
			"Crit": 0, #set an int value for crit bonus
			"Type": Enums.DAMAGE_TYPE.PHYS, #use enum types. Set False if augment should use weapon's type.
			##Used regardless of Augment
			"RangeMin": 1, #if 0, ignored by Augment. Set value to require specific weapon range.
			"RangeMax": 1,
			"Cost": 15,
			"Effects": ["Thirst50"], #any attacking effects for an augment skill must be set to instant.
			"RuleType": Enums.RULE_TYPE.TIME,
			"Rule": Enums.TIME.NIGHT,
			
		},
		"ST05": {
		"SkillId": "ST05",
		"SkillName": "Slow Time",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Self", #Enemy, Self, Ally
		"TrueHit": false,
		"Hit": 0,
		"RangeMin": 0,
		"RangeMax": 0,
		"Cost": 0,
		"Effects": ["SlowTime05"]
		},
		"SLP1": {
		"SkillId": "SLP1",
		"SkillName": "Sleep",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally
		"TrueHit": false,
		"Hit": 60,
		"RangeMin": 1,
		"RangeMax": 2,
		"Cost": 0,
		"Effects": ["SleepTest"]
		},
		"SHV1": {
		"SkillId": "SHV1",
		"SkillName": "Shove",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally
		"TrueHit": false,
		"Hit": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"Effects": ["Shove1"]
		},
		"TOSS1": {
		"SkillId": "TOSS1",
		"SkillName": "Toss",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally
		"TrueHit": false,
		"Hit": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"Effects": ["Toss1"]
		},
		"WARP1": {
		"SkillId": "WARP1",
		"SkillName": "Warp Other",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Ally", #Enemy, Self, Ally
		"TrueHit": false,
		"Hit": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"Effects": ["Warp05"]
		},
		"AttackTest1": {
		"SkillName": "Attack_Test",
		"Icon": load(("res://sprites/gungnir.png")),
		##Ignored if Augment
		"Hit": 100, #Int only. negative values acceptable for Hit penalties to the skill
		"Dmg": 60, #set an int value for damage
		"Crit": false, #set an int value for crit bonus
		"Type": Enums.DAMAGE_TYPE.PHYS, #use enum types
		"RangeMin": 1,
		"RangeMax": 1,
		}
	}
	return skills

static func get_passives():
	var passives = {
		"RemAura":{
			"Type": Enums.PASSIVE_TYPE.AURA,
			"Icon": load(("res://sprites/gungnir.png")),
			"IsTimeSens": true,
			Enums.TIME.DAY: "Charisma",
			Enums.TIME.NIGHT: "Terror",
		},
		"Fated":{
			"Type": Enums.PASSIVE_TYPE.FATED,
			"Icon": load(("res://sprites/gungnir.png")),
			"Value": 10
		},
		"Martial":{
			"Type": Enums.PASSIVE_TYPE.SUB_WEAPON,
			"SubType": Enums.WEAPON_CATEGORY.NATURAL,
			"Icon": load(("res://sprites/gungnir.png")),
			"String": "NaturalMartial",
		}
	}
	return passives
	
static func get_auras():
	var auras = {
		"Charisma":{
			"Range": 2,
			"Effects":["ChaHit"]
		},
		"Terror":{
			"Range":2,
			"IsFriendly": false,
			"Effects":["TerAvoid"],
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
							"Bar": -2,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
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
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
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
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
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
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
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
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
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
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
						},
						Enums.TIME.NIGHT:{
							"Move": 0,
							"Life": 0,
							"Comp": 0,
							"Pwr": 0,
							"Mag": 0,
							"Eleg": 0,
							"Cele": 0,
							"Bar": 0,
							"Cha": 0,
							"Dmg": 0, 
							"Hit": 0, 
							"Avoid": 0, 
							"Graze": 0, 
							"GrzPrc": 0, 
							"Crit": 0, 
							"CrtAvd": 0, 
							"Resist": 0, 
							"EffHit":0, 
							"Def": 0,
						}
		},
	
		
		
	}
	return timeMods
