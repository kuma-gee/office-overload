extends CheckBox

@export var display_settings: DisplaySettings
@export var button: TypingButton

func _ready() -> void:
	focus_mode = FOCUS_NONE
	
	button.finished.connect(func(): _toggle())
	display_settings.loaded.connect(_update)

func _toggle():
	GameManager.is_motion = not GameManager.is_motion
	_update()

func _update():
	button_pressed = GameManager.is_motion
