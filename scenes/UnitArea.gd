extends Area2D

var master
var aura = false

func set_master(unit):
	master = unit

func get_master():
	if !master:
		print(self, "[No Master!]")
		return
	return master
	
