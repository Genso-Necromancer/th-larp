extends RichTextLabel

class_name ToolTipDisplay

func display_tooltip(toolTip:String) -> RichTextLabel:
	set_text("")
	visible = true
	set_text(toolTip)
	return self
