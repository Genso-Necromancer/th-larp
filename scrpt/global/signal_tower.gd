@tool
extends Node

###Managment Signals
#signal game_paused(exempt_scene)
signal exiting_game
signal prompt_accepted
signal focus_unit_changed(unit:Unit)
signal focus_danmaku_changed(dmku:Danmaku)
signal returning_to_title
#signal cursor_tile_updated(unit:Unit, tile)

##Unit Action Signals
signal inventory_weapon_changed(button : ItemButton)
signal action_weapon_selected(button : ItemButton)
signal action_skill_confirmed()
signal action_seize(cell:Vector2i)

##Combat Animation Signals
signal forecast_predicted(fcData : Dictionary)
signal sequence_initiated(sequence:Dictionary)
signal sequence_complete

##Time Signals
signal time_changed(time:float)
signal time_reset

##Fader signal chains. ugh.
signal fader_fade_in(speedScale : float)
signal fader_fade_out(speedScale : float)
signal fade_out_complete
signal fade_in_complete

##Audio Ques
signal audio_called(type:String)

##Saving
signal save_called(fileName:String)
signal save_complete
