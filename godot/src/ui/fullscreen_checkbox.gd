extends CheckBox

@export var display_settings: DisplaySettings

func _ready() -> void:
	display_settings.loaded.connect(_update)
	toggled.connect(func(on): display_settings.set_fullscreen(on))
	
func _update():
	button_pressed = display_settings.is_fullscreen()
