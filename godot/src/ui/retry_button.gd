class_name RetyButton
extends TypingButton

func _ready() -> void:
	self.word = "Retry"
	finished.connect(func(): GameManager.start())
	super._ready()
