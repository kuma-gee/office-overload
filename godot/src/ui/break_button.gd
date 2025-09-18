class_name BreakButton
extends TypingButton

@export var wording := "Home"

func _ready() -> void:
	self.word = wording
	finished.connect(func(): GameManager.back_to_menu())
	super._ready()
