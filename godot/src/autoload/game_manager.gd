extends Node

signal initialized()
signal game_started()
signal round_ended()
signal job_quited()
signal exiting_game()
signal mode_unlocked(mode)
signal item_purchased()
signal item_used_toggled(item: Shop.Items)
signal coffee_used()
signal language_changed()

const GAME_SCENE = "res://src/game/game.tscn"
const START_SCENE = "res://src/start/start_new.tscn"

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

var is_motion := true
var init := false

### Persisted ###
var day := 0
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

var performance := 0

var has_played := false
var shown_ceo_tutorial := false # ceo
var shown_discard_tutorial := false # manager
var shown_distraction_tutorial := false # senior
var shown_stress_tutorial := false # junior

var finished_game := false
var unlocked_modes = [Mode.Work]
var bought_items: Array[Shop.Items] = []
var used_items: Array[Shop.Items] = []
var money := 0

### Dynamic ###
var difficulty: DifficultyResource
var next_difficulty: DifficultyResource
var prev_difficulty: DifficultyResource
var current_mode: Mode
var language := ""

var _logger = Logger.new("GameManager")

func _ready():
	self.difficulty_level = difficulty_level
	SteamCloud.initialized.connect(_load_data)
	SteamManager.init_successful.connect(func():
		_check_achievements()
	)
	
func _load_data():
	var data = save_manager.load_from_slot(0)
	if data:
		cache_properties.load_data(data)
	
	if day == 0:
		reset_values()
	
	if Env.is_editor():
		difficulty_level = DifficultyResource.Level.CEO
		finished_game = true
	
	_logger.info("Game initialized")
	init = true
	initialized.emit()

func _exit_tree() -> void:
	save_data(true)

func save_data(await_finished = false):
	var data = cache_properties.save_data()
	save_manager.save_to_slot(0, data)
	if await_finished:
		await SteamCloud.upload_to_cloud()
	else:
		SteamCloud.upload_to_cloud()

func quit_game():
	exiting_game.emit()
	SceneManager.fade_out()
	await SceneManager.fade_complete
	get_tree().quit()

func start(mode: Mode = current_mode, lang = language, lvl = difficulty_level):
	current_mode = mode
	if Env.is_demo():
		current_mode = Mode.Work

	language = lang
	WordManager.load_words(language)
	
	if current_mode != Mode.Work and not is_mode_unlocked(current_mode):
		_logger.warn("Mode %s not unlocked" % [Mode.keys()[mode]])
		return
	
	difficulty_level = lvl
	if finished_game:
		performance = difficulty.max_performance
	
	wpm_calculator.reset()
	game_started.emit()
	
	SceneManager.change_scene(GAME_SCENE)

func restart():
	start()

func back_to_menu():
	SceneManager.change_scene("res://src/start/start_new.tscn")

func reset_values():
	day = 0
	total_overtime = 0
	difficulty_level = DifficultyResource.Level.INTERN
	performance = 0
	
	average_wpm = 0.0
	average_accuracy = 0.0
	total_completed_words = 0
	past_wpms = []

	finished_game = false
	
	job_quited.emit()
	save_data()

func has_current_job():
	return day > 0

func finished_day(data: Dictionary):
	### Calculate WPM ###
	var wpm = wpm_calculator.get_average_wpm()
	var acc = wpm_calculator.get_average_accuracy()
	_update_speed_values(wpm, acc)
	data["wpm"] = wpm
	data["acc"] = acc
	
	### Calculate Performance ###
	var grade = get_grade_for(data)
	data["money"] = int(ceil(data["total"] * get_money_bonus()))
	data["grade"] = grade
	
	money += data["money"]
	performance = clamp(performance + grade.points, 0, difficulty.max_performance)
	
	_logger.debug("Performance: %s with %s" % [performance, data])
	
	if is_work_mode():
		day += 1

	save_data()
	round_ended.emit()

func _update_speed_values(wpm, acc):
	var current_size = wpm_calculator.get_total_size()
	var previous_size = total_completed_words * 0.5 # count previous wpm less than the current one
	average_wpm = roundf(((average_wpm * previous_size) + (wpm * current_size)) / (previous_size + current_size))
	average_accuracy = ((average_accuracy * previous_size) + (acc * current_size)) / (previous_size + current_size)
	average_accuracy = snappedf(average_accuracy, 0.01)

	past_wpms.append(average_wpm)
	if past_wpms.size() > keep_past_wpms:
		past_wpms.pop_front()
	
	wpm_calculator.reset()
	total_completed_words += current_size # For calculating WPM
	
	_logger.info("New Average WPM %s and Accuracy %s with %s words" % [average_wpm, average_accuracy, total_completed_words])

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
	SteamLeaderboard.upload_score(SteamLeaderboard.STORY_BOARD, score, ";".join(["%.0f/%.0f%%" % [wpm, acc * 100], day, -level]))

func calculate_score(wpm: float = average_wpm, acc: float = average_accuracy, level: int = difficulty_level):
	var lvl = level
	if level == DifficultyResource.Level.CEO and not finished_game:
		lvl = DifficultyResource.Level.MANAGER

	return wpm * acc * lvl + (day / 10.)

func finished_crunch(tasks: int, hours: int, _combo: int):
	var data = {}
	data["wpm"] = wpm_calculator.get_average_wpm()
	data["acc"] = wpm_calculator.get_average_accuracy()
	wpm_calculator.reset()
	
	data["hours"] = hours
	data["tasks"] = tasks
	data["score"] = _upload_endless_scores(data["wpm"], data["acc"], data["tasks"], data["hours"])
	
	round_ended.emit()
	return data

func _upload_endless_scores(wpm: float, acc: float, count: int, hours: int):
	var score = int(floor(wpm * acc * count) - hours)
	if not Env.is_demo():
		SteamLeaderboard.upload_score(SteamLeaderboard.ENDLESS_BOARD, score, ";".join(["%.0f/%.0f%%" % [wpm, acc * 100], count, hours]))
	
	return score
	
func lost_ceo():
	if not finished_game:
		reset_values()
	elif is_work_mode():
		day += 1
	
	save_data()
	round_ended.emit()

func won_ceo():
	finished_game = true
	#unlock_mode(Mode.Multiplayer)
	
	if is_work_mode():
		day += 1
	
	var wpm = wpm_calculator.get_average_wpm()
	var acc = wpm_calculator.get_average_accuracy()
	_update_speed_values(wpm, acc)
	upload_work_scores()
	
	round_ended.emit()
	SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.CEO)

func update_game_status(lobby = false):
	if lobby:
		SteamManager.set_rich_presence("#Prepare")
		return
	
	if is_work_mode():
		SteamManager.set_rich_presence("#Working", { "level": get_level_text(), "day": day+1 })
	elif is_crunch_mode():
		SteamManager.set_rich_presence("#Crunching")
	else:
		SteamManager.set_rich_presence("")

#region PERFORMANCE
func start_type():
	wpm_calculator.start_type()

func finish_type(word: String, mistakes: int):
	wpm_calculator.finish_type(word, mistakes)
	has_played = true

func get_wpm():
	return average_wpm

func get_accuracy():
	return average_accuracy * 100

func get_until_max_performance():
	return get_max_performance() - performance

func get_performance_within_level():
	var diff = get_max_performance() - get_min_performance()
	return diff - get_until_max_performance()

func get_min_performance():
	if not prev_difficulty: return 0
	return prev_difficulty.max_performance
	
func get_max_performance():
	return difficulty.max_performance
#endregion


#region ITEMS
const PLANT_STRESS_REDUCTION = [0.1, 0.2, 0.25]
const MONEY_INCREASE = [0.1, 0.2]
const ASSISTANT_REDUCTION = [0.1, 0.25]
const ASSISTANT_COST = 100
const DEMO_ITEMS = [Shop.Items.PLANT, Shop.Items.COFFEE]

func is_item_available(item: Shop.Items):
	return not Env.is_demo() or item in DEMO_ITEMS

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
	if item.type not in used_items:
		used_items.append(item.type)
	
	item_purchased.emit()
	save_data()
	return true

func pay_assistant():
	if is_item_used(Shop.Items.ASSISTANT):
		money -= get_assistant_cost()
		save_data()

func is_item_used(item: Shop.Items):
	return item in used_items and item in bought_items and is_item_available(item)

func toggle_item_used(item: Shop.Items):
	if item in used_items:
		used_items.erase(item)
	else:
		used_items.append(item)
	
	item_used_toggled.emit(item)

func is_item_max(item: ShopResource):
	return item_count(item.type) >= item.prices.size()

func item_count(item: Shop.Items):
	if not is_item_available(item): return 0
	return bought_items.count(item)

func item_price(item: ShopResource):
	var item_bought = item_count(item.type)
	return item.prices[min(item_bought, item.prices.size() - 1)]

func get_assistant_cost():
	return item_count(Shop.Items.ASSISTANT) * ASSISTANT_COST

func get_item_value(item: Shop.Items, count = item_count(item)):
	var arr = []
	match item:
		Shop.Items.PLANT: arr = PLANT_STRESS_REDUCTION
		Shop.Items.MONEY_CAT: arr = MONEY_INCREASE
		Shop.Items.ASSISTANT: arr = ASSISTANT_REDUCTION
	
	var i = count - 1
	if arr.is_empty() or i < 0: return 0.0
	if i >= arr.size(): return arr[arr.size() - 1]

	return arr[i]

func get_stress_reduction():
	if is_crunch_mode(): return 1.0
	
	var reduction = get_item_value(Shop.Items.PLANT)
	return clamp(1.0 - reduction, 0.0, 1.0)

func get_money_bonus():
	var multiplier = difficulty.money_multiplier
	multiplier += get_item_value(Shop.Items.MONEY_CAT)
	return multiplier

func get_distraction_reduction(invert = false):
	if is_crunch_mode(): return 1.0 if not invert else 0.0
	
	var reduction = get_item_value(Shop.Items.ASSISTANT)
	return 1.0 - reduction if not invert else reduction

func has_coffee():
	if is_crunch_mode(): return false
	return Shop.Items.COFFEE in bought_items and Shop.Items.COFFEE in used_items

func use_coffee():
	if not has_coffee():
		return 0.0

	bought_items.erase(Shop.Items.COFFEE)
	used_items.erase(Shop.Items.COFFEE)
	
	save_data()
	coffee_used.emit()
	return 100.0
#endregion

#region DIFFICULTY
enum PromotionTip {
	WPM,
	Documents,
	Accuracy,
	Max,
}

func can_have_promotion():
	if is_max_promotion(): return false
	return performance >= difficulty.max_performance
	
func take_promotion():
	if is_max_promotion(): return

	difficulty_level += 1
	_logger.info("Promoted to %s" % DifficultyResource.Level.keys()[difficulty_level])
	
	_check_achievements()
	save_data()
	
func _check_achievements():
	if is_junior():
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.JUNIOR)
	elif is_senior():
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.SENIOR)
	elif is_manager():
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.MANAGER)

func demote():
	difficulty_level -= 1
	save_data()

func is_max_promotion():
	if Env.is_demo() and is_senior():
		return true
	
	if finished_game:
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

func is_finished_game():
	return finished_game

func get_level_text(lvl = difficulty_level, abbreviate = -1):
	var txt = DifficultyResource.Level.keys()[lvl] as String
	if abbreviate > 0 and txt.length() > abbreviate:
		txt = txt.substr(0, abbreviate) + "."
	return txt.to_lower()

#endregion

#region MODES
enum Mode {
	Work,
	Crunch,
	Multiplayer, # TODO: add multiplayer, after release?
}


var MODE_TITLE = {
	Mode.Work: "Work Day",
	Mode.Crunch: "Crunch Time",
	Mode.Multiplayer: "Multiplayer",
}

func is_work_mode():
	return current_mode == Mode.Work
	
func is_crunch_mode():
	return current_mode == Mode.Crunch

func is_mode_unlocked(mode: Mode):
	if Env.is_demo():
		return mode == Mode.Work

	if not mode in unlocked_modes:
		return false
	
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
	
	if mode in unlocked_modes: return
	
	if mode == Mode.Multiplayer:
		_logger.warn("Multiplayer not implemented yet.")
		unlocked_modes.append(mode)
		return

	unlocked_modes.append(mode)
	mode_unlocked.emit(mode)
	_logger.info("Unlocked Mode %s" % Mode.keys()[mode])
	save_data()

func get_leaderboard_for_mode(mode = GameManager.current_mode):
	if Env.is_demo():
		return SteamLeaderboard.DEMO_BOARD

	return SteamLeaderboard.STORY_BOARD
	
#endregion
