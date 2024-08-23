extends Node






var focusUnit : Unit
var activeUnit : Unit
var day: bool = true
var gameTime
var timeFactor = 1
var trueTimeFactor = 1
var rotationFactor = 15
var rng
var unitObjs : Dictionary
var flags : Dictionary


var slamage = 5
#combat variables
var attacker = {
	"NAME" : "Null", "ACC": 0, "DMG": 0, "AVOID": 0, "DEF": 0,
	"CRIT": 0, "CAVD": 0, "LIFE": 0, "CLIFE": 0, "RLIFE":0}
var defender = {
	"NAME" : "Null", "ACC": 0, "DMG": 0, "AVOID": 0, "DEF": 0,
	"CRIT": 0, "CAVD": 0, "LIFE": 0, "CLIFE": 0, "RLIFE":0}
func _init():
	gameTime = 0
	rng = RandomNumberGenerator.new()
	randomize()
	_init_flags()
	
func set_flags(flags):
	pass
	
func _init_flags():
	flags = {
		"gameOver": false,
		"victory": false,
		"activeUnit": false,
		"focusUnit": false,
		"gameTime": 0,
		"timeFactor": 1,
		"trueTimeFactor": 1,
		"rotationFactor": 15,
		"currentMap": 0
	}

