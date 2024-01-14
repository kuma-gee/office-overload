extends Node

var day = 1

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func next_day():
	day += 1
	SceneManager.reload_scene()
	get_tree().paused = false

func restart():
	day = 1
	SceneManager.reload_scene()
	get_tree().paused = false
