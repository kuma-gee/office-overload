extends Control

@onready var end_effect = $EndEffect
@onready var finished_tasks = $CenterContainer/VBoxContainer/VBoxContainer/FinishedTasks
@onready var overtime = $CenterContainer/VBoxContainer/VBoxContainer/Overtime
@onready var audio_stream_player = $AudioStreamPlayer
@onready var title = $CenterContainer/VBoxContainer/Title

@export var next: Button

func _ready():
	hide()

func day_ended(finished: int, overtime_in_hours: float):
	title.text = "Day %s report" % GameManager.day
	finished_tasks.text = "Finished %s tasks" % finished
	overtime.text = "%s hours of overtime" % overtime_in_hours
	
	end_effect.do_effect()
	show()
	next.grab_focus()
	audio_stream_player.play()

func _on_next_pressed():
	GameManager.next_day()


func _on_back_pressed():
	GameManager.back_to_menu(false)
