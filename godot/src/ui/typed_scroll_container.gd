class_name TypedScrollContainer
extends ScrollContainer

@export var scroll_button_container: Control
@export var up_scroll: TypingButton
@export var down_scroll: TypingButton
@export var scroll_step := 20

func _ready() -> void:
	up_scroll.finished.connect(func(): scroll_vertical -= scroll_step)
	down_scroll.finished.connect(func(): scroll_vertical += scroll_step)
	scroll_button_container.hide()

func active():
	up_scroll.get_label().highlight_first = true
	down_scroll.get_label().highlight_first = true

func reset():
	scroll_vertical = 0
	up_scroll.get_label().highlight_first = false
	down_scroll.get_label().highlight_first = false

func update(data: Array):
	scroll_button_container.visible = get_v_scroll_bar().visible and not data.is_empty()
