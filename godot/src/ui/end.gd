extends Control

@onready var end_effect = $EndEffect
@onready var key_reader: KeyReader = $KeyReader
@onready var leader_board_effect: EffectRoot = $LeaderBoardEffect

@export var open_sound: AudioStreamPlayer
@export var leader_board: Leaderboard

@export_category("Interview Mode")
@export var interview_finished: Label
@export var interview_wpm: Label
@export var interview_accuracy: Label
@export var interview_delegator: Delegator

@export_category("Work Mode")
@export var next_day: TypingButton
@export var next_day_container: Control
@export var promotion_container: Control
@export var title: Label
@export var overtime: Label
@export var finished_tasks: Label
@export var day_delegator: Delegator

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

func _ready():
	work_container.hide()
	interview_container.hide()
	
	next_day_container.hide()
	promotion_container.hide()
	promotion_text_container.hide()
	
	#key_reader.process_mode = Node.PROCESS_MODE_DISABLED
	#key_reader.pressed_key.connect(func(key, shift):
		#if not shift: return
		#
		#if key == "l":
			#leader_board_effect.do_effect()
			#leader_board.grab_focus()
	#)
	
	leader_board.close.connect(func():
		leader_board_effect.reverse_effect()
		get_viewport().gui_release_focus()
	)
	
	hide()
	next_day.finished.connect(func(): GameManager.start())

func day_ended(finished: int, overtime_in_hours: float):
	title.text = "Day %s report" % GameManager.day
	finished_tasks.text = "Finished %s tasks" % finished
	overtime.text = "%s hours of overtime" % overtime_in_hours
	
	var promo = GameManager.can_have_promotion()
	next_day_container.visible = not promo
	promotion_container.visible = promo
	_do_open(work_container)
	
	if GameManager.day >= 10:
		GameManager.unlock_mode(GameManager.Mode.Crunch)

func interview_ended(finished: int):
	interview_finished.text = "Finished %s documents" % finished
	interview_wpm.text = "%.0f WPM" % GameManager.last_interview_wpm
	interview_accuracy.text = "%.2f%% Accuracy" % [GameManager.last_interview_accuracy * 100]
	_do_open(interview_container)

func _do_open(container: Control):
	container.show()
	#key_reader.process_mode = Node.PROCESS_MODE_ALWAYS
	
	end_effect.do_effect()
	show()
	open_sound.play()

func _on_back_pressed():
	GameManager.back_to_menu(false)

func _on_promotion_yes_finished():
	GameManager.take_promotion()
	
	promotion_text.word = GameManager.get_level_text()
	promotion_text.focused = true
	promotion_text_container.show()
	
	promotion_particle_1.emitting = true
	promotion_particle_2.emitting = true
	promotion_sound.play()
	
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
