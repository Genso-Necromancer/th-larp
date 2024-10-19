
extends Resource
class_name AnimData


const WEAPON_ANIM := {
	"SLVKNF":{
		"WeaponFx": "res://scenes/animations/combat/fx/weapon/fx_self_knife.tscn", 
		"TargetFx":"res://scenes/animations/combat/fx/weapon/fx_target_knife.tscn", 
		"FxBone": "Head"}, 
	"GNG":{
		"WeaponFx": "res://scenes/animations/combat/fx/weapon/fx_self_knife.tscn", 
		"TargetFx":"res://scenes/animations/combat/fx/weapon/fx_target_knife.tscn", 
		"FxBone": "Head"}}
const SKILL_ANIM := {
	"LifeStealRem":{
		"SkillFx": "res://scenes/animations/combat/fx/skill/fx_self_thirst.tscn", 
		"TargetFx": "res://scenes/animations/combat/fx/skill/fx_target_thirst.tscn", 
		"FxBone": "Head"}}


static func get_weapon_anim():
	return WEAPON_ANIM

static func get_skill_anim():
	return SKILL_ANIM
