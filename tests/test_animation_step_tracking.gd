extends SceneTree


func _initialize() -> void:
	var animator := CombatAnimator.new()
	var first := AnimationPlayer.new()
	var second := AnimationPlayer.new()
	animator.begin_step()
	animator._track_player(first)
	animator._track_player(second)
	assert(not animator.is_step_complete())
	first.animation_finished.emit(&"Action")
	assert(not animator.is_step_complete(), "One FX must not finish the whole step")
	second.animation_finished.emit(&"float")
	assert(animator.is_step_complete())

	animator.begin_step()
	animator._track_player(first)
	var old_generation: int = animator._step_generation
	animator.begin_step()
	animator._track_player(second)
	animator._visual_finished(&"Action", second, old_generation)
	assert(not animator.is_step_complete(), "Stale callbacks must not finish a new step")
	first.animation_finished.emit(&"Action")
	assert(not animator.is_step_complete())
	second.animation_finished.emit(&"float")
	assert(animator.is_step_complete())
	first.free()
	second.free()
	animator.free()
	print("Animation step tracking checks passed")
	quit()
