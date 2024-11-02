extends Control

@onready var end_effect = $EndEffect

@export var open_sound: AudioStreamPlayer
@export var gameover_sound: AudioStreamPlayer
@export var leader_board: Leaderboard

@export_category("Interview Mode")
@export var interview_finished: Label
@export var interview_wpm: Label
@export var interview_delegator: Delegator

@export_category("Crunch Mode")
@export var crunch_tasks: Label
@export var crunch_time: Label
@export var crunch_wpm: Label
@export var crunch_delegator: Delegator

@export_category("Work Mode")
@export var next_day: TypingButton
@export var next_day_container: Control
@export var promotion_container: Control
@export var title: Label
@export var overtime: Label
@export var finished_tasks: Label
@export var day_delegator: Delegator
@export var promotion_tip_text: Label
@export var perfect_tasks_label: Label
@export var distraction_label: Label
@export var acc_label: Label
@export var points_label: Label

@export_category("Promotion")
@export var promotion_text: RichTextLabel
@export var promotion_text_container: Control
@export var promotion_particle_1: GPUParticles2D
@export var promotion_particle_2: GPUParticles2D
@export var promotion_sound: AudioStreamPlayer
@export var promotion_delegator: Delegator

@export_category("Mode Container")
@export var work_container: Control
@export var interview_container: Control
@export var crunch_container: Control
@export var unlocked_container: UnlockedMode

func _ready():
	work_container.hide()
	interview_container.hide()
	crunch_container.hide()
	
	next_day_container.hide()
	promotion_container.hide()
	promotion_text_container.hide()
	
	hide()
	next_day.finished.connect(func(): GameManager.start())
	GameManager.mode_unlocked.connect(func(mode): unlocked_container.unlocked_mode(mode))

func day_ended(data: Dictionary):
	var tasks = data["total"]
	var perfect = data["perfect"]
	var overtime_hours = data["overtime"]
	var distraction_missed = data["distractions"]
	var points = data["points"]
	var acc = data["acc"]
	
	title.text = "Day %s report" % GameManager.day
	finished_tasks.text = "%s tasks" % tasks
	perfect_tasks_label.text = "+ %s perfect" % perfect
	overtime.text = "%s hours of overtime" % overtime_hours
	distraction_label.text = "%s ignored messages" % distraction_missed
	acc_label.text = "Quality %0.f%%" % [acc * 2]
	points_label.text = "Performance %s" % points
	
	var promo_tip = GameManager.can_have_promotion()
	var promo = promo_tip == null
	next_day_container.visible = not promo
	promotion_container.visible = promo
	promotion_tip_text.text = _promotion_tip_text(promo_tip)

	_do_open(work_container)
	
	if GameManager.is_work_mode() and not promo:
		GameManager.upload_work_scores()
	
	if GameManager.is_junior() and GameManager.day >= 5:
		GameManager.unlock_mode(GameManager.Mode.Crunch)

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
	interview_finished.text = "Finished %s documents" % finished
	interview_wpm.text = "%.0f WPM / %.0f%%" % [GameManager.last_interview_wpm, GameManager.last_interview_accuracy * 100]

	_do_open(interview_container)

func crunch_ended(finished: int, hours: int):
	crunch_tasks.text = "Finished %s documents" % finished
	crunch_time.text = "Worked for %s hours" % hours
	crunch_wpm.text = "%.0f WPM / %.0f%%" % [GameManager.last_crunch_wpm, GameManager.last_crunch_accuracy * 100]
	
	_do_open(crunch_container, gameover_sound)

func _do_open(container: Control, sound = open_sound):
	container.show()
	end_effect.do_effect()
	show()
	sound.play()

func _on_back_pressed():
	GameManager.back_to_menu()

func _on_promotion_yes_finished():
	GameManager.take_promotion()
	
	promotion_text.word = GameManager.get_level_text()
	promotion_text.focused = true
	promotion_text_container.show()
	
	promotion_particle_1.emitting = true
	promotion_particle_2.emitting = true
	promotion_sound.play()
	
	if GameManager.is_work_mode():
		GameManager.upload_work_scores()
	_on_promotion_no_finished()

func _on_promotion_no_finished():
	promotion_container.hide()
	next_day_container.show()

func _unhandled_input(event: InputEvent) -> void:
	if work_container.visible:
		if promotion_container.visible:
			promotion_delegator.handle_event(event)
		elif work_container.visible:
			day_delegator.handle_event(event)
	elif interview_container.visible:
		interview_delegator.handle_event(event)
	elif crunch_container.visible:
		crunch_delegator.handle_event(event)
