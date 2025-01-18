extends HBoxContainer
class_name EffectList

var path = preload("res://scenes/GUI/effect_label.tscn")

func _ready():
	_close_all_effects()


func _close_all_effects():
	$TargetBox.visible = false
	$SelfBox.visible = false
	$GlobalBox.visible = false
	$PassiveBox.visible = false
	$SkillBox.visible = false
	get_tree().set_group("EffectSeparators", "visible", false)


func update_effects(source):
	var type = get_meta("Type")
	_clear_old()
	match type:
		"Item": _set_item_text(UnitData.itemData[source])
		"Skill": _set_skill_text(UnitData.skillData[source])


func _set_item_text(data) -> void:
	var string : String
	#var strings : Array = []
	var selfEff : Array = []
	var targEff : Array = []
	var globEff : Array = []
	var skillEff: Array = []
	var passEff: Array = []
		
	for effId in data.Effects:
		string = "%s" % StringGetter.get_effect_string(effId)
		
		match UnitData.effectData[effId].Type:
			Enums.EFFECT_TYPE.ADD_SKILL:
				skillEff.append(string)
				continue
			Enums.EFFECT_TYPE.ADD_PASSIVE:
				passEff.append(string)
				continue
			_: pass
			
		match UnitData.effectData[effId].Target:
			Enums.EFFECT_TARGET.SELF, Enums.EFFECT_TARGET.EQUIPPED: selfEff.append(string)
			Enums.EFFECT_TARGET.TARGET: targEff.append(string)
			Enums.EFFECT_TARGET.GLOBAL: globEff.append(string)
			
	if targEff.size() > 0:
		_add_effect_labels(targEff, 0)
	
	if selfEff.size() > 0:
		_add_effect_labels(selfEff, 1)
	
	if globEff.size() > 0:
		_add_effect_labels(globEff, 2)
	
	if skillEff.size() > 0:
		_add_effect_labels(globEff, 3)
	
	if passEff.size() > 0:
		_add_effect_labels(globEff, 4)
	


func _set_skill_text(data):
	pass


func _add_effect_labels(effects, mode : int):
	var container : GridContainer
	
	match mode:
		0: 
			$TargetBox.visible = true
			container = $TargetBox/TargetContainer
		1: 
			$SelfBox.visible = true
			container = $SelfBox/SelfContainer
			#if $TargetBox.visible:
				#$VSeparator.visible = true
		2: 
			$GlobalBox.visible = true
			container = $GlobalBox/GlobalContainer
			if $TargetBox.visible or $SelfBox.visible:
				$VSeparator2.visible = true
		3:
			$PassiveBox.visible = true
			container = $PassiveBox/PassiveContainer
			if $TargetBox.visible or $SelfBox.visible or $GlobalBox.visible:
				$VSeparator3.visible = true
		4: 
			$SkillBox.visible = true
			container = $SkillBox/SkillContainer
			if $TargetBox.visible or $SelfBox.visible or $GlobalBox.visible or $SkillBox.visible:
				$VSeparator4.visible = true
			
	for e in effects:
		var l = path.instantiate()
		l.set_text(e)
		container.add_child(l)


func _clear_old():
	_close_all_effects()
	var kids = $TargetBox/TargetContainer.get_children() + $SelfBox/SelfContainer.get_children() + $GlobalBox/GlobalContainer.get_children() + $PassiveBox/PassiveContainer.get_children()
	for kid in kids:
		kid.queue_free()

