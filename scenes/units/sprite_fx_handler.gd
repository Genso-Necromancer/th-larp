extends Node2D
class_name SpriteFXHandler

signal fx_begins(fx_name:String)
signal fx_ends(fx_name:String)




func play_item_fx(fx_name:String, scale_up:=false):
	var fxPath = "res://scenes/animations/item_effects_sprite/%s_fx.tscn"
	var sprite = $PathFollow2D/Sprite
	var hp = $PathFollow2D/Sprite/HPbar
	var current_fx:AnimationPlayer
	fxPath = fxPath % [fx_name.to_snake_case()]
	if !ResourceLoader.exists(fxPath): 
		print("[fxHanlder/play_item_fx] %s not found" % [fxPath])
		fxPath = "res://scenes/animations/item_effects_sprite/%s_fx.tscn" % ["place_holder"]
	var scene_root = load(fxPath).instantiate()
	if scale_up: scene_root.scale = Vector2(5,5)
	for node in scene_root.get_children(): 
		if node is AnimationPlayer: current_fx = node
	current_fx.animation_finished.connect(self._on_animation_finished.bind(fx_name, scene_root))
	#scene_root.ready.connect(self._on_fx_ready)
	add_child(scene_root)
	current_fx.play("Default")
	fx_begins.emit(fx_name)
	


#func _on_fx_ready():
	#current_fx.play("Default")


func _on_animation_finished(_anim_name:StringName, fx_name:String, scene_root:Node):
	scene_root.queue_free()
	fx_ends.emit(fx_name)
