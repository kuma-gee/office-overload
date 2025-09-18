class_name PlayerGameView
extends Control

@export var name_label: Label
@export var count_label: Label
@export var progress_bar: TextureProgressBar
@export var anim: AnimationPlayer

@export_category("Profile")
@export var profile_icon: Sprite2D
@export var default_frame := 0
@export var distress_frame := 0
@export var distracted_frame := 0
@export var lose_frame := 0
@export var win_frame := 0
@export var disconnected_frame := 0

var steam_id = null
var tw: Tween

func _ready() -> void:
	if not name.is_valid_int(): return
	
	steam_id = Networking.get_player_id(int(name))
	if steam_id == null: return
	
	name_label.text = SteamManager.get_steam_username(steam_id)
	profile_icon.modulate = Color.WHITE

func disconnected():
	profile_icon.frame = disconnected_frame
	profile_icon.modulate = Color(1, 1, 1, 0.75)
	count_label.text = "Left"

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
		profile_icon.frame = distress_frame
	else:
		profile_icon.frame = default_frame

func set_win_state(won: bool):
	if won:
		profile_icon.frame = win_frame
		anim.play("move")
	else:
		profile_icon.frame = lose_frame

func got_distracted():
	profile_icon.frame = distracted_frame
