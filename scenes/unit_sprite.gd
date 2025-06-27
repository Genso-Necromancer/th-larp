extends Sprite2D
var sprite_path :String


func _ready():
	sprite_path = $"../..".artPaths.Sprite
	if sprite_path and !get_texture(): set_texture(load(sprite_path))
