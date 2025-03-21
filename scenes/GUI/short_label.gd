extends Label
##script for simple, single string, labels to update themselves
class_name ShortLabel


##Name of node must match it's desired key
func update_yourself_now():
	var path : String = "terrain_label_%s" % [name.to_lower()]
	set_text(StringGetter.get_string(path))
	
	
