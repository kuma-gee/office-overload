extends Node

signal initialized()
signal game_started()
signal round_ended()
signal job_quited()
signal exiting_game()
signal mode_unlocked(mode)

signal logged(line)

const DIFFICULTIES = {
	DifficultyResource.Level.INTERN: preload("res://src/difficulty/Intern.tres"),
	DifficultyResource.Level.JUNIOR: preload("res://src/difficulty/Junior.tres"),
	DifficultyResource.Level.SENIOR: preload("res://src/difficulty/Senior.tres"),
	DifficultyResource.Level.MANAGER: preload("res://src/difficulty/Management.tres"),
}

enum Mode {
	Work,
	Crunch,
	Interview,
}

@export var keep_past_wpms := 50

@onready var wpm_calculator = $WPMCalculator
@onready var save_manager: SaveManager = $SaveManager
@onready var cache_properties: CacheProperties = $CacheProperties

var init := false

### Persisted ###
var day := 0
var completed_documents := 0
var total_overtime := 0
var difficulty_level := DifficultyResource.Level.INTERN:
	set(v):
		if v in DIFFICULTIES:
			difficulty_level = v
			difficulty = DIFFICULTIES[v]
		
		if v+1 in DIFFICULTIES:
			next_difficulty = DIFFICULTIES[v+1]
		else:
			next_difficulty = null
			
		if v-1 in DIFFICULTIES:
			prev_difficulty = DIFFICULTIES[v-1]
		else:
			prev_difficulty = null

var total_completed_words := 0
var average_wpm := 0.0
var average_accuracy := 0.0
var past_wpms := []
var past_performance := []

var has_played := false
var unlocked_modes = [Mode.Work]
var performance := 0.0

### Maybe Save? ###
var last_interview_wpm := 0.0
var last_interview_accuracy := 0.0

var last_crunch_tasks := 0
var last_crunch_time := 0.0
var last_crunch_wpm := 0.0
var last_crunch_accuracy := 0.0

### Dynamic ###
var difficulty: DifficultyResource
var next_difficulty: DifficultyResource
var prev_difficulty: DifficultyResource
var current_mode: Mode

var _logger = Logger.new("GameManager")

func _ready():
	SteamCloud.initialized.connect(_load_data)
	
func _load_data():
	var data = save_manager.load_from_slot(0)
	if data:
		cache_properties.load_data(data)
	
	self.difficulty_level = difficulty_level
	
	_logger.info("Game initialized")
	init = true
	initialized.emit()

func _exit_tree() -> void:
	_save_data()

func _save_data():
	var data = cache_properties.save_data()
	save_manager.save_to_slot(0, data)
	SteamCloud.upload_to_cloud()

func quit_game():
	exiting_game.emit()
	SceneManager.fade_out()
	await SceneManager.fade_complete
	get_tree().quit()

func start(mode: Mode = current_mode):
	if not is_mode_unlocked(mode):
		return
		
	current_mode = mode
	if Env.is_demo():
		current_mode = Mode.Work
	
	if is_work_mode():
		day += 1
	
	has_played = true
	wpm_calculator.reset()
	game_started.emit()
	SceneManager.change_scene("res://src/game.tscn") # reload_scene (sometimes?) doesn't work?

func restart():
	start()

func back_to_menu():
	SceneManager.change_scene("res://start.tscn")

func reset_values():
	day = 0
	completed_documents = 0
	total_overtime = 0
	difficulty_level = DifficultyResource.Level.INTERN
	performance = 0
	past_performance = []
	
	average_wpm = 0.0
	average_accuracy = 0.0
	total_completed_words = 0
	past_wpms = []
	
	job_quited.emit()
	_save_data()

func has_current_job():
	return day > 0

func finished_day(tasks: int, overtime: int, points: int, distraction_missed: int):
	var wpm = wpm_calculator.get_average_wpm()
	var acc = wpm_calculator.get_average_accuracy()
	var current_size = wpm_calculator.get_total_size()
	var previous_size = total_completed_words * 0.5 # count previous wpm less than the current one
	
	var missed_point = pow(2, distraction_missed)
	performance += int(points - int(overtime/2) * acc) - missed_point
	past_performance.append(performance)
	if past_performance.size() > keep_past_wpms:
		past_performance.pop_front()
	print("Performance: %s with %s, %s, %s, %s" % [performance, points, acc, overtime, missed_point])
	
	average_wpm = ((average_wpm * previous_size) + (wpm * current_size)) / (previous_size + current_size)
	average_accuracy = ((average_accuracy * previous_size) + (acc * current_size)) / (previous_size + current_size)
	past_wpms.append(average_wpm)
	if past_wpms.size() > keep_past_wpms:
		past_wpms.pop_front()
	
	wpm_calculator.reset()
	
	completed_documents += tasks
	total_overtime += overtime
	total_completed_words += tasks # For calculating WPM
	_logger.info("New Average WPM %s and Accuracy %s with %s words" % [average_wpm, average_accuracy, total_completed_words])
	
	_save_data()
	round_ended.emit()

func upload_work_scores(wpm: float = average_wpm, acc: float = average_accuracy, level: int = difficulty_level):
	if is_intern(): return
	
	var score = calculate_score(wpm, acc, level)
	var board = get_leaderboard_for_mode()
	SteamManager.upload_score(board, score, ";".join(["%.0f/%.0f%%" % [wpm, acc * 100], day, -level]))

func calculate_score(wpm: float = average_wpm, acc: float = average_accuracy, level: int = difficulty_level):
	var score = wpm * acc * level * (log(day+1)/log(10)) # +1 in log, so it doesn't return 0
	return score

func finished_interview(tasks: int, time_in_sec: int):
	last_interview_wpm = wpm_calculator.get_average_wpm()
	last_interview_accuracy = wpm_calculator.get_average_accuracy()
	wpm_calculator.reset()
	
	_upload_timed_scores(last_interview_wpm, last_crunch_accuracy, tasks)
	round_ended.emit()

func _upload_timed_scores(wpm: float, acc: float, count: int):
	var score = wpm * acc * count
	var board = get_leaderboard_for_mode()
	SteamManager.upload_score(board, score, ";".join(["%.0f/%.0f%%" % [wpm, acc * 100], count]))

func finished_crunch(tasks: int):
	last_crunch_wpm = wpm_calculator.get_average_wpm()
	last_crunch_accuracy = wpm_calculator.get_average_accuracy()
	wpm_calculator.reset()
	
	last_crunch_tasks = tasks
	last_crunch_time = 0.0
	
	_upload_endless_scores(last_crunch_wpm, last_crunch_accuracy, tasks)
	round_ended.emit()

func _upload_endless_scores(wpm: float, acc: float, count: int):
	var score = wpm * acc * count
	var board = get_leaderboard_for_mode()
	SteamManager.upload_score(board, score, ";".join(["%.0f/%.0f%%" % [wpm, acc * 100], count]))

func start_type():
	wpm_calculator.start_type()

func finish_type(word: String, mistakes: int):
	wpm_calculator.finish_type(word, mistakes)

func get_wpm():
	return average_wpm

func get_accuracy():
	return average_accuracy * 100

### Difficulty
enum PromotionTip {
	WPM,
	Documents,
	Accuracy,
	Max,
}

func can_have_promotion():
	if is_max_promotion(): return PromotionTip.Max

	var next = difficulty_level + 1
	var diff = DIFFICULTIES[next] as DifficultyResource
	
	if performance < diff.min_performance:
		return PromotionTip.Documents

	#if get_wpm() < diff.min_average_wpm:
		#return PromotionTip.WPM
#
	#if completed_documents < diff.minimum_documents:
		#return PromotionTip.Documents
#
	#if average_accuracy < diff.min_accuracy:
		#return PromotionTip.Accuracy
	
	return null
	
func take_promotion():
	if is_max_promotion(): return

	difficulty_level += 1
	_logger.info("Promoted to %s" % DifficultyResource.Level.keys()[difficulty_level])
	_save_data()

func is_max_promotion():
	if Env.is_demo() and is_senior():
		return true

	var next = difficulty_level + 1
	return is_manager() or not next in DIFFICULTIES

func is_intern():
	return difficulty_level == DifficultyResource.Level.INTERN

func is_junior():
	return difficulty_level == DifficultyResource.Level.JUNIOR

func is_senior():
	return difficulty_level == DifficultyResource.Level.SENIOR

func is_manager():
	return difficulty_level == DifficultyResource.Level.MANAGER

func get_level_text(lvl = difficulty_level, abbreviate = -1):
	var txt = DifficultyResource.Level.keys()[lvl] as String
	if abbreviate > 0 and txt.length() > abbreviate:
		txt = txt.substr(0, abbreviate) + "."
	return txt

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
	if Env.is_demo():
		return [Mode.Work]

	return unlocked_modes

func unlock_mode(mode: Mode):
	if Env.is_demo():
		_logger.warn("Cannot unlock new modes in demo")
		return

	unlocked_modes.append(mode)
	mode_unlocked.emit(mode)
	_logger.info("Unlocked Mode %s" % Mode.keys()[mode])
	_save_data()

func get_leaderboard_for_mode():
	if not Env.is_demo():
		match GameManager.current_mode:
			#GameManager.Mode.Work: return SteamManager.STORY_LEADERBOARD
			#GameManager.Mode.Crunch: return SteamManager.ENDLESS_LEADERBOARD
			#GameManager.Mode.Interview: return SteamManager.TIMED_LEADERBOARD
			_: return SteamManager.STORY_LEADERBOARD
	
	return SteamManager.DEMO_LEADERBOARD
