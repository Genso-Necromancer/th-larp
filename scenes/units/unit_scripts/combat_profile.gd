# combat_profile.gd
extends RefCounted
class_name CombatProfile

# Snapshot of combat-related numbers used by AI/combat resolver
var Dmg: int = 0
var Hit: int = 0
var Graze: int = 0
var Barrier: int = 0
var BarPrc: int = 0
var Crit: int = 0
var Luck: int = 0
var Resist: int = 0
var EffHit: int = 0
var DRes: Dictionary = {}
var Type = null
var CanMiss: bool = true

func clone() -> CombatProfile:
	var p := CombatProfile.new()
	p.Dmg = Dmg; p.Hit = Hit; p.Graze = Graze; p.Barrier = Barrier
	p.BarPrc = BarPrc; p.Crit = Crit; p.Luck = Luck; p.Resist = Resist
	p.EffHit = EffHit; p.DRes = DRes.duplicate(true); p.Type = Type; p.CanMiss = CanMiss
	return p
