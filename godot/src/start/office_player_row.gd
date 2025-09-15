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

var steam_id := -1

func is_self():
	return steam_id == Networking.get_player_id()

func _ready() -> void:
	steam_id = int(name)
	if not name.is_valid_int() or steam_id <= 0: return

	if is_self():
		player_name.text = "%s" % SteamManager.get_username()
		set_stats.rpc(GameManager.difficulty_level, GameManager.get_wpm())
		ready_label.finished.connect(func(): toggle_ready())
	else:
		player_name.text = "%s" % SteamManager.get_steam_username(steam_id)
		ready_label.hide()

func toggle_ready():
	set_ready.rpc(not is_ready)

@rpc("any_peer", "call_local", "reliable")
func set_ready(rdy: bool):
	is_ready = rdy

# func request_player_stats():
# 	pass

# @rpc("any_peer", "reliable")
# func send_player_stats():
# 	pass

@rpc("any_peer", "call_local", "reliable")
func set_stats(lvl: DifficultyResource.Level, wpm: int):
	player_stats.text = "%s / %s WPM" % [GameManager.get_level_text(lvl), wpm]

func get_label():
	return ready_label.get_label()
