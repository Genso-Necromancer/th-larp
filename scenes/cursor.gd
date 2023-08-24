#This is just the gameboard cursor for selecting units see "menu_cursor" for the one used in menus
@tool
class_name Cursor
extends Node2D
@onready var cursorSprite: Sprite2D = $Sprite2D
#do I even need this?
var canter = false
# Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO
