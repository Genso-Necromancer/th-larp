extends Control
signal jobs_done_hud
@onready var sunDial = $SunDial
@onready var clockLb = $Clock

func _ready():
	var parent = get_parent()
	self.jobs_done_hud.connect(parent._on_jobs_done)
	emit_signal("jobs_done_hud", "HUD", self)

func set_sun(time):
	var rot = Global.rotationFactor * time
	sunDial.rotation_degrees += rot

func update_sun(rot):
	sunDial.rotation_degrees += rot
