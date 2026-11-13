class_name NewContractPaper
extends FocusedDialog

@export var sign_button: TypingButton

func _ready() -> void:
	super._ready()

	sign_button.finished.connect(func():
		if GameManager.sign_new_contract():
			SceneManager.reload_scene()
	)
