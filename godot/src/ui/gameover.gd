extends Control

@onready var gameover_effect = $GameoverEffect
@onready var finished = $CenterContainer/VBoxContainer/VBoxContainer/Finished
@onready var open = $CenterContainer/VBoxContainer/VBoxContainer/Open
@onready var days = $CenterContainer/VBoxContainer/VBoxContainer/Days
@onready var overtime = $CenterContainer/VBoxContainer/VBoxContainer/Overtime
@onready var audio_stream_player = $AudioStreamPlayer

@export var restart: TypingButton
@export var menu: TypingButton

func _ready():
	hide()
	
	restart.finished.connect(func(): GameManager.restart())
	menu.finished.connect(func(): GameManager.back_to_menu())

func fired(finished_tasks: int, open_tasks: int, _next_day = false):
	get_tree().paused = true
	finished.text = "total %s finished tasks" % finished_tasks
	
	overtime.visible = GameManager.total_overtime > 0
	overtime.text = "total %s hours overtime" % GameManager.total_overtime
	
	open.text = "%s uncompleted tasks" % open_tasks
	days.text = "Survived %s days" % [GameManager.day - 1]
	_do_show()
	audio_stream_player.play()

	GameManager.reset_values()

func _do_show():
	gameover_effect.do_effect()
	show()
	# restart.grab_focus()
