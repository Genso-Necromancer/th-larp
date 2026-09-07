extends Control
class_name item_prompt
signal item_prompt_complete

@onready var button:ItemButton = $PanelContainer/MarginContainer/ItemButton
@onready var hbox:HBoxContainer = $PanelContainer/MarginContainer/CurrencyHBox
@onready var value:RichTextLabel = $PanelContainer/MarginContainer/CurrencyHBox/CurrencyValueLabel

func prompt_item(item:SlotWrapper) ->void:
	button.set_item_text(item)
	button.visible = true
	SignalTower.audio_called.emit("ItemPrompt")
	

func prompt_currency(count:int) -> void:
	hbox.visible = true
	value.set_text(str(count))
	SignalTower.audio_called.emit("ItemPrompt")

func _complete_signal() -> void: item_prompt_complete.emit()
