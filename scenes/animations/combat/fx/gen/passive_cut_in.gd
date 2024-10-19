extends Control
class_name PassiveCutIn

func play_action():
	$AnimationPlayer.play("Action")

func set_passive_style(passiveId):
	var stringPath = "passive_name_%s" % [passiveId.to_snake_case()]
	var string = StringGetter.get_string(stringPath)
	var passiveIcon = UnitData.passiveData[passiveId].Icon
	var lbl = $PanelContainer/TextBox/Label
	var icon = $PanelContainer/TextBox/TextureRect
	lbl.set_text(string)
	icon.set_texture(passiveIcon)
	
	
func flip_text():
	var lbl = $PanelContainer/TextBox/Label
	lbl.set_scale(Vector2(-1,1))
	
	
func connect_signal(connector):
	var player = $AnimationPlayer
	player.animation_finished.connect(connector._on_cut_in_finished)
