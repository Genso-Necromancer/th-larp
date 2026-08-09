@tool
extends Control
class_name EffectScroll
@onready var ef_vbox:=$scroll_top/effect_margin/effect_vbox
@onready var anim_player:=$AnimationPlayer
@onready var list:= $scroll_top/effect_margin/effect_vbox
enum STATES {OPEN,CLOSED}
var state:STATES = STATES.CLOSED
func _ready():
	anim_player.animation_finished.connect(cascade_effects)


func open(): 
	anim_player.play("OPEN")
	state = STATES.OPEN

func close():
	_clear_old(list)
	anim_player.play("CLOSE")
	state = STATES.CLOSED

func cascade_effects(anim:String) -> void:
	if anim != "OPEN": return
	var tween = get_tree().create_tween()
	for label in ef_vbox.get_children():
		tween.tween_property(label,"visible",true,0.2)

func new_labels(unit, action):
	_clear_old(list)
	if action != null:
		_add_effects_for_action(action)
	elif state == STATES.OPEN:
		close()

func _clear_old(list):
	var old = list.get_children()
	for l in old:
		l.queue_free()

#Effect Label Handling
func _add_effects_for_action(action):
	if action == null:
		if state == STATES.OPEN:
			close()
		return

	var swings: Array = action.get("swings", [])
	if swings.size() == 0:
		if state == STATES.OPEN:
			close()
		return

	var swing: Dictionary = swings[0]
	var effs: Array = swing.get("effects", [])
	if effs.size() == 0:
		if state == STATES.OPEN:
			close()
		return

	var selfEff: Array = []
	var targEff: Array = []
	var globEff: Array = []

	for rec in effs:
		var e: Effect = rec.get("effect", null)
		if e == null:
			continue
		var s: String = "[center]%s[/center]" % StringGetter.get_combat_effect_string(e)

		match int(e.target):
			Enums.EFFECT_TARGET.GLOBAL: globEff.append(s)
			Enums.EFFECT_TARGET.SELF: selfEff.append(s)
			Enums.EFFECT_TARGET.TARGET: targEff.append(s)
			_:
				# ignore EQUIPPED/NONE for combat forecast
				pass

	if globEff.size() > 0:
		_add_effect_labels(globEff)

	if targEff.size() > 0:
		_add_effect_labels(targEff)

	if selfEff.size() > 0:
		var lbl := RichTextLabel.new()
		var selfString := "[center]%s[/center]" % StringGetter.get_string("effect_target_self")
		Global.set_rich_text_params(lbl)
		lbl.set_text(selfString)
		list.add_child(lbl)
		_add_effect_labels(selfEff)

	if list.get_child_count() > 0:
		open()
	elif state == STATES.OPEN:
		close()

func _add_effect_labels(strings):
	for string in strings:
		var lbl = RichTextLabel.new()
		Global.set_rich_text_params(lbl)
		lbl.set_text(string)
		lbl.visible = false
		list.add_child(lbl)
