extends Control


@onready var turnBar = $ScrollContainer/TurnBar
@onready var turnToken = preload("res://scenes/turn_token.tscn")
@onready var pTexture = preload("res://sprites/UI/PlayerTurn.png")
@onready var eTexture = preload("res://sprites/UI/EnemyTurn.png")
@onready var nTexture = preload("res://sprites/UI/NPCTurn.png")

func _ready():
	self.visible = false
	
	
func display_turns(turnOrder):
	free_tokens()
	for team in turnOrder:
		var token
		token = _instantiate_token(team)
		turnBar.add_child(token)

func _instantiate_token(team):
	var token = turnToken.instantiate()
	var texture
	match team:
		"Player": texture = pTexture
		"Enemy": texture = eTexture
		"NPC": texture = nTexture
	token.set_texture(texture)
	return token

func free_tokens():
	var tokens = turnBar.get_children()
	for token in tokens:
		token.queue_free()
