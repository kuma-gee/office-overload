class_name ZenScores
extends MenuPaper

@export var slide_dir := Vector2.UP
@export var board: ScoreBoard

var slide_tw: Tween

func _ready() -> void:
	hide()
	connect_focus()
	board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER
	
	for n in board.buttons:
		delegator.nodes.append(n)

func slide_in(delay := 0.0):
	position = original_pos - slide_dir 
	
	slide_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	slide_tw.tween_property(self, "position", original_pos, 0.5).set_delay(delay)
	show()
	
	board.load_data(SteamLeaderboard.ZEN_BOARD, true)
	
func slide_out(delay := 0.0):
	slide_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	slide_tw.tween_property(self, "position", original_pos - slide_dir , 0.5).set_delay(delay)
	slide_tw.finished.connect(func(): hide())

func focused():
	board.active()
	super.focused()

func defocused():
	board.reset()
	super.defocused()
