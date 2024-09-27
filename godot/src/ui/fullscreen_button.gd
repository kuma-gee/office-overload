extends TypingButton

@export var checkbox: CheckBox

func _ready() -> void:
	super._ready()
	finished.connect(func(): checkbox.button_pressed = not checkbox.button_pressed)
