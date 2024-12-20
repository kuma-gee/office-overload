class_name Gameover
extends Control

@onready var gameover_effect = $GameoverEffect
@onready var audio_stream_player = $AudioStreamPlayer
@onready var delegator: Delegator = $Delegator
@onready var burnout_paper: PromotionPaper = $BurnoutPaper

@export var restart: TypingButton
@export var menu: TypingButton

@export var title: Label
@export var desc: Label

@export var days: Label
@export var level: Label
@export var speed: Label
@export var acc: Label

func _ready():
	hide()
	
	restart.finished.connect(func(): GameManager.restart())
	menu.finished.connect(func(): GameManager.back_to_menu())

func burnout():
	title.text = "Burned out!"
	desc.text = "You quit your work."
	set_fields()

func fired():
	title.text = "Fired!"
	desc.text = "You didn't finish your tasks on time."
	set_fields()
	
func set_fields():
	level.text = "%s" % GameManager.get_level_text()
	days.text = "%s" % GameManager.day
	speed.text = "%.0f" % GameManager.get_wpm()
	acc.text = "%.0f%%" % GameManager.get_accuracy()
	
	_do_show()
	audio_stream_player.play()

	GameManager.reset_values()
	GameManager.unlock_mode(GameManager.Mode.Interview)

func _do_show():
	gameover_effect.do_effect()
	burnout_paper.open()
	show()

func _unhandled_input(event: InputEvent) -> void:
	delegator.handle_event(event)
