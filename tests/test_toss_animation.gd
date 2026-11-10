extends SceneTree


class TestUnit:
	extends Unit
	var inactive := false

	func _ready() -> void:
		pass

	func _process(_delta: float) -> void:
		pass

	func check_status(condition: String) -> bool:
		return inactive and condition == "Acted"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var unit := TestUnit.new()
	unit.curve = Curve2D.new()
	var follow := PathFollow2D.new()
	follow.name = "PathFollow2D"
	unit.add_child(follow)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.hframes = 2
	sprite.vframes = 15
	follow.add_child(sprite)
	var bar := TextureProgressBar.new()
	bar.name = "HPbar"
	bar.max_value = 0
	sprite.add_child(bar)
	var fx := SpriteFXHandler.new()
	fx.name = "SpriteFxHandler"
	unit.add_child(fx)
	fx.owner = unit
	fx.unique_name_in_owner = true
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	sprite.add_child(player)
	player.owner = unit
	player.unique_name_in_owner = true
	player.root_node = NodePath("../../..")
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	player.add_animation_library("", load("res://scenes/unit_anim.tres"))
	player.animation_finished.connect(unit._on_animation_player_animation_finished)
	root.add_child(unit)
	unit.active_stats = {"Life": 20}
	unit._toss_pending = true
	unit.current_life = 20
	unit.update_life_bar()
	await create_timer(0.6).timeout
	assert(bar.max_value == 20 and bar.value == 20, "HP bar did not initialize from Life")

	for animation in ["tossed_from_left", "tossed_from_right"]:
		unit._toss_pending = true
		unit._toss_path_finished = false
		unit._toss_animation_finished = false
		unit.lastAnim = "idle"
		unit.pathPaused = false
		player.play(animation)
		for inactive in [false, true]:
			unit.inactive = inactive
			unit.update_sprite()
			unit.refresh_state_visual()
			unit.isSelected = false
			unit.revert_animation()
			assert(player.current_animation == animation, "State refresh interrupted toss")
		unit.inactive = false
		unit.hp_changed = -5
		unit.current_life = 15
		player.advance(2.0)
		assert(player.current_animation == animation, "HP-bar key interrupted toss")
		await create_timer(0.6).timeout
		assert(bar.value == 15, "Toss HP-bar key did not display damage")
		unit.current_life = 20
		unit.hp_changed = 5
		unit.update_life_bar()
		await create_timer(0.6).timeout
		assert(bar.value == 20, "HP bar did not display healing")
		unit.current_life = 0
		unit.update_life_bar()
		await create_timer(0.6).timeout
		assert(bar.value == 0, "HP bar did not display lethal damage")
		assert(not unit.needDeath and unit._toss_pending, "Bar completion ended toss early")
		unit._toss_path_finished = true
		player.advance(0.6)
		assert(not unit._toss_pending, "Toss did not finish after animation and movement")
		assert(player.current_animation == "idle")

	unit.free()
	print("Toss animation interruption checks passed")
	quit()
