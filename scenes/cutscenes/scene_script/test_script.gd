extends Resource
class_name SceneScript

var dialogue_script :Array[Dictionary]= [
	{
		"active_speaker": "Remi",
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.75}]
	},
	{
		"animations": [{"name": "interact", "target": "Remi"}]
	},
	{
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.25}]
	},
	{
		"animations": [{"name": "interact", "target": "Remi"}]
	},
	{
		"text": "Good news everyone.",
		"effects": [{"name": "loud"},],
		"animations": [{"name": "slide", "target": "Pakooli", "pos": -0.2}]
	},
	{
		"active_speaker": "Pakooli",
		"text": "Why did I get pinged?",
		
	},
	{
		"active_speaker": "Remi",
		"text": "I'm showing off early dialogue.",
		"animations": [{"name": "slide", "target": "Remi", "pos": 0.8}, {"name": "double_hop", "target": "Remi"}, {"name": "slide", "target": "Pakooli", "pos": 0.25}]
	},
	{
		"active_speaker": "Pakooli",
		"effects":[{"name":"portrait-sil", "target":"Pakooli"}],
		"text": ":pregnant_mandrew:",
	},
	{
		"animations": [{"name": "toggle_fade", "target":"Pakooli"}]
	},
	{
		"active_speaker": "Remi",
		"text": "damn it.",
		"animations": [{"name": "hop", "target": "Remi"}]
	},
	{
		"animations": [{"name": "slide", "target": "Remi", "pos": 3.0}]
	},
]
