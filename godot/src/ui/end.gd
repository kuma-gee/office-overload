extends Control

@onready var end_effect = $EndEffect
@onready var finished_tasks = $CenterContainer/VBoxContainer/VBoxContainer/FinishedTasks
@onready var overtime = $CenterContainer/VBoxContainer/VBoxContainer/Overtime
@onready var audio_stream_player = $AudioStreamPlayer
@onready var title = $CenterContainer/VBoxContainer/Title

@export var next_day: TypingButton
@export var next_day_container: Control
@export var promotion_container: Control

func _ready():
	next_day_container.hide()
	promotion_container.hide()
	
	hide()
	next_day.finished.connect(func(): GameManager.next_day())

func day_ended(finished: int, overtime_in_hours: float):
	get_tree().paused = true
	
	title.text = "Day %s report" % GameManager.day
	finished_tasks.text = "Finished %s tasks" % finished
	overtime.text = "%s hours of overtime" % overtime_in_hours
	
	var promo = GameManager.can_have_promotion()
	next_day_container.visible = not promo
	promotion_container.visible = promo
	
	end_effect.do_effect()
	show()
	audio_stream_player.play()

func _on_back_pressed():
	GameManager.back_to_menu(false)


func _on_promotion_yes_finished():
	GameManager.take_promotion()

func _on_promotion_no_finished():
	GameManager.next_day()
