class_name Leaderboard
extends Control

signal close()

@export var user_button: TypingButton
@export var friends_button: TypingButton
@export var global_button: TypingButton

@export var user_board: ScoreBoard
@export var friends_board: ScoreBoard
@export var global_board: ScoreBoard

@onready var delegator: Delegator = $Delegator

const GLOBAL_DATA: Array[Dictionary] = [
	{"global_rank": 1, "name": "Bob", "score": 250, "accuracy": "97%", "documents": 120, "time": 52},
	{"global_rank": 2, "name": "Alice", "score": 201, "accuracy": "99%", "documents": 101, "time": 42},
	{"global_rank": 3, "name": "Charlie", "score": 180, "accuracy": "94%", "documents": 98, "time": 52},
	{"global_rank": 4, "name": "David", "score": 165, "accuracy": "98%", "documents": 95, "time": 67},
	{"global_rank": 5, "name": "Eve", "score": 143, "accuracy": "99%", "documents": 70, "time": 68},
	{"global_rank": 6, "name": "Donald", "score": 115, "accuracy": "95%", "documents": 64, "time": 52},
	{"global_rank": 7, "name": "Joe", "score": 99, "accuracy": "88%", "documents": 66, "time": 42},
]

const USER_DATA: Array[Dictionary] = [
	{"global_rank": 59, "name": "Alice", "score": 76, "accuracy": "98%", "documents": 31, "time": 321},
	{"global_rank": 60, "name": "Charlie", "score": 71, "accuracy": "97%", "documents": 30, "time": 234},
	{"global_rank": 61, "name": "David", "score": 68, "accuracy": "96%", "documents": 29, "time": 84},
	{"global_rank": 62, "name": "You", "score": 62, "accuracy": "95%", "documents": 28, "time": 12},
	{"global_rank": 63, "name": "Donald", "score": 54, "accuracy": "90%", "documents": 23, "time": 30},
	{"global_rank": 64, "name": "Joe", "score": 50, "accuracy": "88%", "documents": 20, "time": 42},
	{"global_rank": 65, "name": "John", "score": 47, "accuracy": "79%", "documents": 24, "time": 69},
]

const FRIENDS_DATA: Array[Dictionary] = [
	{"global_rank": 1, "name": "John", "score": 131, "accuracy": "99%", "documents": 32, "time": 123},
	{"global_rank": 2, "name": "Maven", "score": 124, "accuracy": "98%", "documents": 31, "time": 321},
	{"global_rank": 3, "name": "You", "score": 98, "accuracy": "97%", "documents": 30, "time": 234},
	{"global_rank": 4, "name": "Rick", "score": 93, "accuracy": "96%", "documents": 29, "time": 84},
	{"global_rank": 5, "name": "Charles", "score": 87, "accuracy": "95%", "documents": 28, "time": 12},
]

func _ready() -> void:
	user_button.finished.connect(func(): show_board(user_board, user_button))
	friends_button.finished.connect(func(): show_board(friends_board, friends_button))
	global_button.finished.connect(func(): show_board(global_board, global_button))

	user_board.show_data(USER_DATA)
	friends_board.show_data(FRIENDS_DATA)
	global_board.show_data(GLOBAL_DATA)

	show_board(user_board, user_button)
	
func show_board(board: ScoreBoard, btn: TypingButton) -> void:
	user_board.hide()
	friends_board.hide()
	global_board.hide()
	board.show()
	
	_set_active_button(user_button, false)
	_set_active_button(friends_button, false)
	_set_active_button(global_button, false)
	_set_active_button(btn, true)

func _set_active_button(btn: TypingButton, active = false):
	btn.get_label().highlight_first = not active
	btn.get_label().reset()
	btn.get_label().active = active

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		close.emit()
		get_viewport().set_input_as_handled()
		return
	
	delegator.handle_event(event)
