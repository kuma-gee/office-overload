extends Control

var logger := Logger.new("Loading")

func _ready() -> void:
	logger.info("Starting game")
	
	if GameManager.has_played:
		GameManager.back_to_menu()
	else:
		GameManager.start(GameManager.Mode.Work)
