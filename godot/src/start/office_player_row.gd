class_name OfficePlayerRow
extends Control

signal ready_changed()

@export var player_name: Label
@export var player_stats: Label
@export var ready_label: TypedWord

var is_ready := false:
	set(v):
		is_ready = v
		ready_label.fill_all = is_ready
		ready_changed.emit()

var steam_id: int

func _ready() -> void:
	steam_id = int(name)

	if steam_id == Networking.get_player_id():
		player_name.text = "%s" % SteamManager.get_username()
		set_stats.rpc(GameManager.difficulty_level, GameManager.get_wpm())
		ready_label.type_finish.connect(func(): toggle_ready())
		ready_label.highlight_first = true
	else:
		player_name.text = "%s" % SteamManager.get_steam_username(steam_id)

func toggle_ready():
	print("Toggle ready for %s" % name)
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
	return ready_label
