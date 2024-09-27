class_name Leaderboard
extends Control

signal closed()

@export var effect: EffectRoot

@export var user_button: TypingButton
@export var friends_button: TypingButton
@export var global_button: TypingButton

@export var user_board: ScoreBoard
@export var friends_board: ScoreBoard
@export var global_board: ScoreBoard

@export var steam_offline: Control
@export var boards: Control

@onready var delegator: Delegator = $Delegator

var current_leaderboard := ""

func _ready() -> void:
	user_button.finished.connect(func(): show_board(user_board, user_button))
	friends_button.finished.connect(func(): show_board(friends_board, friends_button))
	global_button.finished.connect(func(): show_board(global_board, global_button))

	user_board.score_type = Steam.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER
	friends_board.score_type = Steam.LEADERBOARD_DATA_REQUEST_FRIENDS
	global_board.score_type = Steam.LEADERBOARD_DATA_REQUEST_GLOBAL
	
	delegator.nodes.append_array(user_board.buttons)
	delegator.nodes.append_array(friends_board.buttons)
	delegator.nodes.append_array(global_board.buttons)

	focus_entered.connect(func():
		current_leaderboard = GameManager.get_leaderboard_for_mode()
		effect.do_effect()
		show_board(user_board, user_button)
		show()
	)
	focus_exited.connect(func(): effect.reverse_effect())
	closed.connect(func():
		current_leaderboard = ""
		get_viewport().gui_release_focus()
	)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not delegator.has_focused():
		closed.emit()
		get_viewport().set_input_as_handled()
		return
	
	delegator.handle_event(event)

func open():
	grab_focus()
	var steam_online = SteamManager.is_successful_initialized
	boards.visible = steam_online
	steam_offline.visible = not steam_online

func show_board(board: ScoreBoard, btn: TypingButton) -> void:
	user_board.hide()
	friends_board.hide()
	global_board.hide()
	board.show()
	
	if current_leaderboard != "":
		board.use_days = current_leaderboard in [SteamManager.DEMO_LEADERBOARD, SteamManager.STORY_LEADERBOARD]
		board.load_data(current_leaderboard)
	
	_set_active_button(user_button, false)
	_set_active_button(friends_button, false)
	_set_active_button(global_button, false)
	_set_active_button(btn, true)

func _set_active_button(btn: TypingButton, active = false):
	btn.get_label().highlight_first = not active
	btn.get_label().reset()
	btn.get_label().active = active
