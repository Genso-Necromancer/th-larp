extends Panel
class_name PopUp

@export var offSet : Vector2 = Vector2(0,0)

func _init():
	hide_pop()


func deploy_pop(button):
	var bPos = button.get_global_position()
	var bSize = button.size
	var newPos = Vector2(bPos.x + bSize.x, bPos.y) + offSet
	self.visible = true
	get_child(0).set_global_position(newPos)
	

func hide_pop():
	self.visible = false
