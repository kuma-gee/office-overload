class_name ScoreBoard
extends Control

const TEXT_OUTLINE = preload("res://theme/text_outline.tres")

@export var keys: Array[String] = [
	"global_rank",
	"score",
	"steam_id",
	"details.0",
	"details.1",
	"details.2",
]
@export var details_title: Array[String] = ["WPM", "Day", "Level"]
@export var detail_labels: Array[Label] = []

@export var container: GridContainer
@export var scroll_container: ScrollContainer
@export var up_scroll: TypingButton
@export var down_scroll: TypingButton
@export var scroll_step := 20
@export var scroll_button_container: Control

@onready var buttons: Array[TypingButton] = [up_scroll, down_scroll]

@export var loading_label: Control
@export var empty_label: Control

var loaded: bool = false
var score_type: int = SteamManager.steam.LEADERBOARD_DATA_REQUEST_USERS
var loaded_board: String = ""

func _ready() -> void:
	up_scroll.finished.connect(func(): scroll_container.scroll_vertical -= scroll_step)
	down_scroll.finished.connect(func(): scroll_container.scroll_vertical += scroll_step)
	scroll_button_container.hide()
	empty_label.hide()
	
	for i in container.get_child_count():
		container.get_child(i).visible = i < keys.size()
	container.columns = keys.size()
	
	for i in details_title.size():
		var lbl = detail_labels[i]
		lbl.text = "%s" % details_title[i]

func active():
	up_scroll.get_label().highlight_first = true
	down_scroll.get_label().highlight_first = true

func reset():
	scroll_container.scroll_vertical = 0
	up_scroll.get_label().highlight_first = false
	down_scroll.get_label().highlight_first = false

func _update_scrollbar():
	var bar = scroll_container.get_v_scroll_bar()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.update_minimum_size()

func is_friends_board():
	return score_type == SteamManager.steam.LEADERBOARD_DATA_REQUEST_FRIENDS

func load_data(board: String = GameManager.get_leaderboard_for_mode()):
	if loaded: return
	loaded = true
	
	loading_label.show()
	var result = await SteamLeaderboard.load_score(board, score_type)
	show_data(result)

func parse_details(data: Dictionary):
	if not "details" in data: return []
	
	var details_data = data.get("details") as PackedInt32Array
	var x = bytes_to_var(details_data.to_byte_array())
	return x.split(";")

func parse_data(data: Dictionary, key: String, details: Array):
	if key == "steam_id":
		return SteamManager.get_steam_username(data.get(key))
	else:
		return "%s" % _get_recursive(data, key, details)

func show_data(data: Array):
	loading_label.hide()
	empty_label.visible = data.is_empty()
	
	for i in range(data.size()):
		var d = data[i]
		var details = parse_details(d)
			
		for k in keys:
			var label = Label.new()
			label.text = parse_data(d, k, details)

			if label.text.length() > 10:
				label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			
			if k == "global_rank":
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				
				if is_friends_board():
					label.text = "%s" % (i+1)

			if SteamManager.get_steam_id() == d["steam_id"]:
				label.add_theme_color_override("font_color", Color.WHITE)
				label.add_theme_color_override("font_outline_color", Color("#353540"))
				label.add_theme_constant_override("outline_size", 3)
			
			label.add_theme_font_size_override("font_size", 6)
			label.tooltip_text = label.text
			container.add_child(label)
	
	await get_tree().physics_frame
	scroll_button_container.visible = scroll_container.get_v_scroll_bar().visible and not data.is_empty()

func _get_recursive(dict: Dictionary, key: String, details: Array):
	if key.begins_with("details."):
		var idx = int(key.split(".")[1])
		if idx >= 0 and idx < details.size():
			var value = details[idx]
			if int(value) < 0:
				return GameManager.get_level_text(-int(value), 8)
			return details[idx]
	return dict.get(key, "")
