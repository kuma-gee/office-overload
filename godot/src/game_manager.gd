extends Node

signal initialized()
signal game_started()
signal round_ended()
signal job_quited()
signal exiting_game()
signal mode_unlocked(mode)
signal item_purchased()

signal logged(line)

const DIFFICULTIES = {
	DifficultyResource.Level.INTERN: preload("res://src/difficulty/Intern.tres"),
	DifficultyResource.Level.JUNIOR: preload("res://src/difficulty/Junior.tres"),
	DifficultyResource.Level.SENIOR: preload("res://src/difficulty/Senior.tres"),
	DifficultyResource.Level.MANAGER: preload("res://src/difficulty/Management.tres"),
	DifficultyResource.Level.CEO: preload("res://src/difficulty/CEO.tres"),
}

@export var keep_past_wpms := 50
@export var grades: Array[GradeResource] = []

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
		
		if v+1 in DIFFICULTIES and not is_max_promotion():
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
var has_reached_junior := false
var unlocked_modes = [Mode.Work]
var performance := 0

var received_promotion_day := 0
var days_since_promotion := 0
var money := 0

var bought_items: Array[Shop.Items]= []

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
	
	#self.difficulty_level = DifficultyResource.Level.INTERN
	#unlocked_modes = Mode.values()
	
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
	
	has_played = true
	wpm_calculator.reset()
	game_started.emit()
	
	if mode == Mode.Work:
		SceneManager.change_scene("res://src/game.tscn")
	else:
		SceneManager.change_scene("res://src/gamemode/bonus_game.tscn")

func restart():
	start()

func back_to_menu():
	SceneManager.change_scene("res://src/start/start_new.tscn")

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

	received_promotion_day = 0
	days_since_promotion = 0
	
	job_quited.emit()
	_save_data()

func has_current_job():
	return day > 0

func finished_day(data: Dictionary):
	### Calculate WPM ###
	var wpm = wpm_calculator.get_average_wpm()
	var acc = wpm_calculator.get_average_accuracy()
	var current_size = wpm_calculator.get_total_size()
	var previous_size = total_completed_words * 0.5 # count previous wpm less than the current one
	data["wpm"] = wpm
	data["acc"] = acc

	average_wpm = ((average_wpm * previous_size) + (wpm * current_size)) / (previous_size + current_size)
	average_accuracy = ((average_accuracy * previous_size) + (acc * current_size)) / (previous_size + current_size)
	past_wpms.append(average_wpm)
	if past_wpms.size() > keep_past_wpms:
		past_wpms.pop_front()
	
	wpm_calculator.reset()
	total_completed_words += current_size # For calculating WPM
	_logger.info("New Average WPM %s and Accuracy %s with %s words" % [average_wpm, average_accuracy, total_completed_words])
	
	### Calculate Performance ###
	var grade = get_grade_for(data)
	data["money"] = int(ceil(difficulty.money * (get_money_bonus() + grade.money_multiplier)))
	data["grade"] = grade
	
	money += data["money"]
	performance = clamp(performance + grade.points, 0, difficulty.max_performance)
	
	past_performance.append(performance)
	if past_performance.size() > keep_past_wpms:
		past_performance.pop_front()
	_logger.debug("Performance: %s with %s" % [performance, data])
	
	# completed_documents += tasks
	# total_overtime += overtime
	
	if is_work_mode():
		day += 1
		days_since_promotion += 1

	_save_data()
	round_ended.emit()

# deprecated??
func calculate_performance(data: Dictionary):
	var total = data["total"]
	var wrong = data["wrong"]
	var overtime = data["overtime"]
	var stress = data["stress"]
	var acc = data["acc"]
	
	var wrong_points = pow(wrong, 1.2)
	
	var points = total
	points -= wrong_points
	data["points"] = points
	
	var grade = get_grade_for(data)
	data["grade"] = grade
	
	return points

func get_grade_for(data: Dictionary):
	var wrong = data["wrong"]
	var overtime = data["overtime"]
	var stress = data["stress"]
	var acc = data["acc"]
	var tasks = data["tasks"]
	
	for grade in grades:
		if stress <= grade.stress and wrong <= grade.mistakes and overtime <= grade.overtime and acc >= grade.accuracy and tasks >= grade.documents:
			return grade
			
	return grades[grades.size() - 1]

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

### Performance
func get_until_max_performance():
	return difficulty.max_performance - performance

### Items
func buy_item(item: ShopResource):
	if is_item_max(item):
		_logger.warn("Item %s already at max upgrade" % Shop.Items.keys()[item.type])
		return false
	
	var price = item_price(item)
	if money < price:
		_logger.warn("Not enough money to buy %s" % Shop.Items.keys()[item.type])
		return false

	money -= price
	bought_items.append(item.type)
	item_purchased.emit()
	_save_data()
	return true

func is_item_max(item: ShopResource):
	return item_count(item.type) >= item.prices.size()

func item_count(item: Shop.Items):
	return bought_items.count(item)

func item_price(item: ShopResource):
	var item_bought = item_count(item.type)
	return item.prices[min(item_bought, item.prices.size() - 1)]

func get_stress_reduction():
	if not Shop.Items.PLANT in bought_items:
		return 1.0
	return 0.8

func get_money_bonus():
	if not Shop.Items.MONEY_CAT in bought_items:
		return 1.0
	return 1.2

func get_distraction_reduction():
	if not Shop.Items.DO_NOT_DISTURB in bought_items:
		return 1.0
	return 0.8

func has_coffee():
	return Shop.Items.COFFEE in bought_items

func use_coffee():
	if not has_coffee():
		return 0.0

	bought_items.erase(Shop.Items.COFFEE)
	_save_data()
	return 100.0

### Difficulty
enum PromotionTip {
	WPM,
	Documents,
	Accuracy,
	Max,
}

func can_have_promotion():
	if is_max_promotion(): return PromotionTip.Max

	#var next = difficulty_level + 1
	#var diff = DIFFICULTIES[next] as DifficultyResource
	
	if performance < difficulty.max_performance:
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
	
	if difficulty_level >= DifficultyResource.Level.JUNIOR:
		has_reached_junior = true
	
	received_promotion_day = day
	days_since_promotion = 0
	_save_data()

func is_max_promotion():
	if Env.is_demo() and is_senior():
		return true

	var next = difficulty_level + 1
	return not next in DIFFICULTIES

func is_level_greater_or_eq(diff: DifficultyResource.Level):
	return difficulty_level >= diff

func is_intern():
	return difficulty_level == DifficultyResource.Level.INTERN

func is_junior():
	return difficulty_level == DifficultyResource.Level.JUNIOR

func is_senior():
	return difficulty_level == DifficultyResource.Level.SENIOR

func is_manager():
	return difficulty_level == DifficultyResource.Level.MANAGER

func is_ceo():
	return difficulty_level == DifficultyResource.Level.CEO

func get_level_text(lvl = difficulty_level, abbreviate = -1):
	var txt = DifficultyResource.Level.keys()[lvl] as String
	if abbreviate > 0 and txt.length() > abbreviate:
		txt = txt.substr(0, abbreviate) + "."
	return txt

### Modes
enum Mode {
	Work,
	Crunch,
	Interview,

	Meeting,
	AfterworkBeer,
	MorningCoffee,

	Multiplayer, # TODO: add multiplayer, after release?
}

var MODE_CONDITION = {
	Mode.Meeting: func(): return is_senior(),
	Mode.AfterworkBeer: func(): return true, # TODO: check if overtime stress is high
	Mode.MorningCoffee: func(): return is_junior(),
}

var MODE_TITLE = {
	Mode.Work: "Work Day",
	Mode.Crunch: "Crunch Time",
	Mode.Interview: "Job Interview",
	Mode.Meeting: "Meeting",
	Mode.AfterworkBeer: "Afterwork Beer",
	Mode.MorningCoffee: "Morning Coffee",
}

func is_interview_mode():
	return current_mode == Mode.Interview

func is_work_mode():
	return current_mode == Mode.Work
	
func is_crunch_mode():
	return current_mode == Mode.Crunch

func is_meeting_mode():
	return current_mode == Mode.Meeting

func is_afterwork_mode():
	return current_mode == Mode.AfterworkBeer

func is_morning_mode():
	return current_mode == Mode.MorningCoffee

func is_mode_unlocked(mode: Mode):
	if Env.is_demo():
		return mode == Mode.Work

	if not mode in unlocked_modes:
		return false

	#if mode in MODE_CONDITION:
		#var condition = MODE_CONDITION.get(mode)
		#if not condition.call():
			#return false
	
	return true

func get_mode_title(mode: Mode):
	if mode in MODE_TITLE:
		return MODE_TITLE[mode]
	return ""

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
