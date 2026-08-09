extends HBoxContainer
class_name ScrollHBox

@onready var left:EffectScroll= $effect_scroll
@onready var right:EffectScroll= $effect_scroll_flipped

func open_scrolls():
	left.open()
	right.open()

func close_scrolls():
	left.close()
	right.close()
	

func load_effect_labels(cr: CombatResults,
	atk_unit: Unit,
	def_unit: Unit,
	init_action: Dictionary,
	counter_action: Dictionary
):
	left.new_labels(atk_unit,init_action)
	right.new_labels(def_unit,counter_action)
	
