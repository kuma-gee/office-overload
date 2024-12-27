extends Control

const GAME_SCENE = "res://src/game.tscn"

@onready var start_timer: Timer = $StartTimer

var logger := Logger.new("Loading")
var loading_scene := ""
var loaded := false

func _ready() -> void:
	ResourceLoader.load_threaded_request(GAME_SCENE)
	loading_scene = GAME_SCENE

	start_timer.timeout.connect(func(): start_game())

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
		logger.info("Loading finished")
		_show_progress(1.0)
		loaded = true
	else:
		_show_progress(progress[0])

func _show_progress(progress: float) -> void:
	pass
	#loading_progress.value = progress

func start_game():
	loading_scene = ""
	
	if GameManager.has_played:
		GameManager.back_to_menu()
	else:
		GameManager.start(GameManager.Mode.Work)
