extends Node
class_name TurnSort


func sort_turns(turns:Array[StringName]) -> Array[StringName]:
	if turns.size() <= 1:
		return turns
	
	var player_turns :Array[StringName]= []
	var enemy_turns :Array[StringName]= []
	for turn in turns:
		match turn:
			"Player": player_turns.append(turn)
			"Enemy": enemy_turns.append(turn)
			
	return weave_turns(player_turns, enemy_turns)
	
func weave_turns(player_turns:Array[StringName], enemy_turns:Array[StringName]) ->Array[StringName]:
	var interleaved_turns :Array[StringName]= []
	
	var player_index := 0
	var enemy_index := 0
	var player_remaining := player_turns.size()
	var enemy_remaining := enemy_turns.size()
	
	interleaved_turns.append(player_turns[player_index])
	player_index += 1
	player_remaining -= 1
	
	while player_remaining > 0 || enemy_remaining > 0:
		if enemy_remaining > 0:
			interleaved_turns.append(enemy_turns[enemy_index])
			enemy_index += 1
			enemy_remaining -= 1
		
		if player_remaining > 0:
			interleaved_turns.append(player_turns[player_index])
			player_index += 1
			player_remaining -= 1
			
		if player_remaining > enemy_remaining and player_remaining != 0:
			interleaved_turns.append(player_turns[player_index])
			player_index += 1
			player_remaining -= 1
			
			
		elif enemy_remaining > player_remaining and enemy_remaining != 0:
			interleaved_turns.append(enemy_turns[enemy_index])
			enemy_index += 1
			enemy_remaining -= 1
	return interleaved_turns
