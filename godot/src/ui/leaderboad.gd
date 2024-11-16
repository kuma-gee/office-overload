class_name Leaderboard
extends Folder

@export var user_board: ScoreBoard
@export var friends_board: ScoreBoard
@export var global_board: ScoreBoard

@export var steam_offline: Control

var current_leaderboard := ""

func _ready() -> void:
	super._ready()

	if SteamManager.is_successful_initialized:
		user_board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER
		friends_board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_FRIENDS
		global_board.score_type = SteamManager.steam.LEADERBOARD_DATA_REQUEST_GLOBAL
	
	var online = SteamManager.is_successful_initialized
	for p in papers.get_children():
		p.visible = online
	steam_offline.visible = not online
