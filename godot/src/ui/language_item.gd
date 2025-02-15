extends HBoxContainer

@onready var typing_button: TypingButton = $TypingButton
@onready var checkbox: CheckboxImage = $Checkbox

var file := ""

func _ready() -> void:
	get_label().word = file
	GameManager.language_changed.connect(func(): _update())
	
	typing_button.finished.connect(func():
		GameManager.language = "" if file == GameManager.language else file
		GameManager.save_data()
	)
	_update()

func _update():
	checkbox.value = file == GameManager.language

func get_label():
	return typing_button.get_label()

func is_active():
	return checkbox.value
