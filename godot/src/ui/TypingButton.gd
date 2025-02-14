class_name TypingButton
extends Control

signal finished()

@export var center := true
@export var right := false
@export var word := ""
@export var typing_label: TypedWord
@export var reset_on_finished := true

@export var underline: Control
@export var show_underline := true

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
	typing_label.center = center
	typing_label.right = right
	typing_label.type_finish.connect(func(): _on_finished())
	
	if reset_on_finished:
		finished.connect(func(): reset())

	underline.visible = show_underline

func _on_finished():
	finished.emit()

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

func get_label() -> TypedWord:
	return typing_label

func reset():
	return get_label().reset()
