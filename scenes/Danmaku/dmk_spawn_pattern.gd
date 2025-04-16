extends Node2D
class_name DanmakuPattern

enum AnchorTarget{SELF, TARGET}
@export var anchorTarget:AnchorTarget = AnchorTarget.SELF

func get_danmaku()->Array[Danmaku]:
	var children = $DmkSpawnPattern.get_children()
	var dmk : Array[Danmaku] = []
	for c:Danmaku in children:
		dmk.append(c)
	return dmk
