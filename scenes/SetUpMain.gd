extends Control
signal jobs_done_setUp

func _ready():
	var parent = get_parent()
	self.jobs_done_setUp.connect(parent._on_jobs_done)
	emit_signal("jobs_done_setUp", "SetUp", self)
