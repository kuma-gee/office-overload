extends Node

signal round_ended()

enum Level {
	INTERN,
	JUNIOR,
	SENIOR,
	MANAGEMENT,
}

@onready var wpm_calculator = $WPMCalculator

var day := 0
var completed := 0
var total_overtime := 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset()

func start():
	day += 1
	SceneManager.change_scene("res://src/game.tscn") # reload_scene (sometimes?) doesn't work?

func next_day():
	start()

func restart():
	_reset()
	SceneManager.change_scene("res://src/game.tscn")

func back_to_menu(reset = true):
	SceneManager.change_scene("res://start.tscn")
	if reset:
		_reset()

func _reset():
	day = 1
	completed = 0
	total_overtime = 0

func finished_day(tasks: int, overtime: int):
	completed += tasks
	total_overtime += overtime
	round_ended.emit()

func start_type():
	wpm_calculator.start_type()

func finish_type(word: String):
	wpm_calculator.finish_type(word)

func get_wpm():
	return wpm_calculator.get_average_wpm()
