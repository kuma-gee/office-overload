class_name ChallengePaper
extends EndPaper

signal accepted()
signal declined()

@export var yes_button: TypingButton
@export var no_button: TypingButton

func _ready() -> void:
	hide()
	
	yes_button.finished.connect(func():
		GameManager.take_promotion()
		accepted.emit()
		close()
	)
	no_button.finished.connect(func():
		declined.emit()
		close()
	)
