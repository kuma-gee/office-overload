class_name TypingButton
extends Control

signal finished()

@export var word := ""
@export var typing_label: TypedWord

func _ready():
	update()
	typing_label.type_finish.connect(func(): finished.emit())

func update():
	typing_label.word = word

func handle_key(key: String):
	typing_label.handle_key(key)

func set_typed(player_typed: String):
	typing_label.set_typed(player_typed)

func get_word():
	return typing_label.get_word()
