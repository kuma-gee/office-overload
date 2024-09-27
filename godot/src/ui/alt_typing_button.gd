class_name AltTypingButton
extends TypingButton

signal finished_alt()

@export var other_word := ""

var active := false

func _ready() -> void:
	super._ready()

func _on_finished():
	if active:
		finished_alt.emit()
	else:
		super._on_finished()
	
func set_active(a = false):
	if a == active: return

	active = a
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC)

	tw.tween_property(container, "modulate", Color.TRANSPARENT, 0.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "custom_minimum_size:y", 0, 0.2).from(size.y).set_ease(Tween.EASE_IN)
	
	tw.tween_callback(func(): update(other_word if active else word))
	tw.parallel().tween_property(panel, "custom_minimum_size:y", size.y, 0.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(container, "modulate", Color.WHITE, 0.2).set_ease(Tween.EASE_IN)
