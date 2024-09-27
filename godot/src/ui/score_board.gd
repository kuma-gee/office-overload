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
@export var container: GridContainer
@export var scroll_container: ScrollContainer
@export var up_scroll: TypingButton
@export var down_scroll: TypingButton
@export var scroll_step := 20
@export var scroll_button_container: Control
@onready var buttons: Array[TypingButton] = [up_scroll, down_scroll]

@export var use_days := false
@export var day_label: Label

@export var loading_label: Control

var loaded := false
var score_type: int

func _ready() -> void:
	up_scroll.finished.connect(func(): scroll_container.scroll_vertical -= scroll_step)
	down_scroll.finished.connect(func(): scroll_container.scroll_vertical += scroll_step)
	scroll_button_container.hide()
	
	for i in container.get_child_count():
		container.get_child(i).visible = i < keys.size()
	container.columns = keys.size()
	
	
	#var bar = scroll_container.get_v_scroll_bar()
	#bar.reparent(scroll_button_container)
	#_update_scrollbar()
	#scroll_container.scroll_ended.connect(func(): _update_scrollbar())

# Doesn't work, it always gets overwritten by the scroll container probably
#func _process(delta: float) -> void:
	#_update_scrollbar()

func _update_scrollbar():
	var bar = scroll_container.get_v_scroll_bar()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.update_minimum_size()

func load_data(board: String):
	if loaded: return
	loaded = true
	
	loading_label.show()
	var result = await SteamManager.load_score(board, score_type)
	show_data(result)
	
func show_data(data: Array):
	if use_days:
		day_label.text = "Days"
	else:
		day_label.text = "Docs"
	
	loading_label.hide()
	scroll_button_container.visible = scroll_container.get_v_scroll_bar().visible
	
	for d in data:
		var details = []
		if "details" in d:
			var details_data = d.get("details") as PackedInt32Array
			var str = bytes_to_var(details_data.to_byte_array())
			details = str.split(";")
			
		for k in keys:
			var label = Label.new()
			
			if k == "steam_id":
				label.text = SteamManager.get_steam_username(d.get(k))
			else:
				label.text = "%s" % _get_recursive(d, k, details)

			if label.text.length() > 10:
				label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

			if Steam.getSteamID() == d["steam_id"]:
				label.label_settings = TEXT_OUTLINE
			
			label.tooltip_text = label.text
			container.add_child(label)

func _get_recursive(dict: Dictionary, key: String, details: Array):
	if key.begins_with("details."):
		var idx = int(key.split(".")[1])
		if idx >= 0 and idx < details.size():
			var value = details[idx]
			if int(value) < 0:
				return GameManager.get_level_text(-int(value), 6)
			return details[idx]
	return dict.get(key, "")
	
	#var parts = key.split(".")
	#var result = dict
	#for part in parts:
		#result = result.get(part, "")
		#if not result is Dictionary:
			#break
	#
	#return result

#func reset():
	#loaded = false
	#for c in container.get_children():
		#c.queue_free()
