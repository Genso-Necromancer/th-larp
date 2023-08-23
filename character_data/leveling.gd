extends Node




static func get_experience(action, totalExp, targLvl, stats, growths, caps):
	var gainExp = 0
	match action:
		"attack":  
				gainExp  = (21 + targLvl - stats[0]) / 2
				gainExp = clampi(gainExp, 1, 100)
				
		"defeat": 
			gainExp = ((21 + targLvl - stats[0]) / 2) + (targLvl - stats[0])
			gainExp = clampi(gainExp, 1, 100)
		"pacifist": 
			gainExp = (21 + stats[0])
			gainExp = clampi(gainExp, 1, 100)
			
	totalExp = totalExp + gainExp
	while totalExp >= 100:
		totalExp -= 100
		totalExp = clampi(totalExp, 0, 10000)
		stats = level_up(stats, growths, caps)
	return [totalExp, stats]
	
static func level_up(stats, growths, caps):
	var rng = RandomNumberGenerator.new()
	randomize()
	var growth_check
	var arrayInd = 0
	stats[0] += 1
	arrayInd += 1
	while arrayInd < stats.size():
		growth_check = rng.randf_range(0.01, 1.0)
		if growth_check <= growths[arrayInd]:
			stats[arrayInd] += 1
			if growths[arrayInd] >= 1.0 and growth_check <= growths[arrayInd] - 1.0:
				stats[arrayInd] += 1
			clampi(stats[arrayInd], 0, caps[arrayInd])
			arrayInd += 1
		else:
			arrayInd += 1
	rng.queue_free()
	return stats
	
