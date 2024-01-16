extends Control

@onready var end_effect = $EndEffect
@onready var finished_tasks = $CenterContainer/VBoxContainer/VBoxContainer/FinishedTasks
@onready var overtime = $CenterContainer/VBoxContainer/VBoxContainer/Overtime
@onready var next = $CenterContainer/VBoxContainer/VBoxContainer/Next

func _ready():
	hide()

func day_ended(finished: int, overtime_in_hours: float):
	finished_tasks.text = "Finished %s tasks" % finished
	overtime.text = "%s hours of overtime" % overtime_in_hours
	
	end_effect.do_effect()
	show()
	get_tree().paused = true
	next.grab_focus()

func _on_next_pressed():
	GameManager.next_day()
