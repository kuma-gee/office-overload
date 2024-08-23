class_name TypingButton
extends Control

signal finished()

@export var word := ""
@export var typing_label: TypedWord

func _ready():
	typing_label.word = word
	typing_label.type_finish.connect(func(): finished.emit())

func handle_key(key: String):
	typing_label.type(key)

func set_typed(player_typed: String):
	typing_label.set_typed(player_typed)

func get_word():
	return typing_label.get_word()
