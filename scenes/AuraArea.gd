extends Area2D
class_name AuraArea

var master : Unit
var aura : Dictionary
@export var polygon : PackedVector2Array = [Vector2(-40,-24), Vector2(-80,0), Vector2(-40,24), Vector2(40,24), Vector2(80,0), Vector2(40,-24)]
	
	
func set_aura(unit: Unit, auraData: Dictionary):
	var hexStar = AHexGrid2D.new($AuraMap)
	var auraCells : Array
	master = unit
	aura = auraData
	auraCells = hexStar.find_aura(Vector2i(0,0), aura.Range)
	#print("Aura Cells:","[",unit,"]",auraCells)
	if !aura.IsSelf:
		auraCells.erase(Vector2i(0,0))
	if aura.SelfOnly:
			self.area_entered.connect(master._on_self_aura_entered.bind(self))
			self.area_exited.connect(master._on_self_aura_exited.bind(self))
	_place_areas(auraCells)

func _place_areas(cells: Array) -> void:
	var map = $AuraMap
	for cell in cells:
		#print("placing: ", cell)
		var area = CollisionPolygon2D.new()
		var mappos = map.map_to_local(cell)
		var pos = map.to_global(mappos)
		add_child(area)
		area.set_polygon(polygon)
		area.position = pos
		map.queue_free()
		
		
