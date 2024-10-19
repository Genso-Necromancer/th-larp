extends Area2D

var master : Unit
var aura = false

func set_master(unit: Unit):
	master = unit

func get_master() -> Unit:
	if !master:
		print(self, "[No Master!]")
		return
	return master
	
