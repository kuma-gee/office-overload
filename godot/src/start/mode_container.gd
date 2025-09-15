extends VBoxContainer

@export var mode := GameManager.Mode.Crunch

func _ready() -> void:
	visible = GameManager.is_mode_unlocked(mode)
