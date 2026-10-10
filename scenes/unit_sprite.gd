@tool
extends Sprite2D
class_name UnitSprite

const PALETTE_SHADER := preload("res://scenes/units/unit_palette_shift.gdshader")
const PALETTE_SWAP_STRENGTH := 1.0
const PLAYER_PALETTE := [Color("#383890"), Color("#28a0f8"), Color("#18f0f8")]
const ENEMY_PALETTE := [Color("#8c2020"), Color("#e03838"), Color("#ff8a6a")]
const NPC_PALETTE := [Color("#286820"), Color("#32b848"), Color("#90f078")]

var sprite_path :String
var _palette_material: ShaderMaterial
@onready var unit: Unit = $"../.."


func _ready():
	refresh_self()


func refresh_self():
	#print("fuck")
	sprite_path = $"../..".artPaths.Sprite
	#print("Sprite: ",sprite_path)
	if sprite_path:
		set_texture(load(sprite_path))
		_ensure_palette_material()
		apply_faction_visual()


func apply_faction_visual() -> void:
	_ensure_palette_material()
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	match unit.FACTION_ID:
		Enums.FACTION_ID.ENEMY:
			_apply_palette_swap(shader_material, ENEMY_PALETTE, PALETTE_SWAP_STRENGTH)
		Enums.FACTION_ID.NPC:
			_apply_palette_swap(shader_material, NPC_PALETTE, PALETTE_SWAP_STRENGTH)
		_:
			_apply_palette_swap(shader_material, PLAYER_PALETTE, 0.0)


func set_disabled_visual(is_disabled: bool) -> void:
	_ensure_palette_material()
	var shader_material := material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("grayscale_amount", 1.0 if is_disabled else 0.0)


func _ensure_palette_material() -> void:
	if _palette_material != null and material == _palette_material:
		return
	var shader_material := ShaderMaterial.new()
	shader_material.shader = PALETTE_SHADER
	shader_material.resource_local_to_scene = true
	_palette_material = shader_material
	material = shader_material


func _apply_palette_swap(shader_material: ShaderMaterial, palette: Array, strength: float) -> void:
	shader_material.set_shader_parameter("target_dark", palette[0])
	shader_material.set_shader_parameter("target_mid", palette[1])
	shader_material.set_shader_parameter("target_light", palette[2])
	shader_material.set_shader_parameter("palette_strength", strength)
