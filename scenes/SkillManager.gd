extends Node
class_name skillManager
var actorStats
var actorDmg
var targetStats
var skillData = UnitData.skillData
var effectData = UnitData.effectData
var rng = Global.rng


func run_skill(actor, target, activeSkill):
	var skillResult = {}
	var skill = skillData.activeSkill
	
	match skill.Target:
		"Enemy":
			pass #skillResult = skill_combat(actor, target, skill)
		"Self", "Player":
			pass #skillResult = check_effects(actor, target, skill)
	# actor.add_composure(skill.Cost) #not an existing function yet
	return skillResult

func skill_combat():
	var canCounter = false #placeholder, implement passive in future that can enable skill countering
	var result = {}
	var hit = false
	var attacker = Global.attacker
	var defender = Global.defender
	var check = roll()
	if check + attacker.ACC < defender.AVOID:
		hit = true
	if hit:
		pass #check_effects
	if !hit and canCounter:
		
	
func roll():
	randomize()
	return rng.randi_range(0, 99)
	
