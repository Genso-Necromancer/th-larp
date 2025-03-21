@tool
extends Node


signal prompt_accepted
signal focus_unit_changed(unit : Unit)
signal cursor_tile_updated(unit: Unit, tile)
signal inventory_weapon_changed(button : ItemButton)
signal action_weapon_selected(button : ItemButton)
signal action_skill_confirmed()
signal forecast_predicted(fcData : Dictionary)
signal sequence_initiated(sequence:Dictionary)
signal sequence_complete

##Fader signal chains. ugh.
signal fader_fade_in(speedScale : float)
signal fader_fade_out(speedScale : float)
signal fade_out_complete
signal fade_in_complete
