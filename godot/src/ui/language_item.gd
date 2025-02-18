extends HBoxContainer

signal typed()

@onready var typing_button: TypingButton = $TypingButton
@onready var checkbox: CheckboxImage = $Checkbox

var file := ""

var current_lang := "":
	set(v):
		current_lang = v
		update(current_lang)

func _ready() -> void:
	get_label().word = file
	typing_button.finished.connect(func(): typed.emit())

func update(lang):
	checkbox.value = file == lang

func get_label():
	return typing_button.get_label()

func is_active():
	return checkbox.value
