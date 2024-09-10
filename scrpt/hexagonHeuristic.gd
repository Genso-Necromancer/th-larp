extends AStarGrid2D
class_name AHexGrid2D
#var Astar = AStarGrid2D.new()
var mapSize
var mapRect
var tileSize
var tilemap: GameMap
var oddq_directions = [
	[[+1,  0], [+1, -1], [ 0, -1], 
	[-1, -1], [-1,  0], [ 0, +1]],
	[[+1, +1], [+1,  0], [ 0, -1], 
	[-1,  0], [-1, +1], [ 0, +1]],
]

var grid: Array
var open_list: Array
var closed_list: Array
var solidList: Array
var weight
var lowest_f_cost
var lowest_node
var unitsList: Dictionary

func reinit():
	_init(tilemap)

func _init(tileMap: GameMap):
	self.tilemap = tileMap
	open_list = []
	closed_list = []
	solidList = []
	mapRect = tilemap.get_used_rect()
	mapSize = mapRect.size
	tileSize = tilemap.tileSize
	lowest_f_cost = INF
	lowest_node = null

#func set_hex_weight(hex, weight):
#	pass

func set_solid(solids: Array, units = null):
	solidList.clear()
	for solid in solids:
		solidList.append(solid)
	if units != null:
		unitsList = units
		
func is_solid_check(cell: Vector2i):
	if solidList.has(cell):
		return true
	else:
		return false
		
func is_units_check(cell):
	if unitsList.has(cell):
		return unitsList[cell]
	else:
		return false

func find_path(start: Vector2i, end: Vector2i, moveType: int, attack: bool = false) -> Array:
	open_list.clear()
	closed_list.clear()
	
	var start_node = start #/ tileSize
	var end_node = end #/ tileSize
	var initial_f_cost = 0.0
	var initial_g_cost = 0.0
	var initial_h_cost = 0.0
	var parent = null
	var terrain = true
	add_to_open_list(start_node, initial_f_cost, initial_g_cost, initial_h_cost, parent)
	if attack:
		terrain = false
	while open_list.size() > 0:
		var current_node = get_lowest_f_cost_node()

		
			
		open_list.erase(current_node)
		closed_list.append(current_node.node)
		if current_node.node == end_node:
#			print("PathTest: ", reconstruct_path(current_node))
			return reconstruct_path(current_node)

		var neighbors = get_neighbor_nodes(current_node, attack)
		for neighbor in neighbors:
			if neighbor in closed_list:
				continue
#		for neighbor in get_neighbor_nodes(current_node.node):
#			if closed_list.find(neighbor) != -1:
#				continue
				
				
			var g_cost = current_node.g_cost + compute_cost(current_node.node, neighbor.node, moveType, terrain)
			var h_cost = compute_cost(neighbor.node, end_node, moveType, terrain)
			var f_cost = g_cost + h_cost
			
			
			var neighbor_node = neighbor
			
			if neighbor_node not in open_list or f_cost < neighbor_node.f_cost:
				neighbor_node.g_cost = g_cost
				neighbor_node.h_cost = h_cost
				neighbor_node.f_cost = f_cost
				neighbor_node.parent = current_node
						
				if neighbor_node not in open_list:
					open_list.append(neighbor_node)
	
	return [] # Path not found

func find_all_paths(start: Vector2i, max_cost: int, moveType: int = Enums.MOVE_TYPE.FOOT, terrain: bool = true) -> Array:
#	var visited: Dictionary = {}
#	visited[start] = { "cost": 0, "paths": [[]] }
	
	var visited: Array = []
	visited.append({"node": start, "cost": 0, "paths": [[]]})
	
	var queue: Array = []
	queue.append(start)
	
	var result: Array = []
	
	while queue.size() > 0:
		var current_node = queue.pop_front()
		var current_info = get_visited_info(visited, current_node)
		var current_cost = current_info.cost
		var current_paths = current_info.paths
		
		result.append({ "node": current_node, "paths": current_paths })
		
		if current_cost >= max_cost:
			continue
			
		for neighbor in get_BFS_nhbr(current_node):
			var neighbor_info = get_visited_info(visited, neighbor)
			var neighbor_cost = current_cost + compute_cost(current_node, neighbor, moveType, terrain)
			if neighbor_cost > max_cost:
				continue
			if neighbor_info == {}  or neighbor_cost < neighbor_info["cost"]:
				var neighbor_paths = []
				if neighbor_info != {} and neighbor_cost < neighbor_info["cost"]:
					neighbor_info["cost"] = neighbor_cost
					neighbor_info["paths"] = []
				else:
					visited.append({ "node": neighbor, "cost": neighbor_cost, "paths": neighbor_paths })
					neighbor_info = visited[-1]
				
				for path in current_paths:
					var new_path = path + [neighbor]
					neighbor_info["paths"].append(new_path)
					
				queue.append(neighbor)

	result = dict_strip(result)
	return result

func dict_strip(dict):
	var strip: Array = []
	for page in dict:
		strip.append(page.node)
	return strip


func get_visited_info(visited: Array, node: Vector2i) -> Dictionary:
	for info in visited:
		if info["node"]== node:
			return info
	return {}

func add_to_open_list(node: Vector2i, f_cost: float, g_cost: float, h_cost: float, _parent) -> void:
		var firstNode = {"node" : node, "f_cost": f_cost, "g_cost": g_cost, "h_cost": h_cost, "parent": null}
		open_list.append(firstNode)
	
func reconstruct_path(node: Dictionary) -> Array:
	var path: Array = []
	var current_node = node
	
	while current_node.parent != null:
		path.insert(0, current_node.node)
		current_node = current_node.parent
	
	path.insert(0, current_node.node)
	current_node = current_node.parent
	
	
	return path
	
func get_lowest_f_cost_node():
	lowest_node = null
	lowest_f_cost = INF
	for node in open_list:
		var f_cost = node.f_cost
		if f_cost < lowest_f_cost:
			lowest_f_cost = f_cost
			lowest_node = node.duplicate()
	return lowest_node

#func get_closest_node(position: Vector2) -> Node:
#	var closest_node = null
#	var closest_distance = float('inf')
#
#	for node in grid:
#		var distance = position.distance_to(node)
#
#		if distance < closest_distance:
#			closest_node = node
#			closest_distance = distance
#
#	return closest_node

func estimate_cost(a, b) -> float:
	var ac = oddq_to_axial(a)
	var bc = oddq_to_axial(b)
	var distance = axial_distance(ac, bc)
	return distance
	
func compute_cost(a: Vector2i, b: Vector2i, moveType: int, terrain: bool = true) -> float:
	var tileWeight = 1
	var tileType
	if terrain:
		tileType = tilemap.get_movement_cost(b)
		tileWeight = UnitData.terrainCosts[moveType][tileType]

#	var base_cost = 1.0  # Base cost for moving between tiles
	var ac = oddq_to_axial(a)
	var bc = oddq_to_axial(b)
	var distance = axial_distance(ac, bc)
	var final = distance * tileWeight
#	if tileType == "Hill":
##		print(distance*tileWeight)
	return final
	
func oddq_to_axial(hex):
	var x = hex.x
	var y = hex.y - (hex.x - fposmod(hex.x, 2)) / 2
#	print(" O2A ", y)
	return Vector2i(x, y)
	
func axial_to_oddq(hex):
	var x = hex.x
	var y = hex.y + (hex.x - fposmod(hex.x, 2)) / 2
	return Vector2i(x, y)

func axial_substract(a, b):
	return Vector2i(a.x - b.x, a.y - b.y)

func axial_distance(a, b):
	var vec = axial_substract(a, b)
	return (abs(vec.x) + abs(vec.x + vec.y) + abs(vec.y)) / 2
	
# Override the get_neighbor_nodes method
func get_neighbor_nodes(hex: Dictionary, attack: bool = false) -> Array:
#	print("??")
	var neighbors = []
	var q = hex.node.x
	var _r = hex.node.y
	
	# Calculate the offsets based on odd-q hexagon grid rules
	var offsets = []
#	print(q)
	if fposmod(q, 2) == 0:
		
#		print("Even")
		offsets = [
			Vector2i(1, -1),  # Top-Right
			Vector2i(1, 0), # Bottom-Right
			Vector2i(0, 1), # Bottom
			Vector2i(-1, 0), # bottom-Left
			Vector2i(-1, -1), # Top-Left
			Vector2i(0, -1)   # Top
		]
	else:
#		print("Odd")
	# even row
		offsets = [
			Vector2i(1, 0),  # Top-Right
			Vector2i(1, 1), # Bottom-Right
			Vector2i(0, 1), # Bottom
			Vector2i(-1, 1), # bottom-Left
			Vector2i(-1, 0),  # Top-Left
			Vector2i(0, -1)   # Top
		]
	
	# Get the neighboring nodes based on the offsets
	for offsetH in offsets:
		var neighbor = hex.duplicate()
		neighbor.node += offsetH
#		print("hex ", hex.node, " nhbr ", neighbor.node)
#		var nodeOffset = []
#		nodeOffset.append(hex)
#		nodeOffset[0].node += offsetH
		
		# Check if the neighbor is valid
		if !attack:
			if is_valid_position(neighbor.node) and !is_solid_check(neighbor.node):
				neighbors.append(neighbor)
		else:
			if is_valid_position(neighbor.node):
				neighbors.append(neighbor)
			
	return neighbors
	
func get_BFS_nhbr(hex: Vector2i, ignoreSolid: bool = false, justNhbrs = false) -> Array:
#	print("??")
	var neighbors = []
	var q = hex.x
	var _r = hex.y
	
	# Calculate the offsets based on odd-q hexagon grid rules
	var offsets = []
#	print(q)
	if fposmod(q, 2) == 0:
		
#		print("Even")
		offsets = [
			Vector2i(1, -1),  # Top-Right
			Vector2i(1, 0), # Bottom-Right
			Vector2i(0, 1),# Bottom
			Vector2i(-1, 0), # bottom-Left
			Vector2i(-1, -1), # Top-Left
			Vector2i(0, -1)   # Top
		]
	else:
#		print("Odd")
		offsets = [			
			Vector2i(1, 0),  # Top-Right
			Vector2i(1, 1), # Bottom-Right
			Vector2i(0, 1), # Bottom
			Vector2i(-1, 1), # bottom-Left
			Vector2i(-1, 0),  # Top-Left
			Vector2i(0, -1)   # Top
		]
		
		
	if justNhbrs:
		for offsetH in offsets:
			var neighbor = hex
			neighbor += offsetH
			neighbors.append(neighbor)
		return neighbors
	else:
		for offsetH in offsets:
			var neighbor = hex
			neighbor += offsetH
	
		
		# Check if the neighbor is valid
			if !ignoreSolid:
				if check_valid_nhbr(neighbor, false, ignoreSolid):
					neighbors.append(neighbor)
			elif ignoreSolid:
				if check_valid_nhbr(neighbor, false, ignoreSolid):
					neighbors.append(neighbor)
		return neighbors

		
		
func resolve_shove(matchHex, targetHex, neighbors, distance): #for Shove, give target's neighbores and matchHex = actor's hex. for Toss, give actor's neighbors and matchHex = target's hex.
	#if <3 +3 if >= 3 -3
	var i = 0
	var shoveTo
	var isSlam = false
	var travel = 0
	var shoveStopper
	
	for hex in neighbors:
		if hex == matchHex and i < 3:
			i += 3
			shoveTo = neighbors[i]
			break
		elif hex == matchHex and i >= 3:
			i -= 3
			shoveTo = neighbors[i]
			break
		i += 1
	if check_valid_nhbr(shoveTo, true, false):
		isSlam = true
		shoveStopper = shoveTo
		shoveTo = targetHex
	distance -= 1
	while distance > 0 and !isSlam:
		neighbors = get_BFS_nhbr(shoveTo, false, true)
		if check_valid_nhbr(neighbors[i], true, false):
			isSlam = true
			shoveStopper = neighbors[i]
		else:
			shoveTo = neighbors[i]
			travel += 1
		distance -= 1
	var unitCollide = is_units_check(shoveStopper)
		
	var shoveResult = {"Hex": shoveTo, "Slam": isSlam, "Travel": travel, "UniColl": unitCollide}
	return shoveResult
	
#func resolve_toss(actorHex, targetHex, neighbors): #Delete if shove actually works for shove and toss
#	var tossTo
#	var isSlam
#	var tossStopper
#	var i = 0
#	for hex in neighbors:
#		if hex == targetHex and i < 3:
#			i += 3
#			tossTo = neighbors[i]
#			break
#		elif hex == targetHex and i >= 3:
#			i -= 3
#			tossTo = neighbors[i]
#			break
#		i += 1
#	if check_valid_nhbr(tossTo, true, false):
#		isSlam = true
#		tossStopper = tossTo
#		tossTo = targetHex
#	var unitCollide = is_units_check(tossStopper)
#	var tossResult = {"Hex": tossTo, "Slam": isSlam, "UniColl": unitCollide}
#	return tossResult

func check_valid_nhbr(hex, checkSlam = false, ignoreSolid = true):
		# Check if the hex is valid
		if checkSlam:
			if is_valid_position(hex) and !is_solid_check(hex):
				return false
			else:
				return true
		elif !ignoreSolid:
			if is_valid_position(hex) and !is_solid_check(hex):
				return hex
		elif ignoreSolid:
			if is_valid_position(hex):
				return hex

	
func is_valid_position(neighbor): 
	var valid
	if neighbor.x > mapSize.x or neighbor.y > mapSize.y:
		valid = false
	elif neighbor.x < 0 or neighbor.y < 0:
		valid = false
	else:
		valid = true
	return valid
	
func oddq_offset_neighbor(hex, direction):
	var parity = fposmod(hex.x, 2)
	var dir = oddq_directions[parity][direction]
	var offsetCoord = Vector2i(hex.x + dir[0], hex.y + dir[1])
	return offsetCoord

func trim_path(path: Array, invalid: Array):
	for cell in invalid:
		if path.has(cell):
			path.erase(cell)
	return path
	
func find_range(current):
	var maxRange = 0
	var minRange = 1000
	for wep in current.unitData.Inv:
		if current.unitData.Inv[wep].LIMIT and current.unitData.Inv[wep].USES == 0:
			continue
		maxRange = max(maxRange, current.unitData.Inv[wep].MAXRANGE, maxRange)
		minRange = min(minRange, current.unitData.Inv[wep].MINRANGE, minRange)
	var unitRange = [minRange, maxRange]
	return unitRange
	
func find_threat(walkable, unitRange, moveType = "Flat"):
	var attackSpaces = []
	var i = 1
	var threatRange = []
	var visited = []
	var maxRange = unitRange[0]
	var minRange = unitRange[1]
	var reachable = walkable.duplicate()
	while i <= maxRange:
		for oddQ in reachable:
	#		var axial = oddq_to_axial(oddQ)
			if !visited.has(oddQ):
				visited.append(oddQ)
			else:
				continue
			for neighbor in get_BFS_nhbr(oddQ, true):
				if !attackSpaces.has(neighbor):
					attackSpaces.append(neighbor)
				if !threatRange.has(neighbor):
					threatRange.append(neighbor)
		for tile in attackSpaces:
			if !reachable.has(tile):
				reachable.append(tile)
		i += 1
	var filteredThreatRange = []
	
	for tile in threatRange:
		for cell in walkable:
			var tileRange = compute_cost(cell, tile, moveType, false)
			if tileRange >= minRange and !filteredThreatRange.has(tile):
				filteredThreatRange.append(tile)
	return filteredThreatRange

func find_closest(_atkrCell, dfndCell, atkrWalkable, moveType: int):
	var closestCell = null
	var minDist = 1000
	for cell in atkrWalkable:
		var path = find_path(cell, dfndCell, moveType, true)
		if path.size() < minDist:
			closestCell = cell
			minDist = path.size()
	return closestCell

func find_distance(start, target, moveType: int = Enums.MOVE_TYPE.FOOT, attack:bool = false):
	var path = find_path(start, target, moveType, attack)
	path.pop_back()
	return path.size()

#func find_goal(wakka, brother, sinsToxin):
#	var goal
#	var you = "Tidus"
#	while goal != "Victory":
#		if !brother.pop_back():
#			match wakka:
#				"Alright": continue
#				"Hustle": goal = "victory"
#	if sinsToxin.has(you):
#		return
#	return goal
