extends RefCounted
class_name BoardAssessment

enum OBJECTIVE_CONTEXT {
	UNKNOWN,
	SEIZE_DEFENSE,
}

var objective_context: int = OBJECTIVE_CONTEXT.UNKNOWN
var faction: int = Enums.FACTION_ID.ENEMY

var player_can_seize_now: bool = false
var player_can_seize_next_round: bool = false
var seize_tile_threatened: bool = false
var boss_threatened: bool = false
var line_is_broken: bool = false
var tempo_advantage: bool = false

var threatened_allies: Array[String] = []
var healable_allies: Array[String] = []
var high_value_targets: Array[String] = []
var safe_attackers: Array[String] = []
var special_tasks_available: Array[String] = []
var seize_tiles: Array[Vector2i] = []

var actions_remaining: int = 0
