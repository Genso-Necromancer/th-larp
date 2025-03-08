@tool
extends Node


signal prompt_accepted
signal focus_unit_changed(unit : Unit)
signal inventory_weapon_changed(button : ItemButton)
signal action_weapon_selected(button : ItemButton)
signal action_skill_confirmed()
signal forecast_predicted(fcData : Dictionary)
signal sequence_initiated(sequence:Dictionary)
signal sequence_complete
