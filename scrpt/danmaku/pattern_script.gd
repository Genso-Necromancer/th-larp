extends Resource
class_name PatternScript

var currentStep := 0
var master : Unit
var map : GameMap


var danmakuData : Dictionary = _get_danmaku_data()
@export var danmakuType : int = 0
@export var danmakuPath : Array
var danmakuPattern := [
	{
		"Action": "Spawn",
		"Bullets": [
			{
			"Type": "DmkuKunai",
			"SpawnStyle": "Radius",
			"AnchorType": "Master",
			"Amount": 2,
			"Offset": 1,
			
			}
		],
		
	}
]


func _get_property_list():
	var properties := []
	
	return properties


func _get_danmaku_data():
	var rawData = _raw_data_danmaku()
	var ids = rawData.keys()
	var data := {
		"Texture": preload("res://sprites/danmaku/danmaku.png"),
		"Sfx":"",
		"Move": 4,
		"MoveStyle": "Line",
		"Damage": 0,
		"CmpDamage": 0,
		"Speed": 250,
		"IsPhasing" : true,
		"Impact": ["EffectId1", "EffectId2"],
	}
	var dData := {}
	
	for id in ids:
		dData[id] = data
		for param in rawData[id]:
			dData[id][param] = rawData[id][param]
	return dData
	
func _raw_data_danmaku():
	var danmaku := {
		"DmkuKunai":
			{
				"Texture": preload("res://sprites/danmaku/danmaku.png"),
				"Sfx":"",
				"Move": 4,
				"MoveStyle": "Line",
				"Damage": 5,
				"CmpDamage": 0,
				"Speed": 300,
				"Impact": ["EffectId1", "EffectId2"],
			}
	}
	return danmaku

#func _raw_data_patterns():
	#var patterns := {
		#"DmkuKunai":
			#{
				#"Texture": preload("res://sprites/danmaku/danmaku.png"),
				#"Sfx":"",
				#"Move": 4,
				#"Damage": 0,
				#"CmpDamage": 0,
				#"Speed": 300,
				#"Impact": ["EffectId1", "EffectId2"],
			#}
	#}
	#return patterns

func get_pattern_step():
	var instruct := {}
	var bullets = []
	
	if currentStep >= danmakuPattern.size():
		currentStep = 0
	var step = danmakuPattern[currentStep]
	var a = step.Action
	
	instruct["Action"] = step.Action
	instruct["Bullets"] = []
	if step.Action != "Nothing":
		for bullet in step.Bullets:
			#var spawnCells = _get_spawn_loc(bullet.SpawnStyle, bullet.Offset, bullet.Amount, bullets)
			#bullets.append(spawnCells)
			#instruct.Bullets.append({"Type": bullet.Type, "Cell": spawnCells})
			bullets.append(bullet)
			instruct.Bullets.append(bullet)
	
	
	currentStep += 1
	return instruct


func _get_spawn_loc(style : String, distance : int, Amount: int, bullets) -> Array:
	var zero = master.cell
	var max = map.mapSize
	var loc := Vector2i(0,0)
	var offset := Vector2i(distance, distance)
	var canter := false
	var adjust
	var adjustDis = distance
	var spawnPoints := []
	var count := 0
	match style:
		"Front":
			while count < Amount:
				if max.x - zero.x > zero.x/2:
					#make negative
					
					adjustDis = adjustDis - (adjustDis * 2)
				offset.x = adjustDis
				offset.y = 0
				loc.x = zero.x + offset.x
				loc.y = zero.y + offset.y
				adjust = loc
				while spawnPoints.has(adjust):
					if canter:
						canter = false
						adjust.y = loc.y + adjustDis
					else: adjust.x = loc.x + adjustDis
					adjustDis += 1
					canter = true
					
				loc = adjust
				spawnPoints.append(loc)
				count += 1

	return spawnPoints


	
