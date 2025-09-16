class_name PlayerGameView
extends Control

@export var name_label: Label
@export var count_label: Label
@export var progress_bar: TextureProgressBar

var steam_id := -1
var tw: Tween

func _ready() -> void:
	steam_id = int(name)
	name_label.text = SteamManager.get_steam_username(steam_id)

@rpc("any_peer", "reliable")
func set_count(count: int):
	count_label.text = "%d" % count

@rpc("any_peer")
func set_progress(value: float):
	if tw and tw.is_running():
		tw.kill()

	tw = create_tween()
	tw.tween_property(progress_bar, "value", value, 0.5)
