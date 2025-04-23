extends Node2D
class_name PopText

@export_category("Colors")
@export_group("Damage Text")
@export var _critColor : Color
@export var _critOutline : Color
@export var _grazeColor : Color
@export var _grazeOutline : Color
@export var _damageColor : Color
@export var _damageOutline : Color
@export var _dodgeColor : Color
@export var _dodgeOutline : Color
@export_group("Effect Results")
@export var _resistColor : Color
@export var _resistOutline : Color
@export var _healColor : Color
@export var _healOutline : Color
@export var _cureColor : Color
@export var _cureOutline : Color
@export var _buffColor : Color
@export var _buffOutline : Color
@export var _debuffColor : Color
@export var _debuffOutline : Color
@export var _statusColor : Color
@export var _statusOutline : Color
@export var _compHealColor : Color
@export var _compHealOutline : Color
@export var _compDmgColor : Color
@export var _compDmgOutline : Color

#{NONE, LIFE_STEAL, TIME, BUFF, DEBUFF, STATUS, DAMAGE, HEAL, COMP_HEAL, COMP_DMG, CURE, RELOC, ADD_SKILL, ADD_PASSIVE, MULTI_SWING, MULTI_ROUND, CRIT_BUFF, SLAYER,}

var v := 0



		

func set_value(value):
	v = value

func set_stylized_string(s = "damage"):
	var text = $fxText
	var getter = StringGetter
	var base = "pop_up_template"
	var stringPath = "pop_up_%s"
	var string
	var template
	var finalString
	#var font
	var fColor
	var lColor
	var useValue := true
	var usePhrase := true
	match s:
		"graze": 
			fColor = _grazeColor
			lColor = _grazeOutline
		"crit": 
			fColor = _critColor
			lColor = _critOutline
		"critical_graze":
			fColor = _critColor
			lColor = _critOutline
		"damage": 
			fColor = _damageColor
			lColor = _damageOutline
			usePhrase = false
		"heal": 
			fColor = _healColor
			lColor = _healOutline
			usePhrase = false
		"dodge": 
			fColor = _dodgeColor
			lColor = _dodgeOutline
			useValue = false
			
	#text.add_theme_font_override("font", font)
	stringPath = stringPath % [s]
	string = getter.get_string(stringPath)
	if !usePhrase:
		template = getter.get_template(base)
		finalString = template % [v]
	elif useValue:
		base +=  "_value"
		template = getter.get_template(base)
		finalString = template % [string, v]
	else:
		template = getter.get_template(base)
		finalString = template % [string]
	text.set_text(finalString)
	text.add_theme_color_override("font_color", fColor)
	text.add_theme_color_override("font_outline_color", lColor)
	
func set_effect_result(effectResult):
	var effect = UnitData.effectData[effectResult.EffectId]
	
	var type = effect.type
	var subType = effect.SubType
	var value = 0

	if effectResult.Dmg:
		value = effectResult.Dmg
	elif effectResult.Heal:
		value = effectResult.Heal
	set_value(value)
	if effectResult.Resisted:
		type = false
	_set_effect_style(type, subType)
	
func _set_effect_style(type, subType):
	var EFF_TYPE = Enums.EFFECT_TYPE
	var typeKeys = Enums.EFFECT_TYPE.keys()
	var subKeys = Enums.SUB_TYPE.keys()
	var text = $fxText
	var getter = StringGetter
	var base = "pop_up_template"
	var stringPath = "effect_pop_text_%s"
	var subPath = "effect_pop_text_%s"
	
	var string
	var subString
	var template
	var finalString
	#var font
	var fColor
	var lColor
	var useValue := true
	var usePhrase := true
	var isBuff := false
	var isStatus := false

	if subType:
		subPath = subPath % [subKeys[subType].to_snake_case()]
		subString = getter.get_string(subPath)
		
	if type:
		stringPath = stringPath  % [typeKeys[type].to_snake_case()]
	else:
		stringPath = stringPath % ["resisted"]
		
	string = getter.get_string(stringPath)
	
	match type:
		EFF_TYPE.LIFE_STEAL, EFF_TYPE.HEAL: 
			fColor = _healColor
			lColor = _healOutline
			usePhrase = false
		EFF_TYPE.STATUS: 
			#get subtype colors?
			fColor = _statusColor
			lColor = _statusOutline
			useValue = false
			isStatus = true
		EFF_TYPE.BUFF:
			fColor = _buffColor
			lColor = _buffOutline
			useValue = false
			isBuff = true
		EFF_TYPE.DAMAGE: 
			fColor = _damageColor
			lColor = _damageOutline
			usePhrase = false
		EFF_TYPE.DEBUFF: 
			fColor = _debuffColor
			lColor = _debuffOutline
			useValue = false
			isBuff = true
		EFF_TYPE.COMP_HEAL:
			fColor = _compHealColor
			lColor = _compHealOutline
			usePhrase = false
		EFF_TYPE.COMP_DMG:
			fColor = _compDmgColor
			lColor = _compDmgOutline
			usePhrase = false
		EFF_TYPE.CURE:
			fColor = _cureColor
			lColor = _cureOutline
			useValue = false
		_:
			fColor = _resistColor
			lColor = _resistOutline
			useValue = false
			
	#text.add_theme_font_override("font", font)
	
	if !usePhrase:
		template = getter.get_template(base)
		finalString = template % [v]
	elif useValue:
		base += "_value"
		template = getter.get_template(base)
		finalString = template % [string, v]
	elif isBuff:
		base += "_buff"
		template = getter.get_template(base)
		finalString = template % [subString, string]
	elif isStatus:
		string += "_%s"
		string = string % [subString]
		template = getter.get_template(base)
		finalString = template % [string]
	else:
		template = getter.get_template(base)
		finalString = template % [string]
		
	text.set_text(finalString)
	text.add_theme_color_override("font_color", fColor)
	text.add_theme_color_override("font_outline_color", lColor)
	
func play_action():
	var player = $AnimationPlayer
	
	player.play("float")

func end_all():
	pass

func connect_signal(connector):
	var player = $AnimationPlayer
	player.animation_finished.connect(connector._on_pop_up_finished)
