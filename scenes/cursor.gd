#This is just the gameboard cursor for selecting units see "menu_cursor" for the one used in menus
@tool
class_name Cursor
extends Node2D

signal jobs_done_crsr

@onready var cursorSprite: Sprite2D = $Sprite2D
#do I even need this?
var canter = false
# Coordinates of the current cell the cursor is hovering.
var cell := Vector2i.ZERO

#func _ready():
	#var parent = get_parent()
	#self.jobs_done_crsr.connect(parent._on_jobs_done)
	#emit_signal("jobs_done_crsr", "Cursor", self)

func align_camera():
	var camera = $Camera2D
	camera.align()
