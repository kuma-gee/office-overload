extends Control

@export var label: TypedWord

@export_category("Label Slide")
@export var label_container: Control
@export var slide_dir := Vector2.ZERO
@onready var start_pos := label_container.position

var tw: Tween

func _ready() -> void:
	label_container.position = get_hide_position()

func set_word(w: String):
	label.word = w

func get_word():
	return label.word

func get_label():
	return label

func get_hide_position():
	return start_pos - slide_dir

func slide_in():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(label_container, "position", start_pos, 0.5)

func slide_out():
	if tw and tw.is_running():
		tw.kill()
	
	tw = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(label_container, "position", get_hide_position(), 0.5)
