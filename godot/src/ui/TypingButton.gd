class_name TypingButton
extends Control

signal finished()

@export var word := ""
@export var typing_label: TypedWord
@export var button: TextureButton
@export var reset_on_finished := true

@export var center_container: Control
@export var panel: Panel
@export var container: Control

var tw: Tween
var disabled := false:
	set(v):
		disabled = v
		typing_label.highlight_first = not disabled
		typing_label.modulate.a = 0.5 if disabled else 1.0
		
		if disabled:
			reset()

func _ready():
	update()
	typing_label.typing.connect(func(): _press_effect())
	typing_label.type_finish.connect(func(): _on_finished())
	button.pressed.connect(func(): _on_finished())
	
	if reset_on_finished:
		finished.connect(func(): reset())

func _press_effect():
	center_container.pivot_offset = center_container.size / 2
	if tw and tw.is_running():
		tw.kill()
		center_container.scale = Vector2.ONE
	
	tw = create_tween()
	tw.tween_property(center_container, "scale", Vector2(0.99, 0.99), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_container, "scale", Vector2.ONE, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _on_finished():
	finished.emit()

func _process(delta: float) -> void:
	panel.custom_minimum_size = container.size

func update(w = word):
	typing_label.word = w
	reset()

func handle_key(key: String):
	if disabled: return false
	return typing_label.handle_key(key)

func set_typed(player_typed: String):
	typing_label.set_typed(player_typed)

func get_word():
	return typing_label.get_word()

func get_label():
	return typing_label

func reset():
	return get_label().reset()
