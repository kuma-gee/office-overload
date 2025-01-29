extends Control

@onready var end_effect = $EndEffect

@export var open_sound: AudioStreamPlayer
@export var gameover_sound: AudioStreamPlayer
@export var performance_progress: TextureProgressBar
@export var level_label: Label

@export_category("Crunch Mode")
@export var crunch_tasks: Label
@export var crunch_time: Label
@export var crunch_wpm: Label
@export var crunch_acc: Label
@export var crunch_score: Label
@export var retry_button: TypingButton
@export var highscore_board: Control
@export var crunch_offline: Control

@export_category("Work Mode")
@export var next_day: TypingButton
@export var next_day_container: Control
@export var title: Label
@export var finished_tasks: Label
@export var day_delegator: Delegator
@export var promotion_tip_text: Label
@export var perfect_tasks_label: Label
@export var distraction_label: Label
@export var grade_label: Label
@export var wpm_label: Label
@export var money_label: Label
@export var bonus_label: Label
@export var money_used: Label

@export_category("CEO")
@export var ceo_player_tasks: Label
@export var ceo_boss_tasks: Label
@export var ceo_player_mistakes: Label
@export var ceo_boss_mistakes: Label
@export var ceo_player_score: Label
@export var ceo_boss_score: Label
@export var ceo_win_status: Label

@export_category("Promotion")
@export var promotion_delegator: Delegator

@export_category("Mode Container")
@export var work_container: Control
@export var ceo_container: Control
@export var unlocked_container: UnlockedMode
@export var crunch_container: Control

@onready var promotion_paper: PromotionPaper = $PromotionPaper
@onready var promotion_status: PromotionStatus = $PromotionStatus
@onready var challenge_paper: ChallengePaper = $ChallengePaper
@onready var menu_paper: EndScorePaper = $Control/MenuPaper

func _ready():
	work_container.hide()
	ceo_container.hide()
	crunch_container.hide()
	highscore_board.hide()
	
	hide()
	next_day.finished.connect(func(): GameManager.start())
	GameManager.mode_unlocked.connect(func(mode):
		unlocked_container.unlocked_mode(mode)
	)
	
	promotion_paper.accepted.connect(func():
		promotion_status.open()
		_work_day_finished()
	)
	
	retry_button.finished.connect(func(): GameManager.start())

func _unlock_crunch_mode():
	if GameManager.is_senior() or GameManager.is_manager() or GameManager.is_ceo():
		GameManager.unlock_mode(GameManager.Mode.Crunch)

func ceo_ended(user: Dictionary, boss: Dictionary):
	var user_tasks = user["tasks"]
	var boss_tasks = boss["tasks"]
	var user_mistakes = user["mistakes"]
	var boss_mistakes = boss["mistakes"]
	var user_points = user_tasks - user_mistakes
	var boss_points = boss_tasks - boss_mistakes
	var win = user_points > boss_points
	
	ceo_player_tasks.text = "%s" % user_tasks
	ceo_boss_tasks.text = "%s" % boss_tasks
	ceo_player_mistakes.text = "%s" % user_mistakes
	ceo_boss_mistakes.text = "%s" % boss_mistakes
	ceo_player_score.text = "%s" % user_points
	ceo_boss_score.text = "%s" % boss_points
	
	if GameManager.finished_game:
		ceo_win_status.text = "Congratulations!\nYou proved your CEO skills!" if win else "You should practice\nyour skills more."
	else:
		ceo_win_status.text = "Congratulations!\nYou are the new CEO!" if win else "You lost\nand have been fired."
		
	_do_open(ceo_container)
	
	if win:
		GameManager.won_ceo()
	else:
		GameManager.lost_ceo()


func day_ended(data: Dictionary):
	var tasks = data["tasks"]
	var combo = data["combo"]
	var wrong = data["wrong"]

	grade_label.text = data["grade"].grade
	title.text = "Day %s report" % GameManager.day
	finished_tasks.text = "%s" % tasks
	perfect_tasks_label.text = "%s" % combo
	money_label.text = "$%0.f" % data["money"]
	distraction_label.text = "%s" % wrong
	wpm_label.text = "%0.f" % data["wpm"]
	bonus_label.text = "x%s" % GameManager.difficulty.money_multiplier
	
	money_used.visible = GameManager.get_assistant_cost() > 0 and GameManager.is_item_used(Shop.Items.ASSISTANT)
	money_used.text = "-$%s" % GameManager.get_assistant_cost()
	
	performance_progress.min_value = GameManager.get_min_performance()
	performance_progress.max_value = GameManager.get_max_performance()
	performance_progress.value = GameManager.performance
	
	if GameManager.next_difficulty:
		if GameManager.is_max_promotion() and Env.is_demo():
			level_label.text = "End of demo"
		else:
			level_label.text = GameManager.get_level_text(GameManager.next_difficulty.level)
	level_label.visible = performance_progress.value == performance_progress.max_value or (GameManager.is_max_promotion() and GameManager.get_until_max_performance() <= 0)

	var promo = GameManager.can_have_promotion() # and (data["grade"].points > 0 or GameManager.get_until_max_performance() == 0)
	if promo:
		if GameManager.is_manager():
			challenge_paper.open(0.2)
		else:
			promotion_paper.open(0.2)
	
	_do_open(work_container)
	
	if not promo:
		_work_day_finished()

func _work_day_finished():
	if GameManager.is_work_mode():
		GameManager.upload_work_scores()
		_unlock_crunch_mode()

func crunch_ended(data: Dictionary):
	crunch_tasks.text = "%s" % data["tasks"]
	crunch_time.text = "%sh" % data["hours"]
	crunch_wpm.text = "%.0f" % data["wpm"]
	crunch_acc.text = "%.0f%%" % [data["acc"] * 100]
	crunch_score.text = "%s" % data["score"]
	
	#crunch_offline.visible = false #not GameManager.unsaved_crunch_score.is_empty()
	
	_do_open(crunch_container, gameover_sound)

func _do_open(container: Control, sound = open_sound):
	container.show()
	end_effect.do_effect()
	show()
	sound.play()

func _on_back_pressed():
	GameManager.back_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if work_container.visible or ceo_container.visible or crunch_container.visible:
		if promotion_paper.visible or challenge_paper.visible:
			promotion_delegator.handle_event(event)
		else:
			day_delegator.handle_event(event)
