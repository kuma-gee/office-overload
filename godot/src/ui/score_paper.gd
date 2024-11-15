class_name ScorePaper
extends MenuPaper

@export var board: ScoreBoard

func _ready() -> void:
	super._ready()
	
	for n in board.buttons:
		delegator.nodes.append(n)

func focused():
	board.load_data()
	board.active()
	super.focused()

func defocused():
	board.reset()
	super.defocused()
