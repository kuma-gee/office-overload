extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
