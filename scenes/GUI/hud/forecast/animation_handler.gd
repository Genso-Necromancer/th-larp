extends MarginContainer
class_name AnimationHandler

signal animations_complete
signal sequence_ready

#new vars
var unit_by_id: Dictionary = {}        # String -> Unit
var anim_by_id: Dictionary = {}        # String -> CombatAnimator

#old vars
const ACTION_TYPE = Enums.ACTION_TYPE
var animations = {}
var targets = {}
var activeAnims = {}
var isInitiated = false
var sequenceSteps = []
var begin := false
var sequence = false

func _process(_delta):
	if begin:
		begin = false
		_start_combat()


func _ready():
	SignalTower.prompt_accepted.connect(self._scene_skipped)
	SignalTower.sequence_initiated.connect(self._on_gameboard_sequence_initiated)

func load_animations(units):
	var initiatorNode = $InitiatorNode
	var initiateNode = $InitiateNode
	var firstUnit: Unit = null

	animations.clear()
	targets.clear()
	activeAnims.clear()
	sequenceSteps.clear()

	unit_by_id.clear()
	anim_by_id.clear()

	for unit: Unit in units:
		# Stable maps
		unit_by_id[unit.unit_id] = unit

		var animPath = "res://scenes/animations/combat/combat_%s.tscn" % [unit.unit_id.to_snake_case()]
		var animScene = load(animPath)
		if !animScene:
			animPath = "res://scenes/animations/combat/combat_sakuya.tscn"
			animScene = load(animPath)

		var anim = animScene.instantiate()
		anim.set_unit(unit)
		anim.pop_up_requested.connect(self._on_pop_up_requested)
		anim.target_fx_requested.connect(self._on_target_fx_requested)

		# Connect once; bind the UNIT as the key (keeps your current activeAnims structure)
		if !anim.animation_start.is_connected(self._on_animation_start.bind(unit)):
			anim.animation_start.connect(self._on_animation_start.bind(unit))
		if !anim.animation_end.is_connected(self._on_animation_end.bind(unit)):
			anim.animation_end.connect(self._on_animation_end.bind(unit))

		animations[unit] = anim
		anim_by_id[unit.unit_id] = anim

		if firstUnit == null:
			initiatorNode.add_child(anim)
			firstUnit = unit
		else:
			anim.flip_animation()
			initiateNode.add_child(anim)

			# Pairing (2-unit combat)
			targets[firstUnit] = unit
			targets[unit] = firstUnit


func _on_gameboard_sequence_initiated(newSequence):
	accept_event()
	begin = true
	sequence = newSequence


func _start_combat():
	if sequence == null:
		push_warning("AnimationHandler._start_combat: sequence is null")
		_clear_sequence()
		SignalTower.sequence_complete.emit()
		return

	# We expect CombatResults now
	if sequence is not CombatResults:
		push_error("AnimationHandler._start_combat: sequence is not CombatResults")
		_clear_sequence()
		SignalTower.sequence_complete.emit()
		return

	var cr: CombatResults = sequence
	var isSkipped := false
	isInitiated = true

	# Iterate rounds -> actions -> swings
	for round in cr.rounds:
		if isSkipped: break
		var actions: Array = round.get("actions", [])
		for action in actions:
			if isSkipped: break

			var actor_id := String(action.get("actor_id", ""))
			var target_id := String(action.get("target_id", ""))
			var action_type := int(action.get("action_type", 0))

			if actor_id == "" or target_id == "":
				continue

			var actor_unit: Unit = unit_by_id.get(actor_id, null)
			var target_unit: Unit = unit_by_id.get(target_id, null)
			if actor_unit == null or target_unit == null:
				continue

			var actor_anim: CombatAnimator = animations.get(actor_unit, null)
			var target_anim: CombatAnimator = animations.get(target_unit, null)
			if actor_anim == null or target_anim == null:
				continue

			# Optional: if you decide to store skill/item on the action node later
			# (recommended for hostile/friendly skill visuals)
			var skill_ref = null
			if action.has("skill_ref") and action["skill_ref"] != null:
				skill_ref = action["skill_ref"]
			elif action.has("item_ref") and action["item_ref"] != null:
				skill_ref = action["item_ref"]

			for swing in action.get("swings", []):
				if isSkipped: break

				var passiveStep := false
				var effectStep := false

				var did_hit := bool(swing.get("hit", false))
				var dmg := int(swing.get("dmg", 0))
				var did_crit := bool(swing.get("crit", false))
				var barrier_amt := int(swing.get("barrier", 0))
				var did_barrier := barrier_amt > 0
				var target_dead := bool(swing.get("target_dead", false))

				# Ensure death flag is set before defend animation chooses Death/Idle
				target_anim.set_if_death(target_dead)

				# PASSIVES / INSTANT CUT-INS
				# Pass A: only supports what is explicitly present (if you later add pre_events for these)
				# If you later push {"type":"passive_cut_in","passive":PassiveResource} into pre_events,
				# you can wire it here.
				var pre_events: Array = swing.get("pre_events", [])
				for ev in pre_events:
					if typeof(ev) == TYPE_DICTIONARY and ev.get("type", "") == "passive_cut_in":
						var passive = ev.get("passive", null)
						if passive != null:
							actor_anim.add_passive_cut_in([passive])
							passiveStep = true

				if passiveStep:
					sequenceSteps.append("Passives")

				# ACTIONS (attack/cast + defend)
				if action_type != ACTION_TYPE.FRIENDLY_SKILL:
					# Your CombatAnimator.assign_defend expects (hit, dmg, crit, grazeFlag)
					# In your current code, "graze" was used for barrier/graze mixing.
					target_anim.assign_defend(did_hit, dmg, did_crit, did_barrier)

				actor_anim.assign_action(did_hit, action_type, skill_ref)

				if skill_ref != null:
					actor_anim.add_skill_fx(skill_ref)

				if actor_anim.targetFxArray:
					target_anim.add_target_fx(actor_anim.targetFxArray)

				sequenceSteps.append("Actions")

				# EFFECT POPUPS (procced + resisted)
				# Rule:
				# - Always show when procced.
				# - If not procced: ONLY show "Resisted!" when the effect is resistable (effect.hostile == true).
				# - If it can fail but is not resistable: show nothing (avoid clutter).
				if not bool(swing.get("hit", false)): pass
				else:
					for eff in swing.get("effects", []):
						if typeof(eff) != TYPE_DICTIONARY:
							continue

						var effect_res: Effect = eff.get("effect", null)
						if effect_res == null:
							continue

						var procced := bool(eff.get("procced", false))
						var resisted := (not procced)

						# Skip clutter: non-resistable failures show nothing
						if resisted and not bool(effect_res.hostile):
							continue

						var is_self := bool(eff.get("is_self", false))
						var recipient_unit: Unit = actor_unit if is_self else target_unit
						var recipient_anim: CombatAnimator = animations.get(recipient_unit, null)
						if recipient_anim == null:
							continue
						if recipient_anim.dead:
							continue

						var effect_payload := _make_popup_effect_result(
							effect_res,
							eff.get("value", null),
							procced
						)
						recipient_anim.load_effect_result(effect_payload)
						effectStep = true

				if effectStep:
					sequenceSteps.append("Effects")

				# Kick sequence
				_progress_sequence()

				isSkipped = await self.animations_complete
				if isSkipped:
					break

				# Reset between swings
				actor_anim.reset_action()
				actor_anim.reset_variables()
				target_anim.reset_variables()

			# Reset defender stance after the action completes (matches your old behavior)
			target_anim.reset_defense()

	if not isSkipped:
		_clear_sequence()
	SignalTower.sequence_complete.emit()


func _on_animation_start(player):
	activeAnims[player] = true


func _on_animation_end(player):
	activeAnims[player] = false
	for anim in activeAnims:
		if activeAnims[anim]:
			return
	activeAnims.clear()
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
			"Passives": animations[anim].call_deferred("play_passive_que")
			"Actions": animations[anim].call_deferred("play_animation")
			"Complete": 
				animations_complete.emit(false)
				break
			"Effects": animations[anim].call_deferred("play_effects_que")

func _on_pop_up_requested(unit):
	var target = targets[unit]
	animations[target].play_pop_up()
	
func _on_target_fx_requested(unit):
	var target = targets[unit]
	animations[target].play_target_fx()

func _clear_sequence():
	isInitiated = false
	for anim in animations:
		animations[anim].stop_all()
		animations[anim].queue_free()
	sequenceSteps.clear()
	animations.clear()
	activeAnims.clear()
	print("Sequence cleared")


func _scene_skipped():
	if isInitiated: 
		activeAnims.clear()
		animations_complete.emit(true)

func _make_popup_effect_result(effect_res: Effect, resolved_value, procced: bool) -> Dictionary:
	if effect_res == null:
		return {}

	var d := {
		"EffectId": effect_res,
		"Dmg": 0,
		"Heal": 0,
		"Resisted": (not procced),
		"StyleType": int(effect_res.type)
	}

	# Resisted: phrase-only, no numbers
	if not procced:
		return d

	match int(effect_res.type):
		Enums.EFFECT_TYPE.DAMAGE, Enums.EFFECT_TYPE.COMP_DMG:
			if resolved_value != null:
				d["Dmg"] = int(resolved_value)
		Enums.EFFECT_TYPE.HEAL, Enums.EFFECT_TYPE.COMP_HEAL, Enums.EFFECT_TYPE.LIFE_STEAL:
			if resolved_value != null:
				d["Heal"] = int(resolved_value)
		_:
			pass

	return d
