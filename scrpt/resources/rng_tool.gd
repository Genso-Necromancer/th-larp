extends Resource
## Handles initialization of RandomNumberGenerator.
## Generating new seeds, saving and loading RNG state, and quick function for frequently used "rolls".(Roll functions not yet implemented)
## the RNG is stored in the Global singleton to maintain a persistant reference while this can be freely loaded and freed as needed to utilize it
## Inherits from Resource, so the first instance is cached and self frees. Fine to load this wherever needed
class_name RngTool

var rng:RandomNumberGenerator

func _init():
	_new_generator()

#region seed handling
func _new_generator():
	if !Global.rng:
		Global.rng = RandomNumberGenerator.new()
		rng = Global.rng


func new_seed():
	rng.randomize()


func save_state()->int:
	return rng.get_state()
#endregion

func load_state(state:int):
	rng.set_state(state)

#region roll functions
## Returns by how much the stat increases, 0 for failure, 1 for success and 2 if growth is over 100% and succeeds in a bonus
func growth_check(growth_rate:float) -> int:
	var overBonus:float= clampf((growth_rate - 1.0),0.0,2.0)
	var increase:int = 0
	var check:float = rng.randf_range(0.0,1.0)
	if check <= growth_rate: increase += 1
	if growth_rate > 1.0 and check < overBonus:
		increase += 1
	return increase
#endregion
