class_name BreakButton
extends TypingButton

func _ready() -> void:
	self.word = "Home"
	finished.connect(func(): GameManager.back_to_menu())
	super._ready()
