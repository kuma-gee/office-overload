extends Control

@onready var gameover_effect = $GameoverEffect
@onready var finished = $CenterContainer/VBoxContainer/VBoxContainer/Finished
@onready var open = $CenterContainer/VBoxContainer/VBoxContainer/Open
@onready var days = $CenterContainer/VBoxContainer/VBoxContainer/Days
@onready var overtime = $CenterContainer/VBoxContainer/VBoxContainer/Overtime

@export var restart: Button

func _ready():
	hide()

func fired(finished_tasks: int, open_tasks: int, _next_day = false):
	finished.text = "total %s finished tasks" % GameManager.completed
	overtime.text = "total %s hours overtime" % GameManager.total_overtime
	open.text = "%s uncompleted tasks" % open_tasks
	days.text = "Survived %s days" % [GameManager.day - 1]
	_do_show()


func _do_show():
	gameover_effect.do_effect()
	show()
	restart.grab_focus()

func _on_restart_pressed():
	GameManager.restart()


func _on_back_pressed():
	GameManager.back_to_menu()
