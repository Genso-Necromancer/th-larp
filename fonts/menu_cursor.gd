extends TextureRect
signal wep_updated
signal jobs_done_crs


@export var cursor_offset : Vector2 = Vector2(25,5)

var currentButton : Button = null
var menu_parent
var menuIndex
var cursor_index : int = 0
var shouldUpdateCursor = false
var currentFocus

func _process(delta):
	set_cursor(currentFocus)

func _ready():
	var parent = get_parent()
	self.jobs_done_crs.connect(parent._on_jobs_done)
	emit_signal("jobs_done_crs", "Cursor", self)


		
func set_cursor(button):
	currentFocus = button
	if button == null:
		return
	var cPosition = button.get_global_position()
	var cSize = button.size
	var newPos
	newPos = Vector2(cPosition.x, cPosition.y + cSize.y / 2.0) - (size / 2.0) - cursor_offset
	set_global_position(newPos)
	
	
	
