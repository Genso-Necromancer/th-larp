extends Node
class_name CombatManager

signal time_factor_changed
signal warp_selected

var ACTION_TYPE = Enums.ACTION_TYPE
var gameBoard: GameBoard

@export var rng_tool: RngTool # assign in inspector or created automatically

@onready var forecast_service: ForecastService = get_node_or_null("ForecastService")
@onready var resolver: CombatResolver = get_node_or_null("CombatResolver")
@onready var applier: CombatApplier = get_node_or_null("CombatApplier")

func _ready() -> void:
	_init_children()
	init_manager()

func _init_children() -> void:
	if not rng_tool:
		rng_tool = RngTool.new()

	# Ensure children exist and names match @onready paths
	if not has_node("ForecastService"):
		forecast_service = ForecastService.new()
		forecast_service.name = "ForecastService"
		add_child(forecast_service)

	if not has_node("CombatResolver"):
		resolver = CombatResolver.new()
		resolver.name = "CombatResolver" # IMPORTANT: match $CombatResolver
		add_child(resolver)

	if not has_node("CombatApplier"):
		applier = CombatApplier.new()
		applier.name = "CombatApplier"
		add_child(applier)

	# Shared deps
	for child in [forecast_service, resolver, applier]:
		child.cm = self
		child.rng_tool = rng_tool

	# Forward any signals you still rely on
	# (Long-term: migrate these to events instead of signals)
	if resolver.has_signal("warp_selected"):
		resolver.warp_selected.connect(func(a,b,c): warp_selected.emit(a,b,c))
	if resolver.has_signal("time_factor_changed"):
		resolver.time_factor_changed.connect(func(v): time_factor_changed.emit(v))

	if applier.has_signal("warp_selected"):
		applier.warp_selected.connect(func(a,b,c): warp_selected.emit(a,b,c))

func init_manager() -> void:
	gameBoard = get_parent()
	for child in [forecast_service, resolver, applier]:
		child.gameBoard = gameBoard

# ==========================
# PUBLIC API (normalized)
# ==========================

# Forecast should return CombatResults (not Dictionary) so UI can consume same structure
func get_forecast(attacker: Unit, defender: Unit, action: Dictionary) -> CombatResults:
	return forecast_service.get_forecast(attacker.to_sim(), defender.to_sim(), action)

# Live combat: resolve + apply + return the same CombatResults
func start_the_justice(attacker: Unit, defender: Unit, attacker_action: Dictionary) -> CombatResults:
	var cr: CombatResults = resolver.resolve_live(attacker.to_sim(), defender.to_sim(), attacker_action)
	applier.apply_results(cr, {
	String(cr.units["attacker_id"]): attacker,
	String(cr.units["defender_id"]): defender
})
	return cr

# AI sim branches: deterministic outcomes, no applier
func simulate_combat_hit(attacker_sim: UnitSim, defender_sim: UnitSim, attacker_action: Dictionary) -> CombatResults:
	return resolver.resolve_sim_hit_success(attacker_sim, defender_sim, attacker_action)

func simulate_combat_miss(attacker_sim: UnitSim, defender_sim: UnitSim, attacker_action: Dictionary) -> CombatResults:
	return resolver.resolve_sim_hit_failure(attacker_sim, defender_sim, attacker_action)

# Keep your old helper
func apply_results(attacker: Unit, defender: Unit, cr: CombatResults) -> void:
	applier.apply_results(cr, {
		attacker.unit_id: attacker,
		defender.unit_id: defender
	})
