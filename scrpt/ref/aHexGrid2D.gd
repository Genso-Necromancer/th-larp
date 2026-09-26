extends RefCounted
class_name AHexGrid2D
##Current Progress: 
##Initialize with a map, assign unit & units, sort how to handle obstacles both units and terrain.
##running find_unit_paths searches all paths up to the unit's movement, based on terrain cost, blocking solid objects.
##Active Unit is used in places, but never actually assigned??? Assess this.

## TileSet custom data layer: WallDirection
## Bitmask order starts from the top edge and proceeds clockwise.
const WALL_UP := 1
const WALL_UP_RIGHT := 2
const WALL_DOWN_RIGHT := 4
const WALL_DOWN := 8
const WALL_DOWN_LEFT := 16
const WALL_UP_LEFT := 32

const WALL_DIRECTION_NAMES := {
	WALL_UP: "UP",
	WALL_UP_RIGHT: "UP_RIGHT",
	WALL_DOWN_RIGHT: "DOWN_RIGHT",
	WALL_DOWN: "DOWN",
	WALL_DOWN_LEFT: "DOWN_LEFT",
	WALL_UP_LEFT: "UP_LEFT",
}

const WALL_BITS_BY_OFFSET_INDEX := [
	WALL_UP_RIGHT,
	WALL_DOWN_RIGHT,
	WALL_DOWN,
	WALL_DOWN_LEFT,
	WALL_UP_LEFT,
	WALL_UP,
]

const WALL_EDGE_POINTS := {
	WALL_UP: [Vector2(-42, -25), Vector2(42, -25)],
	WALL_UP_RIGHT: [Vector2(42, -25), Vector2(84, 0)],
	WALL_DOWN_RIGHT: [Vector2(84, 0), Vector2(42, 25)],
	WALL_DOWN: [Vector2(42, 25), Vector2(-42, 25)],
	WALL_DOWN_LEFT: [Vector2(-42, 25), Vector2(-84, 0)],
	WALL_UP_LEFT: [Vector2(-84, 0), Vector2(-42, -25)],
}

const WALL_CORNER_BITS := {
	"UP_LEFT": [WALL_UP_LEFT, WALL_UP],
	"UP_RIGHT": [WALL_UP, WALL_UP_RIGHT],
	"RIGHT": [WALL_UP_RIGHT, WALL_DOWN_RIGHT],
	"DOWN_RIGHT": [WALL_DOWN_RIGHT, WALL_DOWN],
	"DOWN_LEFT": [WALL_DOWN, WALL_DOWN_LEFT],
	"LEFT": [WALL_DOWN_LEFT, WALL_UP_LEFT],
}

const WALL_CORNER_POINTS := {
	"UP_LEFT": Vector2(-42, -25),
	"UP_RIGHT": Vector2(42, -25),
	"RIGHT": Vector2(84, 0),
	"DOWN_RIGHT": Vector2(42, 25),
	"DOWN_LEFT": Vector2(-42, 25),
	"LEFT": Vector2(-84, 0),
}

const WALL_OPPOSITES := {
	WALL_UP: WALL_DOWN,
	WALL_UP_RIGHT: WALL_DOWN_LEFT,
	WALL_DOWN_RIGHT: WALL_UP_LEFT,
	WALL_DOWN: WALL_UP,
	WALL_DOWN_LEFT: WALL_UP_RIGHT,
	WALL_UP_LEFT: WALL_DOWN_RIGHT,
}

const WALL_TYPE_BLOCK_ALL := &"Wall"
const WALL_TYPE_FLY_PASS := &"WallFly"
const WALL_TYPE_SHOOT_PASS := &"WallShoot"

var mapSize
var mapRect
var mapCells :Array[Vector2i]

var tileMap
var oddq_directions = [
	[[+1,  0], [+1, -1], [ 0, -1], 
	[-1, -1], [-1,  0], [ 0, +1]],
	[[+1, +1], [+1,  0], [ 0, -1], 
	[-1,  0], [-1, +1], [ 0, +1]],
]

var grid: Array
var open_list: Array = []
var closed_list: Array = []
var solidList: Array = []
var passableList: Array = []
var unitList: Dictionary = {}

var weight
var lowest_f_cost = INF
var lowest_node = null

func reinit():
	_init(tileMap)

func _init(map):
	tileMap = map
	mapRect = tileMap.get_used_rect()
	
	if map is GameMap: 
		mapSize = tileMap.mapSize
		mapCells = tileMap.ground.get_used_cells()
	elif map is TileMapLayer: mapCells = tileMap.get_used_cells()
	#tileSize = tileMap.tileSize
	#lowest_f_cost
	#lowest_node

##New Code
#region
func find_all_unit_paths(unit : Unit, customCell:Vector2i = unit.cell, leash : int = unit.active_stats.Move) -> Array:
	var path : Array
	_set_units()
	_sort_solids() 
	_sort_hostiles(unit)
	_sort_walls(unit)
	path = find_all_paths(customCell, leash, unit) #searches all paths, blocking solids
	path = _remove_passable(path) #removes passable tiles as valid selections without blocking
	return path


func find_remaining_unit_paths(unit : Unit, wayPoint:Vector2i, moveRemain: int) -> Array:
	var path : Array
	_set_units()
	_sort_solids() 
	_sort_hostiles(unit)
	_sort_walls(unit)
	path = find_all_paths(wayPoint, moveRemain, unit) #searches all paths, blocking solids
	path = _remove_passable(path) #removes passable tiles as valid selections without blocking
	return path

##Reach = {"Max":int,"Min":int}
func find_units_in_reach(unit:Unit, reach:Dictionary, targetFaction:int) -> Array:
	var unitsNear :=[]
	var area : Array = []
	var underMin : Array = []
	#var mainFaction = unit.FACTION_ID
	_sort_solids()
	_set_units()
	area = find_all_paths(unit.cell, reach.Max)
	underMin = find_all_paths(unit.cell, clampi(reach.Min-1, 0, INF))
	
	for cell in unitList:
			if !area.has(cell) or underMin.has(cell):
				continue
			elif unitList[cell].FACTION_ID == targetFaction:
				unitsNear.append({"Unit":unitList[cell],"Cell":cell})
	
	return unitsNear


func find_doors_in_reach(unit:Unit, reach:Dictionary, targetFaction:int) -> Array:
	var objectsNear :=[]
	var area : Array = []
	var underMin : Array = []
	#var mainFaction = unit.FACTION_ID
	area = find_aura(unit.cell, reach.Max)
	#underMin = find_all_paths(unit.cell, clampi(reach.Min-1, 0, INF))
	for cell in tileMap.doors:
			if !area.has(cell):
				continue
			elif tileMap.doors[cell].faction_id == targetFaction:
				objectsNear.append({"Object":tileMap.doors[cell],"Cell":cell})
	return objectsNear
	

func find_chests_in_reach(unit:Unit, reach:Dictionary, targetFaction:int) -> Array:
	var objectsNear :=[]
	var area : Array = []
	var underMin : Array = []
	#var mainFaction = unit.FACTION_ID
	area = find_all_paths(unit.cell, reach.Max)
	#underMin = find_all_paths(unit.cell, clampi(reach.Min-1, 0, INF))
	for cell in tileMap.chests:
			if !area.has(cell):
				continue
			elif tileMap.chests[cell].faction_id == targetFaction:
				objectsNear.append({"Object":tileMap.chests[cell],"Cell":cell})
	return objectsNear


func _set_units(units:Dictionary = tileMap.get_active_units()) -> void:
	if !units:
		print_rich("[color=red]Missing tileMap, Invalid tileMap, or tileMap has no units.[/color]") 
		return
	unitList = units


func clear_lists():
	solidList = []
	passableList = []
	unitList  = {}


func _sort_solids(walls:Dictionary = tileMap.get_walls()):
	solidList.append_array(walls.Wall)
		


func _sort_hostiles(unit: Unit) -> void:
	var mainFaction = unit.FACTION_ID
	
	for cell in unitList:
			if !_is_hostile(mainFaction, unitList[cell]):
				passableList.append(cell)
			elif unit.move_type == Enums.MOVE_TYPE.FLY or unit.search_passive_id(Enums.PASSIVE_TYPE.PASS): 
				passableList.append(cell)
			else:
				solidList.append(cell)


func _sort_walls(unit : Unit = null, walls : Dictionary = tileMap.get_walls()): #With another function you can nest anywhere
	if unit and unit.move_type == Enums.MOVE_TYPE.FLY:
		passableList.append_array(walls.WallFly)
	else: solidList.append_array(walls.WallFly)
	solidList.append_array(walls.WallShoot)


#func _get_doors(unit:Unit)->Array:
	#var solidDoors:Array=[]
	#var unitFact:= unit.FACTION_ID
	#var team:Enums.FACTION_ID
	#if unitFact == Enums.FACTION_ID.ENEMY:
		#team = Enums.FACTION_ID.ENEMY
	#else:
		#team = Enums.FACTION_ID.PLAYER
	#for cell in tileMap.doors:
		#if tileMap.doors[cell].faction_id != team: solidDoors.append(cell)
	#return solidDoors


func _is_hostile(compare, unit:Unit) -> bool:
	var faction = unit.FACTION_ID
	if faction == Enums.FACTION_ID.ENEMY and compare == Enums.FACTION_ID.ENEMY:
		return false
	elif faction != Enums.FACTION_ID.ENEMY and compare != Enums.FACTION_ID.ENEMY:
		return false
	else:
		return true


func _remove_passable(path:Array)->Array:
	var newPath := []
	for hex in path:
		if !passableList.has(hex):
			newPath.append(hex)
	return newPath
#endregion
	

##MODIFIED CODE CUT OFF
#region
func find_all_paths(start: Vector2i, maxCost: int, unit = false) -> Array:
	var visited: Array = []
	visited.append({"node": start, "cost": 0, "paths": [[]]})
	
	var queue: Array = []
	queue.append(start)
	
	var result: Array = []
	
	while queue.size() > 0:
		var currentNode = queue.pop_front()
		var currentInfo = get_visited_info(visited, currentNode)
		var currentCost = currentInfo.cost
		var currentPaths = currentInfo.paths
		
		result.append({ "node": currentNode, "paths": currentPaths })
		
		if currentCost >= maxCost:
			continue
			
		for neighbor in get_BFS_nhbr(currentNode, false, unit):
			var neighborInfo = get_visited_info(visited, neighbor)
			var neighborCost = currentCost + compute_cost(currentNode, neighbor, unit)
			if neighborCost > maxCost:
				continue
			if neighborInfo == {}  or neighborCost < neighborInfo["cost"]:
				var neighbor_paths = []
				if neighborInfo != {} and neighborCost < neighborInfo["cost"]:
					neighborInfo["cost"] = neighborCost
					neighborInfo["paths"] = []
				else:
					visited.append({ "node": neighbor, "cost": neighborCost, "paths": neighbor_paths })
					neighborInfo = visited[-1]
				
				for path in currentPaths:
					var newPath = path + [neighbor]
					neighborInfo["paths"].append(newPath)
					
				queue.append(neighbor)

	result = dict_strip(result)
	return result


func get_BFS_nhbr(hex: Vector2i, justNhbrs = false, unit = null) -> Array:
#	print("??")
	var neighbors = []
	var q = hex.x
	var _r = hex.y
	
	# Calculate the offsets based on odd-q hexagon grid rules
	var offsets = _get_offsets(q)
		
		
	if justNhbrs: #Not Verified
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
			if _check_valid_step(hex, neighbor, unit):
				neighbors.append(neighbor)
				
		return neighbors


func get_neighbor_nodes(hex: Dictionary, unit = null) -> Array:
	var neighbors = []
	var q = hex.node.x
	var _r = hex.node.y
	var offsets = _get_offsets(q)
	
	# Get the neighboring nodes based on the offsets
	for offsetH in offsets:
		var neighbor = hex.duplicate()
		neighbor.node += offsetH
#		print("hex ", hex.node, " nhbr ", neighbor.node)
		# Check if the neighbor is valid
		if _check_valid_step(hex.node, neighbor.node, unit):
			neighbors.append(neighbor)
		#if !attack:
			#if is_valid_position(neighbor.node) and !_is_solid_check(neighbor.node):
				#neighbors.append(neighbor)
		#else:
			#if is_valid_position(neighbor.node):
				#neighbors.append(neighbor)
			
	return neighbors


func _check_valid_nhbr(hex) -> bool:
		if is_valid_position(hex) and !_is_solid_check(hex):
			return true
		else:
			return false


func _check_valid_step(from_cell: Vector2i, to_cell: Vector2i, unit = null) -> bool:
	if !_check_valid_nhbr(to_cell):
		return false
	if is_movement_blocked_by_directional_wall(from_cell, to_cell, unit):
		return false
	return true


func _slam_check(hex):
	if is_valid_position(hex) and !_is_occupied_check(hex):
		return false
	else:
		return true


func is_valid_position(neighbor): #not modified, was fine
	var valid
	if !mapCells.has(neighbor): valid = false
	#if neighbor.x >= mapSize.x or neighbor.y >= mapSize.y:
		#valid = false
	#elif neighbor.x < 0 or neighbor.y < 0:
		#valid = false
	else:
		valid = true
	return valid


func _is_solid_check(cell: Vector2i): #not modified, was fine
	if solidList.has(cell): return true
	else: return false


func _is_occupied_check(cell: Vector2i):
	if solidList.has(cell) or passableList.has(cell): return true
	else: return false


##Can sort of function for longer distances, but only accurate for next Hex over when terrain is involved
func compute_cost(a: Vector2i, b: Vector2i, unit = false) -> float:
	
	var tileWeight = 1.0
	var moveType := 0
	var ac = oddq_to_axial(a)
	var bc = oddq_to_axial(b)
	var distance = axial_distance(ac, bc)
	var final = 0
	if unit: 
		moveType = unit.move_type
		tileWeight += tileMap.get_movement_cost(b, moveType)
	
	
	if unit and passableList.has(b) and unitList.get(b, false) and _is_hostile(unit.FACTION_ID, unitList.get(b, false)):
		tileWeight += _get_passby_cost(unit, moveType)
	elif unit and passableList.has(b) and !unitList.get(b, false):
		tileWeight += _get_passby_cost(unit, moveType)
		
	final = distance * tileWeight
	
	return final


func _get_passby_cost(unit:Unit, moveType) -> float:
	var cost:= 0.0
	if unit.search_passive_id(Enums.PASSIVE_TYPE.PASS): cost = 0.0
	elif moveType == Enums.MOVE_TYPE.FLY: cost = 1.0
	else: cost = 1.0
	
	return cost


func find_path(start: Vector2i, end: Vector2i, unit = false,) -> Array[Vector2i]: 
	open_list.clear()
	closed_list.clear()
	var start_node = start #/ tileSize
	var endNode = end #/ tileSize
	var initial_f_cost = 0.0
	var initial_g_cost = 0.0
	var initial_h_cost = 0.0
	var parent = null
	
	add_to_open_list(start_node, initial_f_cost, initial_g_cost, initial_h_cost, parent)
	while open_list.size() > 0:
		var currentNode = get_lowest_f_cost_node()

		
			
		open_list.erase(currentNode)
		closed_list.append(currentNode.node)
		if currentNode.node == endNode:
#			print("PathTest: ", reconstruct_path(currentNode))
			return reconstruct_path(currentNode)

		var neighbors = get_neighbor_nodes(currentNode, unit)
		for neighbor in neighbors:
			if neighbor in closed_list:
				continue
#		for neighbor in get_neighbor_nodes(currentNode.node):
#			if closed_list.find(neighbor) != -1:
#				continue
				
				
			var g_cost = currentNode.g_cost + compute_cost(currentNode.node, neighbor.node, unit)
			var h_cost = compute_cost(neighbor.node, endNode, unit)
			var f_cost = g_cost + h_cost
			
			
			var neighbor_node = neighbor
			
			if neighbor_node not in open_list or f_cost < neighbor_node.f_cost:
				neighbor_node.g_cost = g_cost
				neighbor_node.h_cost = h_cost
				neighbor_node.f_cost = f_cost
				neighbor_node.parent = currentNode
						
				if neighbor_node not in open_list:
					open_list.append(neighbor_node)
	
	return [] # Path not found
#endregion

##Utility functions
#region
func _get_offsets(x) -> Array:
	# Calculate the offsets based on odd-q hexagon grid rules
	var offsets := []
	if fposmod(x, 2) == 0:
		offsets = [
			Vector2i(1, -1), 
			Vector2i(1, 0), 
			Vector2i(0, 1), 
			Vector2i(-1, 0), 
			Vector2i(-1, -1), 
			Vector2i(0, -1)  
		]
	else:
		# odd row
		offsets = [
			Vector2i(1, 0),  
			Vector2i(1, 1),
			Vector2i(0, 1), 
			Vector2i(-1, 1), 
			Vector2i(-1, 0),  
			Vector2i(0, -1)   
		]
	return offsets


func get_wall_bit_between(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var delta := to_cell - from_cell
	var offsets := _get_offsets(from_cell.x)
	for index in offsets.size():
		if offsets[index] == delta:
			return int(WALL_BITS_BY_OFFSET_INDEX[index])
	return 0


func get_opposite_wall_bit(wall_bit: int) -> int:
	return int(WALL_OPPOSITES.get(wall_bit, 0))


func get_wall_mask(cell: Vector2i) -> int:
	if tileMap != null and tileMap.has_method("get_wall_direction"):
		return int(tileMap.get_wall_direction(cell))
	return 0


func get_wall_type(cell: Vector2i) -> StringName:
	if tileMap != null and tileMap.has_method("get_wall_type"):
		return StringName(tileMap.get_wall_type(cell))
	return &""


func has_directional_wall_between(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var from_wall_bit := get_wall_bit_between(from_cell, to_cell)
	if from_wall_bit == 0:
		return false
	var to_wall_bit := get_opposite_wall_bit(from_wall_bit)
	var from_wall_mask := get_wall_mask(from_cell)
	var to_wall_mask := get_wall_mask(to_cell)
	return (from_wall_mask & from_wall_bit) != 0 or (to_wall_mask & to_wall_bit) != 0


func _get_directional_wall_types_between(from_cell: Vector2i, to_cell: Vector2i) -> Array[StringName]:
	var wall_types: Array[StringName] = []
	var from_wall_bit := get_wall_bit_between(from_cell, to_cell)
	if from_wall_bit == 0:
		return wall_types
	var to_wall_bit := get_opposite_wall_bit(from_wall_bit)
	if (get_wall_mask(from_cell) & from_wall_bit) != 0:
		var from_type := get_wall_type(from_cell)
		if from_type != &"":
			wall_types.append(from_type)
	if (get_wall_mask(to_cell) & to_wall_bit) != 0:
		var to_type := get_wall_type(to_cell)
		if to_type != &"":
			wall_types.append(to_type)
	return wall_types


func is_movement_blocked_by_directional_wall(from_cell: Vector2i, to_cell: Vector2i, unit = null) -> bool:
	var wall_types := _get_directional_wall_types_between(from_cell, to_cell)
	if wall_types.is_empty():
		return false
	var can_fly: bool = unit != null and unit is Unit and unit.move_type == Enums.MOVE_TYPE.FLY
	for wall_type in wall_types:
		match wall_type:
			WALL_TYPE_FLY_PASS:
				if !can_fly:
					return true
			WALL_TYPE_BLOCK_ALL, WALL_TYPE_SHOOT_PASS:
				return true
			_:
				return true
	return false


func is_targeting_blocked_by_directional_wall(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var wall_types := _get_directional_wall_types_between(from_cell, to_cell)
	if wall_types.is_empty():
		return false
	return wall_types.has(WALL_TYPE_BLOCK_ALL)


func is_target_line_blocked(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if from_cell == to_cell:
		return false
	var line_start := _cell_center(from_cell)
	var line_end := _cell_center(to_cell)
	if _line_exits_or_enters_blocked_corner(line_start, line_end, from_cell):
		return true
	if _line_exits_or_enters_blocked_corner(line_start, line_end, to_cell):
		return true
	for wall_cell in mapCells:
		if get_wall_type(wall_cell) != WALL_TYPE_BLOCK_ALL:
			continue
		var wall_mask := get_wall_mask(wall_cell)
		if wall_mask == 0:
			continue
		if wall_cell != from_cell and wall_cell != to_cell and _line_touches_sealed_wall_corner(line_start, line_end, wall_cell, wall_mask):
			return true
		var wall_center := _cell_center(wall_cell)
		for wall_bit in WALL_EDGE_POINTS:
			if (wall_mask & int(wall_bit)) == 0:
				continue
			var points: Array = WALL_EDGE_POINTS[wall_bit]
			var edge_start: Vector2 = wall_center + points[0]
			var edge_end: Vector2 = wall_center + points[1]
			if _segments_cross(line_start, line_end, edge_start, edge_end):
				return true
	return false


func _line_exits_or_enters_blocked_corner(line_start: Vector2, line_end: Vector2, cell: Vector2i) -> bool:
	if get_wall_type(cell) != WALL_TYPE_BLOCK_ALL:
		return false
	var wall_mask := get_wall_mask(cell)
	if wall_mask == 0:
		return false
	var cell_center := _cell_center(cell)
	for corner_name in WALL_CORNER_POINTS:
		var corner_point: Vector2 = cell_center + WALL_CORNER_POINTS[corner_name]
		if !_point_on_segment(line_start, line_end, corner_point):
			continue
		var blocked_edges := 0
		for wall_bit in WALL_CORNER_BITS[corner_name]:
			if (wall_mask & int(wall_bit)) != 0:
				blocked_edges += 1
		if blocked_edges >= 2:
			return true
	return false


func _line_touches_sealed_wall_corner(line_start: Vector2, line_end: Vector2, cell: Vector2i, wall_mask: int) -> bool:
	var cell_center := _cell_center(cell)
	for corner_name in WALL_CORNER_POINTS:
		var corner_point: Vector2 = cell_center + WALL_CORNER_POINTS[corner_name]
		if !_point_on_segment(line_start, line_end, corner_point):
			continue
		var blocked_edges := 0
		for wall_bit in WALL_CORNER_BITS[corner_name]:
			if (wall_mask & int(wall_bit)) != 0:
				blocked_edges += 1
		if blocked_edges >= 2:
			return true
	return false


func _cell_center(cell: Vector2i) -> Vector2:
	if tileMap != null and tileMap.has_method("map_to_local"):
		return tileMap.map_to_local(cell)
	return Vector2(cell)


func _point_on_segment(a: Vector2, b: Vector2, point: Vector2) -> bool:
	var orientation := absf(_segment_orientation(a, b, point))
	if orientation > 0.001:
		return false
	var min_x := minf(a.x, b.x) - 0.001
	var max_x := maxf(a.x, b.x) + 0.001
	var min_y := minf(a.y, b.y) - 0.001
	var max_y := maxf(a.y, b.y) + 0.001
	return point.x >= min_x and point.x <= max_x and point.y >= min_y and point.y <= max_y


func _segments_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 := _segment_orientation(a, b, c)
	var o2 := _segment_orientation(a, b, d)
	var o3 := _segment_orientation(c, d, a)
	var o4 := _segment_orientation(c, d, b)
	# Only a proper crossing blocks targeting. Touching a corner or riding along
	# a wall edge is allowed, which preserves corner-shot lines.
	return o1 * o2 < 0.0 and o3 * o4 < 0.0


func _segment_orientation(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)


func axial_substract(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i(a.x - b.x, a.y - b.y)


func axial_distance(a: Vector2i, b: Vector2i) -> int:
	var vec = axial_substract(a, b)
	return int((abs(vec.x) + abs(vec.x + vec.y) + abs(vec.y)) / 2)


func oddq_to_axial(hex: Vector2i) -> Vector2i:
	var x = hex.x
	var y = hex.y - (hex.x - fposmod(hex.x, 2)) / 2
#	print(" O2A ", y)
	return Vector2i(x, y)


func axial_to_oddq(hex: Vector2i) -> Vector2i:
	var x = hex.x
	var y = hex.y + (hex.x - fposmod(hex.x, 2)) / 2
	return Vector2i(x, y)


func dict_strip(dict):
	var strip: Array = []
	for page in dict:
		strip.append(page.node)
	return strip

func reconstruct_path(node: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var currentNode = node
	while currentNode.parent != null:
		path.insert(0, currentNode.node)
		currentNode = currentNode.parent
	path.insert(0, currentNode.node)
	currentNode = currentNode.parent
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


func get_visited_info(visited: Array, node: Vector2i) -> Dictionary:
	for info in visited:
		if info["node"]== node:
			return info
	return {}

func add_to_open_list(node: Vector2i, f_cost: float, g_cost: float, h_cost: float, _parent) -> void:
		var firstNode = {"node" : node, "f_cost": f_cost, "g_cost": g_cost, "h_cost": h_cost, "parent": null}
		open_list.append(firstNode)


#endregion


func is_units_check(cell): 
	if unitList.has(cell):
		return unitList[cell]
	else:
		return false

	
func find_aura(start: Vector2i, max_cost: int) -> Array: #HERE
#	var visited: Dictionary = {}
#	visited[start] = { "cost": 0, "paths": [[]] }
	
	var visited: Array = []
	visited.append({"node": start, "cost": 0, "paths": [[]]})
	
	var queue: Array = []
	queue.append(start)
	
	var result: Array = []
	
	while queue.size() > 0:
		var currentNode = queue.pop_front()
		var currentInfo = get_visited_info(visited, currentNode)
		var currentCost = currentInfo.cost
		var currentPaths = currentInfo.paths
		
		result.append({ "node": currentNode, "paths": currentPaths })
		
		if currentCost >= max_cost:
			continue
			
		for neighbor in get_BFS_nhbr(currentNode, true):
			var neighborInfo = get_visited_info(visited, neighbor)
			var neighborCost = currentCost + compute_cost(currentNode, neighbor, false)
			if neighborCost > max_cost:
				continue
			if neighborInfo == {}  or neighborCost < neighborInfo["cost"]:
				var neighbor_paths = []
				if neighborInfo != {} and neighborCost < neighborInfo["cost"]:
					neighborInfo["cost"] = neighborCost
					neighborInfo["paths"] = []
				else:
					visited.append({ "node": neighbor, "cost": neighborCost, "paths": neighbor_paths })
					neighborInfo = visited[-1]
				
				for path in currentPaths:
					var newPath = path + [neighbor]
					neighborInfo["paths"].append(newPath)
					
				queue.append(neighbor)

	result = dict_strip(result)
	return result


func find_target_paths(start: Vector2i, max_cost: int) -> Array:
	var result: Array = []
	for cell in mapCells:
		if find_target_distance(start, cell) > max_cost:
			continue
		if is_target_line_blocked(start, cell):
			continue
		result.append(cell)
	return result


func get_target_nhbr(hex: Vector2i) -> Array:
	var neighbors := []
	for offsetH in _get_offsets(hex.x):
		var neighbor: Vector2i = hex + offsetH
		if !is_valid_position(neighbor):
			continue
		if is_targeting_blocked_by_directional_wall(hex, neighbor):
			continue
		neighbors.append(neighbor)
	return neighbors


func find_target_distance(start: Vector2i, target: Vector2i) -> int:
	var ac = oddq_to_axial(start)
	var bc = oddq_to_axial(target)
	return axial_distance(ac, bc)

	

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


func resolve_shove(matchHex, targetHex, neighbors, distance): #for Shove, give target's neighbores and matchHex = actor's hex. for Toss, give actor's neighbors and matchHex = target's hex.
	#if <3 +3 if >= 3 -3
	var i = 0
	var shoveTo
	var isSlam = false
	var travel = 0
	var shoveStopper
	
	if !distance:
		distance = 0
	
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
	if _slam_check(shoveTo):
		isSlam = true
		shoveStopper = shoveTo
		shoveTo = targetHex
	distance -= 1
	while distance > 0 and !isSlam:
		neighbors = get_BFS_nhbr(shoveTo, true)
		if _slam_check(neighbors[i]):
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
#	if _check_valid_nhbr(tossTo, true, false):
#		isSlam = true
#		tossStopper = tossTo
#		tossTo = targetHex
#	var unitCollide = is_units_check(tossStopper)
#	var tossResult = {"Hex": tossTo, "Slam": isSlam, "UniColl": unitCollide}
#	return tossResult



	

	
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
	for wep in current.inventory:
		if current.inventory[wep].LIMIT and current.inventory[wep].USES == 0:
			continue
		maxRange = max(maxRange, current.inventory[wep].MaxRange, maxRange)
		minRange = min(minRange, current.inventory[wep].MinRange, minRange)
	var unitRange = [minRange, maxRange]
	return unitRange
	
func find_threat(walkable:Array, unitRange:Dictionary) -> Array:
	var attackSpaces = []
	var i = 1
	var threatRange = []
	var visited = []
	var maxRange = unitRange.Max
	var minRange = unitRange.Min
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
	var filteredThreatRange := []
	
	for tile in threatRange:
		for cell in walkable:
			var tileRange = compute_cost(cell, tile, false)
			if tileRange >= minRange and !filteredThreatRange.has(tile):
				filteredThreatRange.append(tile)
	return filteredThreatRange

func find_closest(_atkrCell, dfndCell, atkrWalkable, moveType: int):
	var closestCell = null
	var minDist = 1000
	for cell in atkrWalkable:
		var path = find_path(cell, dfndCell, true)
		if path.size() < minDist:
			closestCell = cell
			minDist = path.size()
	return closestCell

func find_distance(start, target,)->int:
	var path = find_path(start, target,)
	path.pop_back()
	return path.size()
	
#bullet.cell, bullet.move, bullet.facing, bullet.moveStyle
#start:Vector2i,move:int,facing:int,moveStyle:String
func get_danmaku_path(bullet) -> Array:
	var path : Array
	
	var moveStyle = bullet.moveStyle
	
	match moveStyle:
		"Line": path = _line(bullet)
		
	return path
	
	
func _line(bullet) -> Array:
	var path := []
	var lastCell = bullet.cell
	var move = bullet.move
	var facing = bullet.facing
	
	for step in move:
		var offSets = _get_offsets(lastCell.x)
		var next = lastCell + offSets[facing]
		if _check_valid_nhbr(next):
			path.append(next)
			lastCell = next
		elif bullet.isPhasing and _slam_check(next):
			path.append(next)
			lastCell = next
		else: 
			path.append(Vector2i(-1,-1))
			break
	#print("Danmaku Path[",path,"]")
	return path
	
func _weave(cell) -> Array:
	var path := []
	var point = cell
	var endX = _find_closest_edge_x(cell)
	
	if endX == 0:
		endX = mapSize.x
		while point.x < endX:
			path.append(point)
			point.x += 1
			
	else:
		while point.x >= endX:
			path.append(point)
			point.x -= 1
	print("Danmaku Path:",path)
	return path


func _find_closest_edge_x(cell):
	var edge
	if cell.x > (mapSize.x/2):
		edge = mapSize.x
	else:
		edge = 0
	
	return edge


#func find_goal(wakka, brother, sinsToxin, youSaySo):
	#var goal
	#var you = "Tidus"
	#var gotcha = 0
	#while goal != "Victory":
		#if !brother.pop_back():
			#match wakka[gotcha]:
				#"Alright": gotcha += 1
				#"Hustle": goal = "victory"
	#if youSaySo:
		#return goal
	#elif sinsToxin.has(you):
		#return

#danmaku pathing
#func find_and_set_direction(cell, anchorCell):
	#var offsets = _get_offsets(cell)
	#var offsetSize = offsets.size()
	#var current_move_vec 
	#var norm_move_vec 
	#var direction_id 
	#
	#lastGlbPosition = _sprite.global_position
#
	#current_move_vec = _sprite.global_position - lastGlbPosition
	#lastGlbPosition = _sprite.global_position
	#
	#norm_move_vec = current_move_vec.normalized()
	#direction_id = int(offsetSize * (norm_move_vec.rotated(PI / offsetSize).angle() + PI) / TAU)
