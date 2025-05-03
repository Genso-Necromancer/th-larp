extends Node # For storing dialog, cutscene, and other data
class_name CutSceneData

enum ACTORS {
	SAKUYA = 0,
	PATCHOULI = 1,
	REMILIA = 2,
	CIRNO = 3,
}


var ActorData: Dictionary = {
	0: {
		"name": "Sakuya Izayoi",
		"title": "Maid",
		"portrait": preload("res://sprites/SakuyaPrt.png")
	},
	1: {
		"name": "Patchouli Knowledge",
		"title": "Librarian",
		"portrait": preload("res://sprites/PatchouliPrt.png")
	},
	2: {
		"name": "Remilia",
		"title": "Head Lady",
		"portrait": preload("res://sprites/th1.png")
	},
	3: {
		"name": "Cirno",
		"title": "The Strongest",
		"portrait": preload("res://sprites/Fairy TroublemakerPrt.png"),
	},
}


# planning an example of how the scene data/actions may flow.
# it might make more sense just to hard code a bunch of utils
# and expand into this "way" later
enum CUTSCENES {
	PROLOGUE = 0,
	MAP1_1 = 1,
}


var Cutscenes: Dictionary = {
	0: {
		"setup": {
			# Something...
		},
		"steps": [
			{
				"action": "pan_camera",
				"coords": Vector2i(5,4)
			},
			{
				"action": "wait",
				"duration": 0.5
			},
			{
				"action": "start_dialog"
			},
			{
				"action": "fade_to_black"
			}
		]
	}
}
