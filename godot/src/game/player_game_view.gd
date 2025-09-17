class_name PlayerGameView
extends Control

@export var name_label: Label
@export var count_label: Label
@export var progress_bar: TextureProgressBar
@export var profile_icon: TextureRect

var steam_id := -1
var tw: Tween

func _ready() -> void:
	if not name.is_valid_int(): return
	
	steam_id = int(name)
	name_label.text = SteamManager.get_steam_username(steam_id)

	Networking.player_disconnected.connect(func(id):
		if Networking.get_player_id(id) == steam_id:
			# TODO: show disconnected
			count_label.text = "Left"
	)

@rpc("any_peer", "reliable")
func set_count(count: int):
	count_label.text = "%d" % count

@rpc("any_peer")
func set_progress(value: float):
	if tw and tw.is_running():
		tw.kill()

	tw = create_tween()
	tw.tween_property(progress_bar, "value", value, 0.5)

	if value >= 90:
		pass # TODO: distress profile

func set_win_state(won: bool):
	if won:
		pass # TODO: won profile
	else:
		pass # TODO: lost profile

func got_distracted():
	pass # TODO: distracted profile
