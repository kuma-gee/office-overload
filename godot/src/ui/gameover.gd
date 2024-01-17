extends Control

@onready var gameover_effect = $GameoverEffect
@onready var finished = $CenterContainer/VBoxContainer/VBoxContainer/Finished
@onready var open = $CenterContainer/VBoxContainer/VBoxContainer/Open
@onready var days = $CenterContainer/VBoxContainer/VBoxContainer/Days
@onready var unfinished_next_day = $CenterContainer/VBoxContainer/VBoxContainer/UnfinishedNextDay

@export var restart: Button

func _ready():
	hide()

func fired(finished_tasks: int, open_tasks: int, next_day = false):
	unfinished_next_day.visible = false
	GameManager.finished_day(finished_tasks, 0)
	
	finished.text = "finished in total %s tasks" % GameManager.completed
	open.text = "%s uncompleted tasks" % open_tasks
	days.text = "Survived %s days" % [GameManager.day - 1]
	_do_show()


func _do_show():
	gameover_effect.do_effect()
	show()
	get_tree().paused = true
	restart.grab_focus()

func _on_restart_pressed():
	GameManager.restart()


func _on_back_pressed():
	GameManager.back_to_menu()
