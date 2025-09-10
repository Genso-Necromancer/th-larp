@tool
extends Sprite2D
var sprite_path :String
@onready var unit: Unit = $"../.."


func _ready():
	refresh_self()


func refresh_self():
	#print("fuck")
	sprite_path = $"../..".artPaths.Sprite
	#print("Sprite: ",sprite_path)
	if sprite_path:
		set_texture(load(sprite_path))
		match unit.FACTION_ID:
			Enums.FACTION_ID.ENEMY: self_modulate = Color.RED
			Enums.FACTION_ID.PLAYER: self_modulate = Color(1, 1, 1)
