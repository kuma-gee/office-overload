class_name PlayerPaper
extends DocumentUI

@export var username_label: Label
@export var no_steam_label: Label

@export var info_container: Control
@export var days_label: Label
@export var speed_label: Label
@export var ready_button: TypingButton

@export var remote := false

func _ready() -> void:
	var is_steam = SteamManager.is_successful_initialized
	no_steam_label.visible = not is_steam
	info_container.visible = is_steam
	username_label.text = "Offline"
	close()

func disable():
	ready_button.disabled = true
	
@rpc("call_local")
func update_values():
	username_label.text = Networking.network.get_player_name(multiplayer.get_remote_sender_id())
	days_label.text = "Days %s" % GameManager.day
	speed_label.text = "Speed %.0f" % GameManager.average_wpm

func get_label():
	return ready_button.get_label()

# func open(delay = 0.0):
# 	if not was_opened:
# 		super.open(delay)
