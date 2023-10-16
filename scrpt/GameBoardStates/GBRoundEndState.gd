extends GenericState
class_name GBRoundEndState
var gameBoard

func setup(newSlaves):
	super.setup(newSlaves)
	gameBoard = slaves[0]
