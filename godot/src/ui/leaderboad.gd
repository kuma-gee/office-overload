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

@export_category("Local Score")
@export var local_score_label: RichTextLabel

@onready var delegator: Delegator = $Delegator

var current_leaderboard := ""

func _ready() -> void:
	user_button.finished.connect(func(): show_board(user_board, user_button))
	friends_button.finished.connect(func(): show_board(friends_board, friends_button))
	global_button.finished.connect(func(): show_board(global_board, global_button))

	if SteamManager.is_successful_initialized:
		user_board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER
		friends_board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_FRIENDS
		global_board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_GLOBAL
	
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
	
		if GameManager.has_current_job():
			var wpm_str = "%.0f/%.0f%%" % [GameManager.average_wpm, GameManager.average_accuracy * 100]
			var score_str = "%.0f" % GameManager.calculate_score()
			
			local_score_label.text = "[center]Current Score: %s with WPM %s, %s %s as %s[/center]" % [
				_bbcode_outline(score_str),
				_bbcode_outline(wpm_str),
				board.get_day_title(),
				GameManager.day,
				GameManager.get_level_text(GameManager.difficulty_level)
			]
		else:
			local_score_label.text = "No current score"
	
	_set_active_button(user_button, false)
	_set_active_button(friends_button, false)
	_set_active_button(global_button, false)
	_set_active_button(btn, true)

func _bbcode_outline(txt: String):
	return "[outline_size=3]%s[/outline_size]" % txt

func _set_active_button(btn: TypingButton, active = false):
	btn.get_label().highlight_first = not active
	btn.get_label().reset()
	btn.get_label().active = active
