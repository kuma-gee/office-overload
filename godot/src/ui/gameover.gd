extends Control

@onready var gameover_effect = $GameoverEffect
@onready var finished = $CenterContainer/VBoxContainer/VBoxContainer/Finished
@onready var open = $CenterContainer/VBoxContainer/VBoxContainer/Open
@onready var days = $CenterContainer/VBoxContainer/VBoxContainer/Days
@onready var restart = $CenterContainer/VBoxContainer/VBoxContainer/Restart

func _ready():
	hide()

func fired(finished_tasks: int, open_tasks: int):
	finished.text = "finished %s tasks" % finished_tasks
	open.text = "%s uncompleted tasks" % open_tasks
	days.text = "Survived %s days" % [GameManager.day - 1]
	_do_show()

func fired_next_day(open_tasks: int):
	finished.text = "Didn't finish tasks until next day"
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
