
enum UNIT_ID {Remilia, Sakuya, Patchy}

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
					"PWR": 5,
					"MAG": 6,
					"ELEG": 6,
					"CELE": 6,
					"BAR": 5,
					"CHA": 8
					},
				"Growths": {
					"MOVE": 0,
					"LIFE": 0.7,
					"COMP": 0,
					"PWR": 0.3,
					"MAG": 0.35,
					"ELEG": 0.4,
					"CELE": 0.4,
					"BAR": 0.2,
					"CHA": 0.6
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
				"Inv":[],
				"StartInv":["GNG"],
				"EQUIP": "",
				"Passive":{"Vampire": true,
					"Fate": true,
					"SunWeak": true,
					"Fly": true},
				"Skills":["TEST1", "TEST2"]
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
				"Inv":[],
				"StartInv":["SLVKNF", "THKN"],
				"EQUIP":"",
				"Passive":{},
				"Skills":["ST05"]
			}
		}
		UNIT_ID.Patchy: 
			unitData = {"Patchouli": {"CLIFE": 1,
				"Profile": {
					"UnitName": "Patchouli Knowledge",
					"Prt": load(("res://sprites/PatchouliPrt.png")),
					"Sprite": load(("res://sprites/SakuyaTest.png")),
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
				"Inv":[],
				"StartInv":["BK"],
				"EQUIP":"Book",
				"Passive":{},
				"Skills":[]
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
				"Passive":{"Test2": true}
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
				"Passive":{"Test3": true}
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
	
static func get_wep():
	var wepData = {"GNG":{
				"NAME":"Gungnir",
				"ICON": load(("res://sprites/gungnir.png")),
				"TYPE": "Physical",
				"DMG": 5,
				"ACC": 90,
				"CRIT": 100,
				"GRAZE": 3,
				"MINRANGE": 1,
				"MAXRANGE": 2,
				"LIMIT": false },
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
				"LIMIT": false},
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
				"LIMIT": false},
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
				"LIMIT": false},
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
				"LIMIT": true,
				"MAXDUR": 10},
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
				"LIMIT": false }
				}
	return wepData
	
static func get_skill_effects():
	var skillEffects : Dictionary
	skillEffects = {
		"EffectTest": {
			"Target": "Self", #Self, Target, Global
			"OnHit": false,
			"Proc": 99,
			"Duration": 0,
			"Time": false,
			"TimeFactor": 0,
			"Buff": false,
			"Debuff": false,
			"BuffStat": "PWR", #Any core Stat
			"BuffValue": 0,
			"Damaging": false,
			"Type": "Physical", #Physical, Magic
			"Damage": 0,
			"Cure": false,
			"CureType": "all",
			"Healing": false,
			"Heal": 0,
			"Sleep": false,
			"Relocate": false,
			"MoveType": "reposition"
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
		"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally)
		"CanMiss": true,
		"ACC": 99,
		"RangeMin": 1,
		"RangeMax": 2,
		"Cost": 0,
		"Effect": ["Test1"]
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
		"Effect": ["Test2"]
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
		"Effect": ["SlowTime05"]
		}
	}
	return skills
