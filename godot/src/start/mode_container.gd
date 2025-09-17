extends VBoxContainer

@export var mode := GameManager.Mode.Crunch
@export var button: TypingButton

func _ready() -> void:
	visible = GameManager.is_mode_unlocked(mode)
	button.update(GameManager.get_mode_title(mode))
