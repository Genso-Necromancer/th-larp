# runtime_item.gd
# Lightweight runtime wrapper for inventory items.
class_name RuntimeItem
extends RefCounted

var id: String = ""
var resource_path: String = ""  # path to EquipmentData resource
var dur: int = -1
var equipped: bool = false
var temp_remove: bool = false
var is_broken: bool = false
var expendable: bool = false
var breakable: bool = true
var category = null
var sub_group = null
var extra: Dictionary = {}

func from_resource(res: Resource) -> void:
	if res == null: return
	# res should be EquipmentData (or similar)
	id = res.id
	resource_path = res.resource_path if res.has_method("resource_path") else ""
	dur = res.max_dur
	breakable = res.breakable if res.has_method("breakable") else true
	expendable = res.expendable if res.has_method("expendable") else false
	category = res.category if res.has("category") else null
	sub_group = res.sub_category if res.has("sub_category") else null
	extra = res.properties.duplicate(true) if res.has("properties") else {}
