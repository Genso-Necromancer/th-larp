
const UNIT_ID := Enums.UNIT_ID

#these three are used in combination to create the data on a single enemy unit.
const MOVE_TYPE = Enums.MOVE_TYPE
const SPEC_ID = Enums.SPEC_ID
#, Human, Kappa, Lunarian, Oni, Doll, Devil, Yukionna, Zombie, Hermit, Magician, Spirit
const JOB_ID = Enums.JOB_ID

const WEP_ID = Enums.WEP_ID


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
				"Inv":[{"ID":"GNG", "EQUIP":true, "DUR":40}],
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
					"SUB": false},
				"MoveType": MOVE_TYPE.FLY
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
				"Inv":[{"ID":"SLVKNF", "EQUIP":true, "DUR":40}, {"ID":"PWRELIX", "EQUIP":false, "DUR":1}, {"ID":"DGR", "EQUIP":false, "DUR": 30}, {"ID":"TESTACC", "EQUIP":false, "DUR": -1}],
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
					"SUB": ("KNIFE")},
				"MoveType": MOVE_TYPE.FOOT
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
				"Inv":[{"ID":"BK", "EQUIP":true, "DUR":40}, {"ID":"PZA", "EQUIP":false, "DUR":3}],
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
					"SUB": false},
				"MoveType": MOVE_TYPE.FOOT
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
				"Inv":[{"ID":"CLB", "EQUIP":true, "DUR":40}, {"ID":"CLB", "EQUIP":false, "DUR":40}],
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
					"SUB": ("NATURAL")},
				"MoveType": MOVE_TYPE.FOOT
			}
		}
	return unitData

static func get_spec(specInd):

	match specInd:
		SPEC_ID.FAIRY: 
			return {
			"Spec": "Fairy",
			"StatGroups":{
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
					}
					},
			"Passive":{"Test": true},
			"MoveType": MOVE_TYPE.FLY
				}
	
static func get_job(jobInd):
	match jobInd:
		JOB_ID.TRBLR: 
			return {
			"Role": "Troublemaker",
			"StatGroups":{
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
					}
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
				}
		JOB_ID.THIEF: return {
			"Role": "Cointaker",
			"StatGroups":{
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
					"CELE": 0.45,
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
					}
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
		Enums.MOVE_TYPE.FOOT: 
			{"Flat": 1,
			"Fort": 2,
			"Hill": 3},
		Enums.MOVE_TYPE.FLY:
			{"Flat": 1,
			"Fort": 1,
			"Hill": 1}
		}
	return terrainCost
	
static func get_items():
	var iData = {"NONE":{
				"Name":"--",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 0,
				"ACC": 0,
				"Crit": 0,
				"GRAZE": 0,
				"MINRANGE": 0,
				"MAXRANGE": 0,
				"CATEGORY": "NONE",
				"MAXDUR": -1,
				"EQUIP":true,
				"SUBGROUP": false},
				##################
				"GNG":{
				"Name":"Gungnir",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 5,
				"ACC": 90,
				"Crit": 100,
				"GRAZE": 3,
				"MINRANGE": 1,
				"MAXRANGE": 2,
				"CATEGORY": "STICK",
				"MAXDUR": 40,
				"EQUIP":true,
				"SUBGROUP": false},
				###############
				"SLVKNF":{
				"Name":"Silver Knife",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 40,
				"ACC": 90,
				"Crit": 100,
				"GRAZE": 2,
				"MINRANGE": 1,
				"MAXRANGE": 2,
				"CATEGORY": "BLADE",
				"MAXDUR": 40,
				"EQUIP":true,
				"SUBGROUP": "KNIVES"},
				###############
				"CLB": {
				"Name":"Club",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 7,
				"ACC": 0,
				"Crit": 0,
				"GRAZE": 4,
				"MINRANGE": 1,
				"MAXRANGE": 1,
				"CATEGORY": "BLUNT",
				"MAXDUR": 40,
				"EQUIP":true,
				"SUBGROUP": false},
				###############
				"DGR": {
				"Name":"Dagger",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 4,
				"ACC": 85,
				"Crit": 0,
				"GRAZE": 1,
				"MINRANGE": 1,
				"MAXRANGE": 1,
				"CATEGORY": "BLADE",
				"MAXDUR": 40,
				"EQUIP":true,
				"SUBGROUP": false},
				###############
				"THKN":{
				"Name":"Throwing Knife",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 3,
				"ACC": 0,
				"Crit": 5,
				"GRAZE": 1,
				"MINRANGE": 2,
				"MAXRANGE": 2,
				"CATEGORY": "BLADE",
				"MAXDUR": 40,
				"EQUIP":true,
				"SUBGROUP": "KNIVES"},
				###############
				"BK":{
				"Name":"Book",
				"Icon": load(("res://sprites/gungnir.png")),
				"Type": Enums.DAMAGE_TYPE.PHYS,
				"Dmg": 1,
				"ACC": 70,
				"Crit": 0,
				"GRAZE": 0,
				"MINRANGE": 1,
				"MAXRANGE": 1,
				"CATEGORY": "BOOK",
				"MAXDUR": 40,
				"EQUIP":true,
				"SUBGROUP": false},
				###############
				"PZA":{
				"Name":"Pizza",
				"Icon": load(("res://sprites/gungnir.png")),
				"CATEGORY": "ITEM",
				"MAXDUR": 3,
				"USE": true,
				"Effect": ["Pizza01"] },
				###############
				"PWRELIX":{
				"Name":"Power Elixir",
				"Icon": load(("res://sprites/gungnir.png")),
				"CATEGORY": "ITEM",
				"MAXDUR": 1,
				"USE": true,
				"Effect": ["StrBuff01"] },
				###############
				"TESTACC":{
				"Name": "STR Ring",
				"Icon": load(("res://sprites/gungnir.png")),
				"CATEGORY": "ACC",
				"EQUIP": true,
				"Effect": ["StrBuff01"] }
				
				}
	return iData
	
	
static func get_skill_effects():
	var skillEffects : Dictionary
	skillEffects = {
			"EffectGuide": {
			"Type": Enums.EFFECT_TYPE,
			"Target": Enums.EFFECT_TARGET.SELF, #Self, Target, Global
			"OnHit": false, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": -1, #Set to -1 to have gaurenteed proc chance
			"Duration": 0, #Unit turns the effect lasts, -1 causes the effect to be permanent. Duration is ignored entirely for on-equip effects of items.
			"Stack": false, #True for infinite stacking, soft limit by duration Not necessary for permanent effects. Ignored for on-equip effects.
			#Effect specific Parameters
			#Effect: Time
			"TimeFactor": 0,
			#Effect: Buff/Debuff
			"BuffStat": Enums.CORE_STAT, #Any core Stat
			"BuffValue": 0,
			#Effect: Status
			"Status": Enums.STATUS_EFFECT, #Assign with string of valid Status conditions, Refer to Unit class for list.
			#Effect STATUS/BUFF/DEBUFF
			"Curable": true, #For buffs/debuffs. Dictates if effects can remove them.
			#Effect: DAMAGE
			"Dmg": 0, #set an int damage value
			"DmgType": Enums.DAMAGE_TYPE.PHYS, #use enum types
			#Effect: HEAL
			"Heal": 0, #set an int heal value
			#Effect: CURE
			"CureType": Enums.STATUS_EFFECT, #Sleep, or All. This is because Sleep is the only status atm. As new status are added, this parameter does not need to be updated.
			#effect: TOSS/SHOVE/WARP/DASH
			"RelocRange": 0, #Distance Shoved, or range of valid tiles to warp to. Set to 0 for Toss.
			"Hostile": false, #If movement should be treated as "hostile"
			#Effect: ADD_SKILL
			"Skill": "", #Not used yet. Temporarily adds skills via on-equip effects
			#Effect: ADD_PASSIVE
			"Passive": "",
			#Effect: ADD_PASSIVE/ADD_SKILL
			"Permanent": false,
			#RULE TYPES. YET TO BE IMPLEMENTED!!!!
},
			"Test1": {
			"Target": "Target",
			"OnHit": true,
			"Proc": -1,
			"Dmg": 5,
			"Type": Enums.DAMAGE_TYPE.PHYS
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
			"TimeFactor": -0.5
			},
			"SleepTest": {
			"Target": "Target", #Self, Target, Global
			"OnHit": true, #True: skill's accuracy check must pass for the effect to occur. False: effect is ran regardless of accuracy check
			"Proc": 100, #Set to -1 to have gaurenteed proc chance
			"Duration": 1,
			"Status": "Sleep",
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
			"Duration": -1,
			"Buff": true,
			"BuffStat": "PWR", #Any core Stat
			"BuffValue": 2
			}
	}
	return skillEffects
static func get_skills():
	var skills : Dictionary
	skills = {
		"TEST1": {
		"SkillId": "TEST1",
		"SkillName": "Example",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally, Self+(This is Self and Ally), Other(Enemy or Ally, not Self)
		"CanMiss": true, #default true
		"ACC": 0, #Int only. negative values acceptable for ACC penalties to the skill
		"Dmg": false, #set an int value for damage
		"Crit": false, #set an int value for crit bonus
		"Type": Enums.DAMAGE_TYPE.PHYS, #use enum types
		"RangeMin": 0,
		"RangeMax": 0,
		"Cost": 0,
		"Effect": []
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
		},
		"SLP1": {
		"SkillId": "SLP1",
		"SkillName": "Sleep",
		"Icon": load(("res://sprites/gungnir.png")),
		"Target": "Enemy", #Enemy, Self, Ally
		"CanMiss": false,
		"ACC": 60,
		"RangeMin": 1,
		"RangeMax": 2,
		"Cost": 0,
		"Effect": ["SleepTest"]
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
		"Effect": ["Shove1"]
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
		"Effect": ["Toss1"]
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
		"Effect": ["Warp05"]
		}
	}
	return skills
