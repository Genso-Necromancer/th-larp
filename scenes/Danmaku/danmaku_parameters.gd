@tool
extends PathFollow2D
class_name DanmakuType

@export var sprite : CompressedTexture2D:
	set(value):
		$Sprite2D.set_texture(value)
		sprite=value
@export var sfx : bool
@export var move : int = 1
@export var damage : int = 0
@export var cmpDamage : int = 0
@export var speed : int = 250
@export var impact: Array[String] = []
@export var type:StringName = ""

@onready var animPlayer := $Sprite2D/AnimationPlayer
@onready var area2d := $Sprite2D/Area2D

func get_sprite2D() -> Sprite2D:
	return $Sprite2D
