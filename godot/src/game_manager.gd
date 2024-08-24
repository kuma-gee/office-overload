extends Node

signal round_ended()

const DIFFICULTIES = {
	DifficultyResource.Level.INTERN: preload("res://src/difficulty/Intern.tres"),
	DifficultyResource.Level.JUNIOR: preload("res://src/difficulty/Junior.tres"),
	DifficultyResource.Level.SENIOR: preload("res://src/difficulty/Senior.tres"),
	DifficultyResource.Level.MANAGEMENT: preload("res://src/difficulty/Management.tres"),
}

@onready var wpm_calculator = $WPMCalculator

var day := 0
var completed := 0
var total_overtime := 0

var difficulty_level := DifficultyResource.Level.INTERN
var difficulty: DifficultyResource

func _ready():
	difficulty = DIFFICULTIES[difficulty_level]
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

func can_have_promotion():
	return get_wpm() > difficulty.average_wpm and difficulty_level in DIFFICULTIES

func take_promotion():
	var level = difficulty_level + 1
	if level in DIFFICULTIES:
		difficulty = DIFFICULTIES[level]
	next_day()
