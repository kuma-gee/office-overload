class_name OfficePlayerRow
extends Control

signal ready_changed()

@export var player_name: Label
@export var player_stats: Label
@export var ready_label: TypingButton
@export var checkbox: CheckboxTexture

var is_ready := false:
	set(v):
		is_ready = v
		checkbox.is_checked = is_ready
		ready_changed.emit()

var steam_id = null

func is_self():
	return steam_id == Networking.get_player_id()

func _ready() -> void:
	steam_id = Networking.get_player_id(int(name))
	if steam_id == null: return

	if not is_self():
		_set_remote_user_data()
		return

	_set_own_user_data()
	ready_label.finished.connect(func(): toggle_ready())

func _set_own_user_data():
	player_name.text = "%s" % SteamManager.get_username()
	set_stats(GameManager.difficulty_level, GameManager.get_wpm())

func _set_remote_user_data():
	player_name.text = "%s" % SteamManager.get_steam_username(steam_id)
	player_stats.text = ""
	_request_remote_user_data.rpc_id(int(name))
	ready_label.hide()

@rpc("any_peer", "reliable")
func _request_remote_user_data():
	set_stats.rpc_id(multiplayer.get_remote_sender_id(), GameManager.difficulty_level, GameManager.get_wpm())
	set_ready.rpc(is_ready)

func toggle_ready():
	set_ready.rpc(not is_ready)

@rpc("any_peer", "call_local", "reliable")
func set_ready(rdy: bool):
	is_ready = rdy

@rpc("any_peer", "call_local", "reliable")
func set_stats(lvl: DifficultyResource.Level, wpm: int):
	player_stats.text = "%s / %s WPM" % [GameManager.get_level_text(lvl), wpm]

func get_label():
	return ready_label.get_label()
