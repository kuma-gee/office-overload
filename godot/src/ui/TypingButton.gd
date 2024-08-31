class_name TypingButton
extends Control

signal finished()

@export var word := ""
@export var typing_label: TypedWord
@export var button: TextureButton
@export var reset_on_finished := true

func _ready():
	update()
	typing_label.type_finish.connect(func(): finished.emit())
	button.pressed.connect(func(): finished.emit())
	finished.connect(func(): reset())

func update():
	typing_label.word = word

func handle_key(key: String):
	return typing_label.handle_key(key)

func set_typed(player_typed: String):
	typing_label.set_typed(player_typed)

func get_word():
	return typing_label.get_word()

func get_label():
	return typing_label

func reset():
	return get_label().reset()
