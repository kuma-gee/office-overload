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

var difficulty_level := DifficultyResource.Level.INTERN
var difficulty: DifficultyResource

var unlocked_modes = [Mode.Work]
var current_mode: Mode

func _ready():
	difficulty = DIFFICULTIES[difficulty_level]

func start(mode: Mode = current_mode):
	if not is_mode_unlocked(mode):
		return
	
	current_mode = mode
	if is_work_mode():
		day += 1
	else:
		day = 1 # Needed to await start key
	
	SceneManager.change_scene("res://src/game.tscn") # reload_scene (sometimes?) doesn't work?

func next_day():
	start()

func restart():
	SceneManager.change_scene("res://src/game.tscn")

func back_to_menu(reset = true):
	SceneManager.change_scene("res://start.tscn")

func reset_values():
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

### Difficulty

func can_have_promotion():
	if is_max_promotion(): return false

	var next = difficulty_level + 1
	if not next in DIFFICULTIES: return false
	
	return get_wpm() > DIFFICULTIES[next].average_wpm
	
func take_promotion():
	if is_max_promotion(): return

	difficulty_level += 1
	if difficulty_level in DIFFICULTIES:
		difficulty = DIFFICULTIES[difficulty_level]

func is_max_promotion():
	if Env.is_demo() and is_senior():
		return true

	return is_management();

func is_intern():
	return difficulty_level == DifficultyResource.Level.INTERN

func is_junior():
	return difficulty_level == DifficultyResource.Level.JUNIOR

func is_senior():
	return difficulty_level == DifficultyResource.Level.SENIOR

func is_management():
	return difficulty_level == DifficultyResource.Level.MANAGEMENT

### Modes

func is_interview_mode():
	return current_mode == Mode.Interview

func is_work_mode():
	return current_mode == Mode.Work
	
func is_crunch_mode():
	return current_mode == Mode.Crunch

func is_mode_unlocked(mode: Mode):
	if Env.is_demo():
		return mode == Mode.Work
	return mode in unlocked_modes

func get_unlocked_modes():
	return unlocked_modes

func unlock_mode(mode: Mode):
	if Env.is_demo(): return

	unlocked_modes.append(mode)
