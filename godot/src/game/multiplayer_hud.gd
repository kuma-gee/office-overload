class_name MultiplayerHUD
extends Control

@export var player_container: Control
@export var player_panel_scene: PackedScene
@export var overload_update_timer: Timer
@export var overload_progress: AutoProgressbar

var current_player_view: PlayerGameView

func _ready() -> void:
	visible = GameManager.is_multiplayer_mode()

	if visible:
		for c in player_container.get_children():
			c.queue_free()
		
		for player in Networking.players.values():
			_add_player(player)

		overload_update_timer.start()
		overload_update_timer.timeout.connect(func():
			if current_player_view:
				current_player_view.set_progress.rpc(ceilf(overload_progress.value))
		)

func _add_player(steam_id: int):
	var row = player_panel_scene.instantiate()
	row.name = steam_id
	player_container.add_child(row, true)

	if steam_id == Networking.get_player_id():
		current_player_view = row
		current_player_view.visible = false

func end_data_received(from: int, is_last: bool):
	for c in player_container.get_children():
		var view = c as PlayerGameView
		if view and view.visible and view.steam_id == from:
			view.set_win_state(is_last)
			break

func distracted_others():
	for c in player_container.get_children():
		var view = c as PlayerGameView
		if view and view != current_player_view:
			view.got_distracted()