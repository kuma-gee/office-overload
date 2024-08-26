extends Node

signal round_ended()

const DIFFICULTIES = {
	DifficultyResource.Level.INTERN: preload("res://src/difficulty/Intern.tres"),
	DifficultyResource.Level.JUNIOR: preload("res://src/difficulty/Junior.tres"),
	DifficultyResource.Level.SENIOR: preload("res://src/difficulty/Senior.tres"),
	DifficultyResource.Level.MANAGEMENT: preload("res://src/difficulty/Management.tres"),
}

enum Mode {
	Work,
	Crunch,
	Interview,
}

@onready var wpm_calculator = $WPMCalculator

var day := 0
var completed_documents := 0
var total_overtime := 0

var current_mode: Mode
var difficulty_level := DifficultyResource.Level.INTERN
var difficulty: DifficultyResource

func _ready():
	difficulty = DIFFICULTIES[difficulty_level]

func start(mode: Mode = current_mode):
	current_mode = mode
	day += 1
	SceneManager.change_scene("res://src/game.tscn") # reload_scene (sometimes?) doesn't work?

func next_day():
	start()

func restart():
	#_reset()
	SceneManager.change_scene("res://src/game.tscn")

func back_to_menu(reset = true):
	SceneManager.change_scene("res://start.tscn")

func _reset():
	day = 0
	completed_documents = 0
	total_overtime = 0

func finished_day(tasks: int, overtime: int):
	completed_documents += tasks
	total_overtime += overtime
	round_ended.emit()

func start_type():
	wpm_calculator.start_type()

func finish_type(word: String, mistakes: int):
	wpm_calculator.finish_type(word, mistakes)

func get_wpm():
	return wpm_calculator.get_average_wpm()

func get_accuracy():
	return wpm_calculator.get_average_accuracy() * 100

func finish_game():
	wpm_calculator.calculate_wpm()

func can_have_promotion():
	return get_wpm() > difficulty.average_wpm and (difficulty_level + 1) in DIFFICULTIES
	
func take_promotion():
	difficulty_level += 1
	if difficulty_level in DIFFICULTIES:
		difficulty = DIFFICULTIES[difficulty_level]
