extends Resource
##Nudges AI behavior towards trends and tactics for characterizing enemy commanders. Every map requires a personality_weight connected with it.
class_name Personality

# Designer-facing tiers stay readable in the inspector while the evaluator
# converts them into small scoring nudges.
enum WeightTier {
	NONE, ##0.0
	VERY_LOW, ##0.8
	LOW, ##0.9
	NORMAL, ##1.0
	HIGH, ##1.1
	EXTREME, ##1.2
}

const TIER_VALUES := {
	WeightTier.NONE: 0.0,
	WeightTier.VERY_LOW: 0.8,
	WeightTier.LOW: 0.9,
	WeightTier.NORMAL: 1.0,
	WeightTier.HIGH: 1.1,
	WeightTier.EXTREME: 1.2,
}

# These grouped exports map directly to the evaluator feature families.
@export_group("Offense")
@export var damage_preference: WeightTier = WeightTier.VERY_LOW
@export var kill_finish_preference: WeightTier = WeightTier.VERY_LOW
@export var accuracy_preference: WeightTier = WeightTier.VERY_LOW
@export var focus_fire_preference: WeightTier = WeightTier.VERY_LOW
@export var support_bias_preference: WeightTier = WeightTier.NONE

@export_group("Defense")
@export var survival_preference: WeightTier = WeightTier.NORMAL
@export var barrier_value_preference: WeightTier = WeightTier.NORMAL
@export var lethality_respect_preference: WeightTier = WeightTier.NORMAL
@export_range(0.0, 1.0, 0.05) var risk_threshold: float = 0.5

@export_group("Position")
@export var terrain_preference: WeightTier = WeightTier.NORMAL
@export var objective_pressure_preference: WeightTier = WeightTier.NORMAL
@export var formation_preference: WeightTier = WeightTier.LOW
@export var aura_coverage_preference: WeightTier = WeightTier.LOW
@export var protect_leader_preference: WeightTier = WeightTier.LOW
@export var unit_pressure_preference: WeightTier = WeightTier.VERY_LOW

@export_group("Tempo")
@export var wait_preference: WeightTier = WeightTier.VERY_LOW
@export var aggression_preference: WeightTier = WeightTier.NORMAL
@export var overextension_tolerance_preference: WeightTier = WeightTier.LOW
@export var tempo_preference: WeightTier = WeightTier.NORMAL

@export_group("Tuning")
@export_range(0.0, 5.0, 0.05) var safe_attack_bonus: float = 1.4
@export_range(0.0, 5.0, 0.05) var accuracy_curve: float = 2.2
@export_range(0.0, 5.0, 0.05) var minimum_action_score: float = 0.5
@export var max_depth: int = 3


func tier_value(tier: WeightTier) -> float:
	return float(TIER_VALUES.get(tier, 1.0))


# Returns the evaluator-ready shape used by the new AI manager.
func get_category_weights() -> Dictionary:
	return {
		"offense": {
			"damage": tier_value(damage_preference),
			"kill_finish": tier_value(kill_finish_preference),
			"accuracy": tier_value(accuracy_preference),
			"focus_fire": tier_value(focus_fire_preference),
			"support_bias": tier_value(support_bias_preference),
		},
		"defense": {
			"survival": tier_value(survival_preference),
			"barrier_value": tier_value(barrier_value_preference),
			"lethality_respect": tier_value(lethality_respect_preference),
			"risk_threshold": risk_threshold,
		},
		"position": {
			"terrain": tier_value(terrain_preference),
			"objective_pressure": tier_value(objective_pressure_preference),
			"formation": tier_value(formation_preference),
			"aura_coverage": tier_value(aura_coverage_preference),
			"protect_leader": tier_value(protect_leader_preference),
			"unit_pressure": tier_value(unit_pressure_preference),
		},
		"tempo": {
			"wait": tier_value(wait_preference),
			"aggression": tier_value(aggression_preference),
			"overextension_tolerance": tier_value(overextension_tolerance_preference),
			"tempo": tier_value(tempo_preference),
		},
		"tuning": {
			"safe_attack_bonus": safe_attack_bonus,
			"accuracy_curve": accuracy_curve,
			"minimum_action_score": minimum_action_score,
			"max_depth": max_depth,
		},
	}


# Compatibility accessors keep older AI call sites working while the evaluator
# finishes migrating onto the grouped schema.
var terrain: float:
	get:
		return tier_value(terrain_preference)

var finishOffUnits: float:
	get:
		return tier_value(kill_finish_preference)

var dmgWeight: float:
	get:
		return tier_value(damage_preference)

var accWeight: float:
	get:
		return tier_value(accuracy_preference)

var barrierChance: float:
	get:
		return tier_value(barrier_value_preference)

var survival: float:
	get:
		return tier_value(survival_preference)

var waitWeight: float:
	get:
		return tier_value(wait_preference)

var survThresh: float:
	get:
		return risk_threshold

var accScale: float:
	get:
		return accuracy_curve

var safeBonus: float:
	get:
		return safe_attack_bonus

var units: float:
	get:
		return tier_value(unit_pressure_preference)

var tWeight: float:
	get:
		return terrain

var uWeight: float:
	get:
		return units

var ulWeight: float:
	get:
		return finishOffUnits

var grWeight: float:
	get:
		return barrierChance

var survWeight: float:
	get:
		return survival

var minimumValue: float:
	get:
		return minimum_action_score
