extends Control

@onready var gameover_effect = $GameoverEffect
@onready var audio_stream_player = $AudioStreamPlayer

@export var restart: TypingButton
@export var menu: TypingButton

@export var finished: Label
@export var days: Label
@export var overtime: Label

func _ready():
	hide()
	
	restart.finished.connect(func(): GameManager.restart())
	menu.finished.connect(func(): GameManager.back_to_menu())

func fired():
	get_tree().paused = true
	finished.text = "total %s finished tasks" % GameManager.completed_documents
	
	overtime.visible = GameManager.total_overtime > 0
	overtime.text = "total %s hours overtime" % GameManager.total_overtime
	days.text = "Survived %s days" % [GameManager.day - 1]
	
	_do_show()
	audio_stream_player.play()

	GameManager.reset_values()
	GameManager.unlock_mode(GameManager.Mode.Interview)

func _do_show():
	gameover_effect.do_effect()
	show()
