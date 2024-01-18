extends Button

func _ready():
	mouse_entered.connect(func(): grab_focus())
	focus_entered.connect(func(): SoundManager.play_button_sound())
	pressed.connect(func(): SoundManager.play_press_sound())
