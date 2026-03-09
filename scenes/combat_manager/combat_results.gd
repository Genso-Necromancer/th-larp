extends Resource
class_name CombatResults
## CombatResults
## Used by: Resolver, Visuals, Applier, AI

enum MODE {
	NONE,
	LIVE,
	FORECAST,
	SIM
}


## Core
@export var mode: MODE = MODE.NONE

## Combat instance meta info
@export var meta: Dictionary = {
	"combat_type": 0,          # Enums.COMBAT_TYPE
	"deathmatch_rounds": 0,    # int
	"vantage": false           # bool
}

## identifiers, never store Unit references here
@export var units: Dictionary = {
	"attacker_id": "",
	"defender_id": ""
}

## Combat data order: rounds > actions > swings
@export var rounds: Array = []

## Build / Reset
func reset(p_mode: MODE = MODE.NONE) -> void:
	mode = p_mode
	meta = {
		"combat_type": 0,
		"deathmatch_rounds": 0,
		"vantage": false
	}
	units = {
		"attacker_id": "",
		"defender_id": ""
	}
	rounds.clear()



## Round / Action / Swing helpers
func add_round() -> Dictionary:
	var round := {
		"actions": []
	}
	rounds.append(round)
	return round


func add_action(round: Dictionary, actor_id: String, target_id: String, action_type: int, is_initiator: bool) -> Dictionary:
	var action := {
		"actor_id": actor_id,
		"target_id": target_id,
		"action_type": int(action_type),
		"is_initiator": bool(is_initiator),
		"swings": [],
		# UI flags
		"swing_count": 1,
		"followup_possible": false,
		"counter_possible": false,

		# action source (for animations/UI)
		"uses_weapon": false,          # bool
		"skill_id": "",                # String
		"item_id": "",                 # String

		# runtime-only (animation convenience; avoid serializing)
		"skill_ref": null,             # SlotWrapper/Skill (Resource)
		"item_ref": null               # SlotWrapper/Item (Resource)
	}
	round["actions"].append(action)
	return action


func add_swing(action: Dictionary) -> Dictionary:
	var swing := {
		"hit": false,
		"hit_chance": 0,
		"crit": false,
		"crit_chance": 0,
		"crit_dmg": 0,
		#Final damage after all factoring
		"dmg": 0,
		# debug/preview components
		"reduction": 0,
		"barrier": 0,
		"bar_prc": 0,
		#Durability
		"break": false,
		#Damage modifier defaults
		"slayer_mult": 1.0,
		#Effect result records (resolver/forecast fill these)
		"effects": [],
		#Events (LIVE only; applier consumes)
		"events": [],
		#Morale/composure
		"comp_actor": 0,
		"comp_target": 0,
		"target_dead": false
	}
	action["swings"].append(swing)
	return swing



## QoL
func is_live() -> bool:
	return mode == MODE.LIVE

func is_sim() -> bool:
	return mode == MODE.SIM

func is_forecast() -> bool:
	return mode == MODE.FORECAST


func get_all_actions() -> Array:
	var out := []
	for r in rounds:
		for a in r.get("actions", []):
			out.append(a)
	return out


func get_all_swings() -> Array:
	var out := []
	for r in rounds:
		for a in r.get("actions", []):
			for s in a.get("swings", []):
				out.append(s)
	return out



## Serialization for old stuff, saves, AI
func to_dict() -> Dictionary:
	var clean_rounds := rounds.duplicate(true)

	for r in clean_rounds:
		for a in r.get("actions", []):
			a.erase("skill_ref")
			a.erase("item_ref")

	return {
		"mode": mode,
		"meta": meta.duplicate(true),
		"units": units.duplicate(true),
		"rounds": clean_rounds
	}


func from_dict(data: Dictionary) -> void:
	mode = data.get("mode", MODE.NONE)
	meta = data.get("meta", {}).duplicate(true)
	units = data.get("units", {}).duplicate(true)
	rounds = data.get("rounds", []).duplicate(true)
