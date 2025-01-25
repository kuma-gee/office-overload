extends Node

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
