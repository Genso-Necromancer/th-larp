extends Area2D
class_name TileArea

@export var master:InteractableTile

func get_master():
	if master: return master
	else: printerr("[%s]:TileArea, no mater found" % [self.to_string()])
