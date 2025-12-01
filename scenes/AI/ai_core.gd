extends Node
class_name AiCore


var generator:MoveGenerator

func find_best_move(state:BoardState, depth:int)->Turn:
	var best_score := -INF
	var best_move:Turn
	generator = MoveGenerator.new()
	for move in generator.generate_moves(state):
		var score := -negamax(state.apply(move), depth - 1, -INF, INF)
		if score > best_score:
			best_score = score
			best_move = move
	generator.queue_free()
	return best_move


func negamax(state:BoardState, depth:int, alpha:float, beta:float)->float:
	if depth == 0 or state.is_terminal(): return evaluate(state)
	var best := -INF
	for move in generator.generate_moves(state):
		var new_state := state.apply(move)
		var score := -negamax(new_state, depth - 1, -beta, -alpha)
		best = max(best, score)
		alpha = max(alpha, score)
		if alpha >= beta: break# α-β prune
	return best


#Concept. Not a true evaluation
func evaluate(state:BoardState)->float:
	var score:=0.0
	for unit in state.units.values():
		var val:float= unit.value * (unit.hp / unit.max_hp)
		if unit.FACTION_ID == Enums.FACTION_ID.ENEMY:
			score += val
		else: score -= val
	# Position bonuses
		#score += terrain_bonus(unit)
		#score += threat_score(unit, state)
		#score += objective_bonus(state)
	return score
