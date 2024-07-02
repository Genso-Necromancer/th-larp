extends TextureRect


func _ready():
	var timeRotation = Global.gameTime * 15
	rotation_degrees = timeRotation
