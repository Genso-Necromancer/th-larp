extends Control
class_name SkillCutIn

func play_action():
	$AnimationPlayer.play("Action")

func set_skill_style(skillId):
	var stringPath = "skill_name_%s" % [skillId.to_snake_case()]
	var string = StringGetter.get_string(stringPath)
	var skillIcon = UnitData.skillData[skillId].Icon
	var lbl = $PanelContainer/MarginContainer/HBoxContainer/SkillName
	var icon1 = $PanelContainer/MarginContainer/HBoxContainer/LeftCrest
	var icon2 = $PanelContainer/MarginContainer/HBoxContainer/RightCrest
	lbl.set_text(string)
	icon1.set_texture(skillIcon)
	icon2.set_texture(skillIcon)
	
	
func flip_text():
	var lbl = $PanelContainer/TextBox/Label
	lbl.set_scale(Vector2(-1,1))
	
	
func connect_signal(connector):
	var player = $AnimationPlayer
	player.animation_finished.connect(connector._on_cut_in_finished)
