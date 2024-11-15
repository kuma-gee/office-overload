class_name ScorePaper
extends MenuPaper

@export var board: ScoreBoard

func focused():
	board.load_data()
	super.focused()
