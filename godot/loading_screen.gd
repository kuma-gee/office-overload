extends Control

var logger := Logger.new("Loading")

func _ready() -> void:
	logger.info("Starting game")
	if GameManager.init:
		_load_scene()
	else:
		GameManager.initialized.connect(func(): _load_scene())

func _load_scene():
	logger.debug("Loading scene, has played: %s" % GameManager.has_played)
	if GameManager.has_played:
		GameManager.back_to_menu()
	else:
		GameManager.start(GameManager.Mode.Work)
