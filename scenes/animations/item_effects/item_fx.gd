extends AnimatedSprite2D
class_name ItemFx

signal itemfx_complete




func _ready():
	SignalTower.prompt_accepted.connect(self._on_prompt_accepted)



func play_item(item:Item, scaleUp := false): #consider utilizing the effect popText scene to clarify what effect occured
	var effKeys :Array= Enums.EFFECT_TYPE.keys()
	var pathFormat := "res://scenes/animations/item_effects/%s.tres"
	
	if scaleUp:
		scale = Vector2(5,5)
	
	for effect in item.effects:
		var effKey :String = effKeys[effect.type].to_snake_case()
		var path := pathFormat % [effKey]
		if !ResourceLoader.exists(path): 
			effKey = "Buff"
		path = pathFormat % [effKey]
		set_sprite_frames(load(path))
		play(effKey.to_pascal_case())
		await self.animation_finished
	self_destruct()

func _on_prompt_accepted():
	if is_playing():
		set_frame_progress(1.0)


func self_destruct():
	emit_signal("itemfx_complete")
	queue_free()
