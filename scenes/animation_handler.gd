@tool
extends Node

signal sequence_complete
signal animations_complete
signal sequence_ready


const ACTION_TYPE = Enums.ACTION_TYPE
var animations = {}
var targets = {}
var activeAnims = {}
var sequenceSteps = []

func _ready():
	SignalTower.prompt_accepted.connect(self._scene_skipped)


func load_animations(units):
	var initiatorNode = $InitiatorNode
	var initiateNode = $InitiateNode
	var firstUnit = false
	animations.clear()
	
	for unit in units:
		var animPath = "res://scenes/animations/combat/combat_%s.tscn" % [unit.unitId.to_snake_case()]
		var animScene = load(animPath)
		if !animScene:
			animPath = "res://scenes/animations/combat/combat_sakuya.tscn"
			animScene = load(animPath)
			
		animations[unit] = animScene.instantiate()
		animations[unit].set_unit(unit)
		animations[unit].pop_up_requested.connect(self._on_pop_up_requested)
		animations[unit].target_fx_requested.connect(self._on_target_fx_requested)
		
		if !firstUnit:
			initiatorNode.add_child(animations[unit])
			firstUnit = unit
		else:
			animations[unit].flip_animation()
			initiateNode.add_child(animations[unit])
			targets[firstUnit] = unit
			targets[unit] = firstUnit


func _on_gameboard_sequence_initiated(sequence): 
	var initiator = sequence.Rounds[0][0].keys()[0]
	var initiate = sequence.Rounds[0][0].keys()[1]
	var isSkipped = false
	
	for cycle in sequence.Rounds:
		for action in sequence.Rounds[cycle]:
			
			for swing in sequence.Rounds[cycle][action][initiator]:
				var passiveStep = false
				var effectStep = false
				var script = sequence.Rounds[cycle][action]
				var isCrit = script[initiator][swing].Crit
				var isGraze = script[initiate][swing].Graze
				#var isSlayer = script[initiator][swing].Slayer
				for anim in animations:
					animations[anim].animation_start.connect(self._on_animation_start.bind(anim))
					animations[anim].animation_end.connect(self._on_animation_end.bind(anim))
				
				animations[initiate].set_if_death(script[initiate][swing].Dead)
				
				if script[initiator][swing].Instant:
					animations[initiator].queue_instant_cut_in(script[initiator][swing].Instant)
				
				if sequence.Vantage:
					script[initiator][swing].PassiveProc.push_front(sequence.Vantage)
					
				if sequence.DeathMatch:
					script[initiator][swing].PassiveProc.push_front(sequence.DeathMatch)
					
				for anim in animations:
					if script[anim][swing].PassiveProc:
						animations[anim].add_passive_cut_in(script[anim][swing].PassiveProc)
						passiveStep = true
						
				if passiveStep:
					sequenceSteps.append("Passives")
						
					
				
				if script[initiator][swing].ActionType != ACTION_TYPE.FRIENDLY_SKILL:
					animations[initiate].assign_defend(script[initiator][swing].Hit, script[initiator][swing].Dmg, isCrit, isGraze)
					#print("Initiate: Defend animation called")
				
				animations[initiator].assign_action(script[initiator][swing].ActionType, script[initiator][swing].SkillId)
				#print("Initiator: action passed, ", script[initiator][swing].ActionType)
				
				if script[initiator][swing].SkillId:
					animations[initiator].add_skill_fx(script[initiator][swing].SkillId)
					#print("Initiator: Fx Added[", script[initiator][swing].SkillId, "]")
					
				if animations[initiator].targetFxArray:
					animations[initiate].add_target_fx(animations[initiator].targetFxArray)
				
				sequenceSteps.append("Actions")
				
				for anim in animations:
					if script[anim][swing].Effects:
						for effect in script[anim][swing].Effects:
							if !animations[effect.Target].dead:
								animations[effect.Target].load_effect_result(effect)
								print(effect.Target, ": Effect popup added[",effect,"]")
						effectStep = true
						
				if effectStep:
					sequenceSteps.append("Effects")
				
				_progress_sequence()
				
				isSkipped = await self.animations_complete
				if isSkipped: break
				animations[initiator].reset_action()
				animations[initiator].reset_variables()
				animations[initiate].reset_variables()
			if isSkipped: break
			animations[initiate].reset_defense()
			var holder1 = initiator
			var holder2 = initiate
			initiator = holder2
			initiate = holder1
		if isSkipped: break
	
	_clear_sequence()

func _on_animation_start(player):
	activeAnims[player] = true


func _on_animation_end(player):
	activeAnims[player] = false
	for anim in activeAnims:
		if activeAnims[anim]:
			return
	_progress_sequence()

#func _check_if_continue():
	#for anim in activeAnims:
		#if activeAnims[anim]:
			#return
	#_progress_sequence()
	#
	
func _progress_sequence():
	var nextStep 
	if sequenceSteps.size() == 0: nextStep = "Complete"
	else: nextStep = sequenceSteps.pop_front()
	
	for anim in animations:
		match nextStep:
			"Passives": animations[anim].play_passive_que()
			"Actions": animations[anim].play_animation()
			"Complete": emit_signal("animations_complete", false)
			"Effects": animations[anim].play_effects_que()

func _on_pop_up_requested(unit):
	var target = targets[unit]
	animations[target].play_pop_up()
	
func _on_target_fx_requested(unit):
	var target = targets[unit]
	animations[target].play_target_fx()

func _clear_sequence():
	
	for anim in animations:
		animations[anim].stop_all()
		animations[anim].queue_free()
	sequenceSteps.clear()
	animations.clear()
	print("Sequence cleared")
	emit_signal("sequence_complete")


func _scene_skipped():
	emit_signal("animations_complete", true)
