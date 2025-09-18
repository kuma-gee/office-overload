class_name LocalRanking
extends MenuPaper

signal received_all()
signal received_data(is_last, steam_id)

@export var slide_dir := Vector2.UP
@export var board: ScoreBoard

@onready var expected_player_size := Networking.get_player_count()

var slide_tw: Tween
var ranking_data: Array

func _ready() -> void:
	hide()
	connect_focus()
	
	for n in board.buttons:
		delegator.nodes.append(n)

func push_local_ranking(data):
	_send_ranking.rpc(data)
	
@rpc("any_peer", "call_local", "reliable")
func _send_ranking(data):
	data["sender"] = multiplayer.get_remote_sender_id()
	ranking_data.append(data)

	var is_last = ranking_data.size() >= expected_player_size
	received_data.emit(is_last, Networking.get_player_id(data["sender"]))

	_show_ranking()
	
	if is_last:
		received_all.emit()

func _show_ranking():
	var result = []
	
	ranking_data.sort_custom(func(a, b): return b["time"] - a["time"])
	for i in ranking_data.size():
		var player_data = ranking_data[i]
		var details = ";".join(["%.0f/%.0f%%" % [player_data["wpm"], player_data["acc"]], player_data["tasks"], "%sh" % player_data["hours"]])
		result.append({
			"global_rank": i + 1,
			"steam_id": Networking.get_player_id(player_data["sender"]),
			"details": var_to_bytes(details).to_int32_array(),
		})
	
	board.show_data(result)

func slide_in(delay := 0.0):
	position = original_pos - slide_dir 
	
	slide_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	slide_tw.tween_property(self, "position", original_pos, 0.5).set_delay(delay)
	show()

func focused():
	board.active()
	super.focused()

func defocused():
	board.reset()
	super.defocused()
