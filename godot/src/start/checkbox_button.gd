class_name CheckboxButton
extends CheckBox

@export var button: TypingButton

func _ready() -> void:
	toggle_mode = true
	focus_mode = FOCUS_NONE
	
	button.finished.connect(func(): button_pressed = not button_pressed)
