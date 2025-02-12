extends Control

signal scene_load_finished(scene: String)

@onready var start_timer: Timer = $StartTimer
@onready var backup_timer: Timer = $BackupTimer

@onready var SCENES_TO_LOAD = [GameManager.START_SCENE, GameManager.GAME_SCENE]

var logger := Logger.new("Loading")
var loading_scene := ""
var loaded := false

func _ready() -> void:
	start_timer.timeout.connect(func(): start_game())
	backup_timer.timeout.connect(func():
		if start_timer.is_stopped(): # Force load the game, sometimes it gets stuck
			start_game()
	)

	_start_load_scene(SCENES_TO_LOAD.pop_front())
	scene_load_finished.connect(func(_s):
		if SCENES_TO_LOAD.is_empty():
			loaded = true
			logger.info("All scenes loaded")
			return

		_start_load_scene(SCENES_TO_LOAD.pop_front())
	)

func _start_load_scene(scene: String):
	ResourceLoader.load_threaded_request(scene)
	loading_scene = scene
	logger.info("Start loading scene: %s" % scene)

func _process(delta: float) -> void:
	if not loading_scene: return
	
	if loaded:
		if start_timer.is_stopped() and GameManager.init:
			start_timer.start()
		
		return
	
	var progress = []
	
	var status = ResourceLoader.load_threaded_get_status(loading_scene, progress)
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		logger.error("Failed loading game scene")
	elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		logger.error("Failed to load invalid resource")
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		logger.info("Loading finished for %s" % loading_scene)
		scene_load_finished.emit(loading_scene)

		_show_progress(1.0)
	else:
		_show_progress(progress[0])

func _show_progress(progress: float) -> void:
	pass
	#loading_progress.value = progress

func start_game():
	logger.info("Starting game")
	loading_scene = ""
	
	if GameManager.has_played:
		GameManager.back_to_menu()
	else:
		GameManager.start(GameManager.Mode.Work)
