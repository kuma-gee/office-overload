extends Node

var day := 0
var completed := 0
var total_overtime := 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start():
	day += 1
	SceneManager.change_scene("res://src/game.tscn") # reload_scene (sometimes?) doesn't work?

func next_day():
	start()
	get_tree().paused = false

func restart():
	_reset()
	SceneManager.change_scene("res://src/game.tscn")
	get_tree().paused = false

func back_to_menu(reset = true):
	SceneManager.change_scene("res://start.tscn")
	get_tree().paused = false
	if reset:
		_reset()

func _reset():
	day = 0
	completed = 0
	total_overtime = 0

func finished_day(tasks: int, overtime: int):
	completed += tasks
	total_overtime += overtime
