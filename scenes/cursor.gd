@tool
class_name Cursor
extends Node2D

@onready var cursorSprite: Sprite2D = $Sprite2D
var canter = false
## Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO
