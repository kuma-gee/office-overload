extends TypingButton

@export var level := DifficultyResource.Level.INTERN

func _ready() -> void:
	word = DifficultyResource.Level.keys()[level]
	finished.connect(func(): GameManager.start(GameManager.Mode.Work, level))
	
	super._ready()
