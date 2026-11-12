class_name ContractPaper
extends EndPaper

signal accepted()
signal declined()

@export var sign_button: TypingButton
@export var cancel_button: TypingButton

func _ready() -> void:
	hide()

	sign_button.finished.connect(func():
		GameManager.sign_new_contract()
		accepted.emit()
		close()
	)
	cancel_button.finished.connect(func():
		declined.emit()
		close()
	)
