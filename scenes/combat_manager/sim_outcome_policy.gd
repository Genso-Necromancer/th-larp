# SimOutcomePolicy.gd
extends CombatOutcomePolicy
class_name SimOutcomePolicy

enum SCENARIO {
	# core
	HIT_SUCCESS,
	HIT_FAIL,

	# optional refinement
	CRIT_SUCCESS,
	CRIT_FAIL,

	# effects
	EFFECT_SUCCESS,   # treat proc rolls as succeed if they are hostile etc
	EFFECT_FAIL,

	# or a more granular per-effect approach later
}

var scenario := SCENARIO.HIT_SUCCESS
var crit_mode := SCENARIO.CRIT_FAIL
var effect_mode := SCENARIO.EFFECT_FAIL

func _init(p_scenario: SCENARIO) -> void:
	scenario = p_scenario

func decide_hit(_hit_chance: int) -> bool:
	match scenario:
		SCENARIO.HIT_SUCCESS: return true
		SCENARIO.HIT_FAIL: return false
		_: return true # neutral scenarios hit

func decide_crit(_crit_chance: int) -> bool:
	return false

func decide_effect_proc(_proc_chance: int) -> bool:
	match scenario:
		SCENARIO.EFFECT_SUCCESS: return true
		SCENARIO.EFFECT_FAIL: return false
		_: return true # neutral scenarios success
