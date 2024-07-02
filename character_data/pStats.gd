
enum UNIT_ID {Remilia, Sakuya, Patchy, China}

#these three are used in combination to create the data on a single enemy unit.

enum SPEC_ID {Fairy}
#, Human, Kappa, Lunarian, Oni, Doll, Devil, Yukionna, Zombie, Hermit, Magician, Spirit
enum JOB_ID {Trblr}

enum WEP_ID {Spear, Knife}


static func get_named_unit_data(unitInd):
	var unitData
	match unitInd:
		UNIT_ID.Remilia: 
			unitData = {"Remilia": {"CLIFE": 1,
				"Profile": {
					"UnitName": "Remilia Scarlet",
					"Prt": load(("res://sprites/RemiliaPrt.png")),
					"Sprite": load(("res://sprites/RemiliaTest.png")),
					"Level": 1,
					"EXP": 0,
					"CurCOMP": 0,
					"Class": "Lady"
					},
				"Stats": {
					"MOVE": 4,
					"LIFE": 22,
					"COMP": 100,
					"PWR": 15,
					"MAG": 6,
					"ELEG": 6,
					"CELE": 6,
					"BAR": 5,
					"CHA": 8
					},
				"Growths": {
					"MOVE": 0,
					"LIFE": 1,
					"COMP": 0,
					"PWR": 1,
					"MAG": 1,
					"ELEG": 0.4,
					"CELE": 0.4,
					"BAR": 0.2,
					"CHA": 0.6
					},
				"Caps": {
					"MOVE": 10,
					"LIFE": 60,
					"COMP": 20,
					"PWR": 20,
					"MAG": 20,
					"ELEG": 20,
					"CELE": 20,
					"BAR": 20,
					"CHA": 20
					},
				"MaxInv": 6,
				"Inv":[{"Data":"GNG", "DUR":40}],
				"EQUIP": {"Data":"GNG", "DUR":40},
				"Passive":{"Vampire": true,
					"Fate": true,
					"SunWeak": true,
					"Fly": true},
				"Skills":["SLP1", "SHV1", "TOSS1", "WARP1"],
				"Weapons": {
					"BLADE": false,
					"BLUNT": false,
					"STICK": true,
					"BOOK": false,
					"GOHEI": false,
					"FAN": false,
					"BOW": false,
					"GUN": false,
					"SUB": false
					
				}
			}
		}
		UNIT_ID.Sakuya: 
			unitData = {"Sakuya": {"CLIFE": 1,
				"Profile": {
					"UnitName": "Sakuya Izayoi",
					"Prt": load(("res://sprites/SakuyaPrt.png")),
					"Sprite": load(("res://sprites/SakuyaTest.png")),
					"Level": 1,
					"EXP": 0,
					"CurCOMP": 0,
					"Class": "Maid"
					},
				"Stats": {
					"MOVE": 4,
					"LIFE": 19,
					"COMP": 100,
					"PWR": 7,
					"MAG": 2,
					"ELEG": 7,
					"CELE": 7,
					"BAR": 4,
					"CHA": 7
					},
				"Growths": {
					"MOVE": 0.02,
					"LIFE": 0.5,
					"COMP": 0,
					"PWR": 0.3,
					"MAG": 0.2,
					"ELEG": 0.55,
					"CELE": 0.55,
					"BAR": 0.2,
					"CHA": 0.7
					},
				"Caps": {
					"MOVE": 10,
					"LIFE": 20,
					"COMP": 20,
					"PWR": 20,
					"MAG": 20,
					"ELEG": 20,
					"CELE": 20,
					"BAR": 20,
					"CHA": 20
					},
				"MaxInv": 6,
				"Inv":[{"Data":"SLVKNF", "DUR":40}, {"Data":"PWRELIX", "DUR":1}],
				"EQUIP": {"Data":"SLVKNF", "DUR":40},
				"Passive":{},
				"Skills":["ST05"],
				"Weapons": {
					"BLADE": true,
					"BLUNT": false,
					"STICK": false,
					"BOOK": false,
					"GOHEI": false,
					"FAN": false,
					"BOW": false,
					"GUN": false,
					"SUB": ("KNIFE")
				}
			}
		}
		UNIT_ID.Patchy: 
			unitData = {"Patchouli": {"CLIFE": 1,
				"Profile": {
					"UnitName": "Patchouli Knowledge",
					"Prt": load(("res://sprites/PatchouliPrt.png")),
					"Sprite": load(("res://sprites/RemiliaTest.png")),
					"Level": 1,
					"EXP": 0,
					"CurCOMP": 0,
					"Class": "Mage"
					},
				"Stats": {
					"MOVE": 4,
					"LIFE": 18,
					"COMP": 100,
					"PWR": 2,
					"MAG": 7,
					"ELEG": 6,
					"CELE": 3,
					"BAR": 1,
					"CHA": 6
					},
				"Growths": {
					"MOVE": 0.02,
					"LIFE": 0.5,
					"COMP": 0,
					"PWR": 0.3,
					"MAG": 0.2,
					"ELEG": 0.55,
					"CELE": 0.55,
					"BAR": 0.2,
					"CHA": 0.7
					},
				"Caps": {
					"MOVE": 10,
					"LIFE": 20,
					"COMP": 20,
					"PWR": 20,
					"MAG": 20,
					"ELEG": 20,
					"CELE": 20,
					"BAR": 20,
					"CHA": 20
					},
				"MaxInv": 6,
				"Inv":[{"Data":"BK", "DUR":40}],
				"EQUIP": {"Data":"BK", "DUR":40},
				"Passive":{},
				"Skills":[],
				"Weapons": {
					"BLADE": false,
					"BLUNT": false,
					"STICK": false,
					"BOOK": true,
					"GOHEI": false,
					"FAN": false,
					"BOW": false,
					"GUN": false,
					"SUB": false
					
				}
			}
		}
		UNIT_ID.China: 
			unitData = {"Meiling": {"CLIFE": 1,
				"Profile": {
					"UnitName": "Hong Meiling",
					"Prt": load(("res://sprites/MeilingPrt.png")),
					"Sprite": load(("res://sprites/RemiliaTest.png")),
					"Level": 1,
					"EXP": 0,
					"CurCOMP": 0,
					"Class": "Guard"
					},
				"Stats": {
					"MOVE": 4,
					"LIFE": 18,
					"COMP": 100,
					"PWR": 2,
					"MAG": 7,
					"ELEG": 6,
					"CELE": 3,
					"BAR": 1,
					"CHA": 6
					},
				"Growths": {
					"MOVE": 0.02,
					"LIFE": 0.5,
					"COMP": 0,
					"PWR": 0.3,
					"MAG": 0.2,
					"ELEG": 0.55,
					"CELE": 0.55,
					"BAR": 0.2,
					"CHA": 0.7
					},
				"Caps": {
					"MOVE": 10,
					"LIFE": 20,
					"COMP": 20,
					"PWR": 20,
					"MAG": 20,
					"ELEG": 20,
					"CELE": 20,
					"BAR": 20,
					"CHA": 20
					},
				"MaxInv": 6,
				"Inv":[{"Data":"CLB", "DUR":40}, {"Data":"CLB", "DUR":40}],
				"EQUIP": {"Data":"CLB", "DUR":40},
				"Passive":{},
				"Skills":[],
				"Weapons": {
					"BLADE": false,
					"BLUNT": true,
					"STICK": false,
					"BOOK": false,
					"GOHEI": false,
					"FAN": false,
					"BOW": false,
					"GUN": false,
					"SUB": ("NATURAL")
					
				}
			}
		}
	return unitData

static func get_spec(specInd):
	var specData
	match specInd:
		SPEC_ID.Fairy: 
			specData = {"Fairy": {"Spec": "Fairy",
				"Stats": {
					"MOVE": 4,
					"LIFE": 0,
					"COMP": 100,
					"PWR": 0,
					"MAG": 1,
					"ELEG": 0,
					"CELE": 2,
					"BAR": 0,
					"CHA": 2
					},
				"Growths": {
					"MOVE": 0,
					"LIFE": 0.0,
					"COMP": 0,
					"PWR": 0.0,
					"MAG": 0.1,
					"ELEG": 0.0,
					"CELE": 0.1,
					"BAR": 0.0,
					"CHA": 0.1
					},
				"Caps": {
					"MOVE": 0,
					"LIFE": 0,
					"COMP": 0,
					"PWR": 0,
					"MAG": 0,
					"ELEG": 0,
					"CELE": 0,
					"BAR": 0,
					"CHA": 0
					},
				"Passive":{"Test": true}
				}
				}
	return specData
	
static func get_job(jobInd):
	var jobData
	match jobInd:
		JOB_ID.Trblr: 
			jobData = {"Trblr": {"Role": "Troublemaker",
				"Stats": {
					"MOVE": 0,
					"LIFE": 20,
					"COMP": 10,
					"PWR": 6,
					"MAG": 0,
					"ELEG": 4,
					"CELE": 2,
					"BAR": 4,
					"CHA": 0
					},
				"Growths": {
					"MOVE": 0,
					"LIFE": 0.4,
					"COMP": 0.3,
					"PWR": 0.3,
					"MAG": -0.1,
					"ELEG": 0.2,
					"CELE": 0.0,
					"BAR": 0.2,
					"CHA": 0.0
					},
				"Caps": {
					"MOVE": 10,
					"LIFE": 20,
					"COMP": 20,
					"PWR": 20,
					"MAG": 20,
					"ELEG": 20,
					"CELE": 20,
					"BAR": 20,
					"CHA": 20
					},
				"Passive":{"Test2": true},
				"Weapons": {
					"BLADE": false,
					"BLUNT":true,
					"STICK": false,
					"BOOK": false,
					"GOHEI": false,
					"FAN": false,
					"BOW": false,
					"GUN": false
				}
				},
			"Thief": {"Role": "Cointaker",
				"Stats": {
					"MOVE": 1,
					"LIFE": 14,
					"COMP": 10,
					"PWR": 4,
					"MAG": 0,
					"ELEG": 4,
					"CELE": 5,
					"BAR": 0,
					"CHA": 0
					},
				"Growths": {
					"MOVE": 0,
					"LIFE": 0.4,
					"COMP": 0.3,
					"PWR": 0.3,
					"MAG": -0.1,
					"ELEG": 0.2,
					"CELE": 0.0,
					"BAR": 0.2,
					"CHA": 0.0
					},
				"Caps": {
					"MOVE": 10,
					"LIFE": 20,
					"COMP": 20,
					"PWR": 20,
					"MAG": 20,
					"ELEG": 20,
					"CELE": 20,
					"BAR": 20,
					"CHA": 20
					},
				"Passive":{"Test3": true},
				"Weapons": {
					"BLADE": true,
					"BLUNT": false,
					"STICK": false,
					"BOOK": false,
					"GOHEI": false,
					"FAN": false,
					"BOW": false,
					"GUN": false,
					"SUB": ("KNIFE")
				}
				}
			}
	return jobData

static func get_art(prtName):
	var artData
	artData = {"Prt": load(("res://sprites/%sPrt.png" % [prtName]))}
#	artData = {"Prt": load(("res://sprites/%sSprite.png" % [prtName]))}
	return artData

static func get_terrain_costs():
	var terrainCost : Dictionary
	terrainCost["Foot"] = {
			"Flat" = 1,
	"Fort" = 2,
	"Hill" = 3
	}
	terrainCost["Fly"] = {
			"Flat" = 1,
	"Fort" = 1,
	"Hill" = 1
	}
	return terrainCost
	
static func get_items():
	var iData = {"NONE":{
				"NAME":"--",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 0,
				"ACC": 0,
				"CRIT": 0,
				"GRAZE": 0,
				"MINRANGE": 0,
				"MAXRANGE": 0,
				"CATEGORY": "NONE",
				"MAXDUR": 40,
				"SUBGROUP": false},
				##################
				"GNG":{
				"NAME":"Gungnir",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 5,
				"ACC": 90,
				"CRIT": 100,
				"GRAZE": 3,
				"MINRANGE": 1,
				"MAXRANGE": 2,
				"CATEGORY": "STICK",
				"MAXDUR": 40,
				"SUBGROUP": false},
				###############
				"SLVKNF":{
				"NAME":"Silver Knife",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 20,
				"ACC": 90,
				"CRIT": 100,
				"GRAZE": 2,
				"MINRANGE": 1,
				"MAXRANGE": 2,
				"CATEGORY": "BLADE",
				"MAXDUR": 40,
				"SUBGROUP": "KNIVES"},
				###############
				"CLB": {
				"NAME":"Club",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 7,
				"ACC": 0,
				"CRIT": 0,
				"GRAZE": 4,
				"MINRANGE": 1,
				"MAXRANGE": 1,
				"CATEGORY": "BLUNT",
				"MAXDUR": 40,
				"SUBGROUP": false},
				###############
				"DGR": {
				"NAME":"Dagger",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 4,
				"ACC": 0,
				"CRIT": 0,
				"GRAZE": 1,
				"MINRANGE": 1,
				"MAXRANGE": 1,
				"CATEGORY": "BLADE",
				"MAXDUR": 40,
				"SUBGROUP": false},
				###############
				"THKN":{
				"NAME":"Throwing Knife",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 3,
				"ACC": 0,
				"CRIT": 5,
				"GRAZE": 1,
				"MINRANGE": 2,
				"MAXRANGE": 2,
				"CATEGORY": "BLADE",
				"MAXDUR": 40,
				"SUBGROUP": "KNIVES"},
				###############
				"BK":{
				"NAME":"Book",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 1,
				"ACC": 70,
				"CRIT": 0,
				"GRAZE": 0,
				"MINRANGE": 1,
				"MAXRANGE": 1,
				"CATEGORY": "BOOK",
				"MAXDUR": 40,
				"SUBGROUP": false},
				###############
				"PZA":{
				"NAME":"Pizza",
				"ICON": load(("res://sprites/gungnir.png")),
				"CATEGORY": "ITEM",
				"MAXDUR": 3,
				"USE": true,
				"EFFECT": ["Pizza01"] },
				###############
				"PWRELIX":{
				"NAME":"Power Elixir",
				"ICON": load(("res://sprites/gungnir.png")),
				"CATEGORY": "ITEM",
				"MAXDUR": 1,
				"USE": true,
				"EFFECT": ["StrBuff01"] }
				
				}
	return iData
	
static func get_item_effects():
	var iEffects : Dictionary
	iEffects = {
		"IHEAL": {
			"target": "Self",
			"isPermanent": true,
			"type": "heal"
			
		}
	}
	
static func get_skill_effects():
	var skillEffects : Dictionary
	skillEffects = {
			"EffectGuide": {
			"Target": "Self", #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": 99, #Set to -1 to have gaurenteed proc chance
			"Duration": 0,
			"Time": false,
			"TimeFactor": 0,
			"Curable": true, #For status effects, buffs/debuffs. Dictates if effects can remove them.
			"Buff": false,
			"Debuff": false,
			"BuffStat": "PWR", #Any core Stat
			"BuffValue": 0,
			"Damaging": false,
			"Type": "Physical", #Physical, Magic
			"Damage": 0,
			"Cure": false,
			"CureType": "all", #Sleep, or All. This is because Sleep is the only status atm. As new status are added, this parameter does not need to be updated.
			"Healing": false,
			"Heal": 0,
			"Sleep": false,
			"Relocate": false,
			"MoveType": "Toss", #Warp(pick a hex), Shove(moved X distance); Toss(Placed behind Actor)
			"RelocRange": 0 #Distance Shoved, or range of valid tiles to warp to. Set to 0 for Toss.
			},
			"Test1": {
			"Target": "Target",
			"OnHit": true,
			"Proc": -1,
			"Damaging": true,
			"Type": "Physical",
			"Damage": 5
			},
			"Test2": {
			"Target": "Target",
			"OnHit": false,
			"Proc": -1,
			"Healing": true,
			"Heal": 2,
			},
			"SlowTime05": {
			"Target": "Global",
			"OnHit": false,
			"Proc": -1,
			"Duration": 2,
			"Time": true,
			"TimeFactor": -0.5
			},
			"SleepTest": {
			"Target": "Target", #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": -1, #Set to -1 to have gaurenteed proc chance
			"Duration": 1,
			"Sleep": true,
			"Curable": true
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
			"Healing": true,
			"Heal": 2
			},
			"StrBuff01": {
			"Target": "Self", #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": -1, #Set to -1 to have gaurenteed proc chance
			"Duration": 0,
			"Buff": true,
			"BuffStat": "PWR", #Any core Stat
			"BuffValue": 2,
			"Curable": true
			}
	}
	return skillEffects
static func get_skills():
	var skills : Dictionary
	skills = {
		"TEST1": {
		"SkillId": "TEST1",
		"SkillName": "Test Skill",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)
		"CanMiss": true,
		"ACC": 99,
		"RangeMin": 1,
		"RangeMax": 2,
		"Cost": 0,
		"EFFECT": ["Test1"]
		},
		"TEST2": {
		"SkillId": "TEST2",
		"SkillName": "Test Heal",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Ally",
		"CanMiss": false,
		"ACC": 100,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"EFFECT": ["Test2"]
		},
		"ST05": {
		"SkillId": "ST05",
		"SkillName": "Slow Time",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Self", #Enemy, Self, Ally
		"CanMiss": false,
		"ACC": 0,
		"RangeMin": 0,
		"RangeMax": 0,
		"Cost": 0,
		"EFFECT": ["SlowTime05"]
		},
		"SLP1": {
		"SkillId": "SLP1",
		"SkillName": "Sleep",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Ally", #Enemy, Self, Ally
		"CanMiss": false,
		"ACC": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"EFFECT": ["SleepTest"]
		},
		"SHV1": {
		"SkillId": "SHV1",
		"SkillName": "Shove",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally
		"CanMiss": false,
		"ACC": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"EFFECT": ["Shove1"]
		},
		"TOSS1": {
		"SkillId": "TOSS1",
		"SkillName": "Toss",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally
		"CanMiss": false,
		"ACC": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"EFFECT": ["Toss1"]
		},
		"WARP1": {
		"SkillId": "WARP1",
		"SkillName": "Warp Other",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Ally", #Enemy, Self, Ally
		"CanMiss": false,
		"ACC": 0,
		"RangeMin": 1,
		"RangeMax": 1,
		"Cost": 0,
		"EFFECT": ["Warp05"]
		}
	}
	return skills
