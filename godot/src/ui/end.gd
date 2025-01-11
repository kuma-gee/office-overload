extends Control

@onready var end_effect = $EndEffect

@export var open_sound: AudioStreamPlayer
@export var gameover_sound: AudioStreamPlayer
@export var performance_progress: TextureProgressBar

#@export_category("Interview Mode")
#@export var interview_finished: Label
#@export var interview_wpm: Label
#@export var interview_delegator: Delegator
#
#@export_category("Crunch Mode")
#@export var crunch_tasks: Label
#@export var crunch_time: Label
#@export var crunch_wpm: Label
#@export var crunch_delegator: Delegator

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
@export var ceo_win_status: Label

@export_category("Promotion")
@export var promotion_delegator: Delegator

@export_category("Mode Container")
@export var work_container: Control
@export var ceo_container: Control
@export var unlocked_container: UnlockedMode

@onready var promotion_paper: PromotionPaper = $PromotionPaper
@onready var promotion_status: PromotionStatus = $PromotionStatus
@onready var challenge_paper: ChallengePaper = $ChallengePaper

func _ready():
	work_container.hide()
	ceo_container.hide()
	
	hide()
	next_day.finished.connect(func(): GameManager.start())
	GameManager.mode_unlocked.connect(func(mode): unlocked_container.unlocked_mode(mode))
	
	promotion_paper.accepted.connect(func():
		promotion_status.open()
		
		if GameManager.is_work_mode():
			GameManager.upload_work_scores()
			_unlock_crunch_mode()
	)

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
	var win = user_tasks > boss_points
	
	ceo_player_tasks.text = "%s" % user_tasks
	ceo_boss_tasks.text = "%s" % boss_tasks
	ceo_player_mistakes.text = "%s" % user_mistakes
	ceo_boss_mistakes.text = "%s" % boss_mistakes
	ceo_win_status.text = "Congratulations!\nYou are the new CEO!" if win else "You got demoted\nto senior."
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
	
	money_used.visible = GameManager.get_assistant_cost() > 0
	money_used.text = "-$%s" % GameManager.get_assistant_cost()
	
	performance_progress.min_value = GameManager.get_min_performance()
	performance_progress.max_value = GameManager.get_max_performance()
	performance_progress.value = GameManager.performance

	var promo = GameManager.can_have_promotion() and data["grade"].points > 0
	if promo:
		if GameManager.is_manager():
			challenge_paper.open(0.2)
		else:
			promotion_paper.open(0.2)
	
	_do_open(work_container)
	
	if GameManager.is_work_mode() and not promo:
		GameManager.upload_work_scores()
		_unlock_crunch_mode()

func _promotion_tip_text(tip) -> String:
	match tip:
		GameManager.PromotionTip.WPM:
			return "The efficiency needs improvement."
		GameManager.PromotionTip.Documents:
			return "You still need more experience."
		GameManager.PromotionTip.Accuracy:
			return "The quality could be better."

	return ""

func interview_ended(finished: int):
	pass
	#interview_finished.text = "Finished %s documents" % finished
	#interview_wpm.text = "%.0f WPM / %.0f%%" % [GameManager.last_interview_wpm, GameManager.last_interview_accuracy * 100]

	#_do_open(interview_container)

func crunch_ended(finished: int, hours: int):
	pass
	#crunch_tasks.text = "Finished %s documents" % finished
	#crunch_time.text = "Worked for %s hours" % hours
	#crunch_wpm.text = "%.0f WPM / %.0f%%" % [GameManager.last_crunch_wpm, GameManager.last_crunch_accuracy * 100]
	
	#_do_open(crunch_container, gameover_sound)

func _do_open(container: Control, sound = open_sound):
	container.show()
	end_effect.do_effect()
	show()
	sound.play()

func _on_back_pressed():
	GameManager.back_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if work_container.visible or ceo_container.visible:
		if promotion_paper.visible or challenge_paper.visible:
			promotion_delegator.handle_event(event)
		else:
			day_delegator.handle_event(event)
	#elif interview_container.visible:
		#interview_delegator.handle_event(event)
	#elif crunch_container.visible:
		#crunch_delegator.handle_event(event)
