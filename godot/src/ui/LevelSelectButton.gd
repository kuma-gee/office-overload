extends TypingButton

@export var level := DifficultyResource.Level.INTERN
@export var game: StartNew

func _ready() -> void:
	word = DifficultyResource.Level.keys()[level]
	finished.connect(func(): GameManager.start(GameManager.Mode.Work, game.languages.language, level))
	
	super._ready()
