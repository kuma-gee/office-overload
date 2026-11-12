extends Node

signal initialized()
signal game_started()
signal round_ended()
signal job_quited()
signal exiting_game()
signal mode_unlocked(mode)
signal mutator_unlocked(mutator)
signal mutator_toggled(mutator)
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

enum Mutator {
	PAPER_JAM,
	CRUNCH,
	PART_TIME,
	OPEN_OFFICE,
	AFTER_HOURS,
	TYPO_TAX,
}

const NG_PLUS_TITLE = "New Contract"

const MUTATOR_NAME = {
	Mutator.PAPER_JAM: "Paper Jam",
	Mutator.CRUNCH: "Crunch",
	Mutator.PART_TIME: "Part Time",
	Mutator.OPEN_OFFICE: "Open Office",
	Mutator.AFTER_HOURS: "After Hours",
	Mutator.TYPO_TAX: "Typo Tax",
}

const MUTATOR_DESC = {
	Mutator.PAPER_JAM: "Documents +30%\nsalary +20%",
	Mutator.CRUNCH: "Stress +30%\ndocument +1 point",
	Mutator.PART_TIME: "Workday ends at 14:00\nsalary -20%",
	Mutator.OPEN_OFFICE: "Double distractions\nfinish one -25 stress",
	Mutator.AFTER_HOURS: "Work +2h overtime\n+2 performance",
	Mutator.TYPO_TAX: "Typo +5 stress\nsalary +20%",
}

const OVERTIME_GRIT := 2

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

var zen_total_documents := 0
var zen_total_hours := 0

var new_game_plus := 0
var unlocked_mutators = []
var active_mutators = []

### Dynamic ###
var difficulty: DifficultyResource
var next_difficulty: DifficultyResource
var prev_difficulty: DifficultyResource
var current_mode: Mode
var language := ""

var _logger = KumaLog.new("GameManager")

func _ready():
	self.difficulty_level = difficulty_level
	SteamCloud.initialized.connect(_load_data)
	SteamManager.init_successful.connect(func(): _check_achievements())

func _load_data():
	var data = save_manager.load_from_slot(0)
	if data:
		cache_properties.load_data(data)
	
	if day == 0:
		reset_values()
	
	if Env.is_editor():
		difficulty_level = DifficultyResource.Level.CEO
		finished_game = true
		has_played = true
		unlocked_modes = Mode.values()
		new_game_plus = 1
		unlocked_mutators = [Mutator.PAPER_JAM]
		active_mutators = [Mutator.PAPER_JAM]
		#bought_items = []
	
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

#region NEW GAME+ / MUTATORS
func is_new_game_plus():
	return new_game_plus > 0

func has_mutators_unlocked():
	return not unlocked_mutators.is_empty()

func has_mutator(mutator: Mutator):
	return is_mutator_active(mutator)

func is_mutator_active(mutator: Mutator):
	return mutator in unlocked_mutators and mutator in active_mutators

func has_all_mutators_active() -> bool:
	return unlocked_mutators.all(func(m): return m in active_mutators)

func toggle_mutator(mutator: Mutator):
	if mutator not in unlocked_mutators:
		return

	if mutator in active_mutators:
		active_mutators.erase(mutator)
	else:
		active_mutators.append(mutator)

	mutator_toggled.emit(mutator)
	save_data()
	_logger.info("Mutator %s toggled: active=%s" % [Mutator.keys()[mutator], is_mutator_active(mutator)])

func get_mutator_name(mutator: Mutator):
	return MUTATOR_NAME.get(mutator, "?")

func get_mutator_desc(mutator: Mutator):
	return MUTATOR_DESC.get(mutator, "")

func get_active_mutator_names():
	return _mutator_names(active_mutators)

func get_policies_summary() -> String:
	return "%s/%s policies active" % [active_mutators.size(), Mutator.values().size()]

func get_unlocked_mutator_names():
	return _mutator_names(unlocked_mutators)

func get_mutator_info(mutator: Mutator) -> String:
	return "%s: %s" % [get_mutator_name(mutator), get_mutator_desc(mutator)]

func get_active_mutator_infos() -> String:
	return _mutator_infos(active_mutators)

func get_unlocked_mutator_infos() -> String:
	return _mutator_infos(unlocked_mutators)

func _mutator_infos(mutators: Array) -> String:
	var parts: Array[String] = []
	for m in mutators:
		parts.append(get_mutator_info(m))
	return "\n".join(parts)

func _mutator_names(mutators: Array) -> String:
	var parts: Array[String] = []
	for m in mutators:
		parts.append(get_mutator_name(m))
	return ", ".join(parts)

func grant_random_mutator() -> int:
	var locked = Mutator.values().filter(func(m): return m not in unlocked_mutators)
	if locked.is_empty():
		return -1

	var m: int = locked.pick_random()
	unlocked_mutators.append(m)
	if m not in active_mutators:
		active_mutators.append(m)
	mutator_unlocked.emit(m)
	save_data()
	_logger.info("Unlocked mutator %s" % Mutator.keys()[m])
	return m

func sign_new_contract():
	if Env.is_demo():
		_logger.warn("New Contract is not available in the demo")
		return

	active_mutators = active_mutators.filter(func(m): return m in unlocked_mutators)
	new_game_plus += 1
	reset_all()
	_logger.info("Signed %s #%s with policies: %s" % [NG_PLUS_TITLE, new_game_plus, get_active_mutator_names()])
	back_to_menu()

func reset_all():
	reset_values()
	money = 0
	bought_items = []
	used_items = []
	save_data()

func get_spawn_time_multiplier() -> float:
	if not is_work_mode(): return 1.0
	return 0.7 if has_mutator(Mutator.PAPER_JAM) else 1.0

func get_stress_multiplier() -> float:
	if not is_work_mode(): return 1.0
	return 1.3 if has_mutator(Mutator.CRUNCH) else 1.0

func get_document_point_bonus() -> int:
	if not is_work_mode(): return 0
	return 1 if has_mutator(Mutator.CRUNCH) else 0

func get_end_hour() -> int:
	if not is_work_mode() or is_ceo(): return 18
	return 14 if has_mutator(Mutator.PART_TIME) else 18

func get_overtime_spawn_hours() -> int:
	if not is_work_mode(): return 0
	return 2 if has_mutator(Mutator.AFTER_HOURS) else 0

func get_distraction_frequency_multiplier() -> float:
	if not is_work_mode(): return 1.0
	return 2.0 if has_mutator(Mutator.OPEN_OFFICE) else 1.0

func get_sharp_eyes_stress() -> float:
	if not is_work_mode(): return 0.0
	return 5.0 if has_mutator(Mutator.TYPO_TAX) else 0.0
#endregion

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
	var grit: int = OVERTIME_GRIT if has_mutator(Mutator.AFTER_HOURS) and data["overtime"] > 0 else 0
	performance = clamp(performance + grade.points + grit, 0, difficulty.max_performance)
	
	_logger.debug("Performance: %s with %s" % [performance, data])
	
	if is_work_mode():
		day += 1
	
	_check_day_achievements(data)

	save_data()
	round_ended.emit()

func _check_day_achievements(data: Dictionary):
	if data["overtime"] > 0:
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.OVERTIME)
	
	if data["tasks"] > 0 and data["wrong"] == 0 and data["acc"] >= 1.0:
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.FLAWLESS)
	
	if data["grade"].grade == "S":
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.TOP_GRADE)
	
	if data["combo"] >= 25:
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.COMBO_25)
	
	if money >= 10000:
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.RICH)
	
	if is_work_mode():
		if day == 1:
			SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.FIRST_DAY)
		elif day >= 10:
			SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.WORKAHOLIC)

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
	
	if total_completed_words >= 1000:
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.WORDS_1K)
	if total_completed_words >= 10000:
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.WORDS_10K)
	
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

func finished_multiplayer(tasks: int, hours: int):
	var data = {}
	data["wpm"] = int(wpm_calculator.get_average_wpm())
	data["acc"] = int(wpm_calculator.get_average_accuracy() * 100)
	wpm_calculator.reset()
	
	data["hours"] = hours
	data["tasks"] = tasks
	data["score"] = _calc_crunch_score(data["wpm"], data["acc"], tasks, hours)
	
	round_ended.emit()
	return data

func _calc_crunch_score(wpm: float, acc: float, count: int, hours: int):
	return max(int(floor(wpm * acc * count) - hours), 0)

func _upload_endless_scores(wpm: float, acc: float, count: int, hours: int):
	var score = _calc_crunch_score(wpm, acc, count, hours)
	if not Env.is_demo():
		SteamLeaderboard.upload_score(SteamLeaderboard.ENDLESS_BOARD, score, ";".join(["%.0f/%.0f%%" % [wpm, acc], count, hours]))
	
	return score

func finished_zen(documents: int = zen_total_documents, hours: int = zen_total_hours):
	if not GameManager.is_zen_mode(): return

	var wpm = int(wpm_calculator.get_average_wpm())
	var acc = int(wpm_calculator.get_average_accuracy() * 100)
	wpm_calculator.reset()
	_upload_zen_scores(wpm, acc, documents, hours)

func _upload_zen_scores(wpm: float, acc: float, documents: int, hours: int):
	if not Env.is_demo():
		SteamLeaderboard.upload_score(SteamLeaderboard.ZEN_BOARD, documents, ";".join(["%.0f/%.0f%%" % [wpm, acc * 100], documents, hours]))
	
	return documents
	
func lost_ceo():
	SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.FIRED)
	
	if not finished_game:
		reset_values()
	elif is_work_mode():
		day += 1
	
	save_data()
	round_ended.emit()

func won_ceo() -> int:
	var was_finished = finished_game
	finished_game = true
	unlock_mode(Mode.Multiplayer)

	if is_work_mode():
		day += 1

	var granted := -1
	if not was_finished and has_all_mutators_active():
		granted = grant_random_mutator()

	var wpm = wpm_calculator.get_average_wpm()
	var acc = wpm_calculator.get_average_accuracy()
	_update_speed_values(wpm, acc)
	upload_work_scores()

	round_ended.emit()
	SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.CEO)
	return granted

func update_game_status(lobby = false):
	if not SteamManager.is_successful_initialized: return
	
	if lobby:
		SteamManager.set_rich_presence("#Prepare")
		return
	
	if is_work_mode():
		SteamManager.set_rich_presence("#Working", { "level": get_level_text(), "day": day+1 })
	elif is_crunch_mode():
		SteamManager.set_rich_presence("#Crunching")
	elif is_multiplayer_mode():
		SteamManager.set_rich_presence("#Competing")
	elif is_zen_mode():
		SteamManager.set_rich_presence("#Zen")
	else:
		SteamManager.set_rich_presence("")

#region PERFORMANCE
const FIRING_PERFORMANCE_RATIO := 0.75

func get_firing_threshold() -> int:
	return floori(get_min_performance() * FIRING_PERFORMANCE_RATIO)

func is_below_firing_threshold() -> bool:
	return is_work_mode() and performance < get_firing_threshold()

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
const PLANT_STRESS_REDUCTION = [0.1, 0.2, 0.25, 0.3, 0.35]
const MONEY_INCREASE = [0.1, 0.2, 0.3, 0.4]
const ASSISTANT_REDUCTION = [0.1, 0.25, 0.35]
const ASSISTANT_COST = 100
const DEMO_ITEMS = [Shop.Items.PLANT, Shop.Items.COFFEE]
const BASE_ITEM_TIERS = {
	Shop.Items.PLANT: 3,
	Shop.Items.COFFEE: 1,
	Shop.Items.ASSISTANT: 2,
	Shop.Items.MONEY_CAT: 2,
	Shop.Items.RUBBER_DUCK: 1,
}

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
	SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.FIRST_BUY)
	if Shop.Items.values().all(func(item): return item in bought_items):
		SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.FULLY_EQUIPPED)
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

func get_max_item_tiers(item: ShopResource):
	if is_new_game_plus():
		return item.prices.size()
	return min(item.prices.size(), BASE_ITEM_TIERS.get(item.type, item.prices.size()))

func is_item_max(item: ShopResource):
	return item_count(item.type) >= get_max_item_tiers(item)

func item_count(item: Shop.Items):
	if not is_item_available(item): return 0
	return bought_items.count(item)

func item_price(item: ShopResource):
	var item_bought = item_count(item.type)
	return item.prices[min(item_bought, get_max_item_tiers(item) - 1)]

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
	if not is_work_mode(): return 1.0
	
	var reduction = get_item_value(Shop.Items.PLANT)
	return clamp(1.0 - reduction, 0.0, 1.0)

func get_money_bonus():
	var multiplier = difficulty.money_multiplier
	multiplier += get_item_value(Shop.Items.MONEY_CAT)
	if is_work_mode():
		if has_mutator(Mutator.PAPER_JAM):
			multiplier += 0.20
		if has_mutator(Mutator.PART_TIME):
			multiplier -= 0.20
		if has_mutator(Mutator.TYPO_TAX):
			multiplier += 0.20
	return multiplier

func get_distraction_reduction(invert = false):
	if not is_work_mode(): return 1.0 if not invert else 0.0
	
	var reduction = get_item_value(Shop.Items.ASSISTANT)
	return 1.0 - reduction if not invert else reduction

func has_coffee():
	if not is_work_mode(): return false
	return Shop.Items.COFFEE in bought_items and Shop.Items.COFFEE in used_items

func use_coffee():
	if not has_coffee():
		return 0.0

	bought_items.erase(Shop.Items.COFFEE)
	used_items.erase(Shop.Items.COFFEE)
	
	save_data()
	coffee_used.emit()
	SteamAchievements.unlock(SteamAchievements.ACHIEVEMENT.CAFFEINE)
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

func is_at_least(level: DifficultyResource.Level):
	return difficulty_level >= level

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
	Multiplayer,
	Zen,
}


var MODE_TITLE = {
	Mode.Work: "Work Day",
	Mode.Crunch: "Crunch Time",
	Mode.Multiplayer: "Compete",
	Mode.Zen: "Zen",
}

func is_work_mode():
	return current_mode == Mode.Work
	
func is_crunch_mode():
	return current_mode == Mode.Crunch

func is_multiplayer_mode():
	return current_mode == Mode.Multiplayer
	
func is_zen_mode():
	return current_mode == Mode.Zen

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
	
	unlocked_modes.append(mode)
	mode_unlocked.emit(mode)
	_logger.info("Unlocked Mode %s" % Mode.keys()[mode])
	save_data()

func get_leaderboard_for_mode(mode = GameManager.current_mode):
	if Env.is_demo():
		return SteamLeaderboard.DEMO_BOARD

	return SteamLeaderboard.STORY_BOARD
	
#endregion
