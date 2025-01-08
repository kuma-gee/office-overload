class_name Gameover
extends Control

@onready var gameover_effect = $GameoverEffect
@onready var audio_stream_player = $AudioStreamPlayer
@onready var delegator: Delegator = $Delegator
@onready var burnout_paper: EndPaper = $BurnoutPaper

@export var restart: TypingButton
@export var menu: TypingButton
@export var ceo_quit: TypingButton
@export var ceo_keep: TypingButton

@export var default_options: Control
@export var ceo_options: Control

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
	ceo_quit.finished.connect(func():
		GameManager.reset_values()
		_show_default_options()
	)
	ceo_keep.finished.connect(func():
		restart.word = "restart"
		restart.update()
		_show_default_options()
	)

func _show_default_options():
	ceo_options.hide()
	default_options.show()

func _show_ceo_options():
	ceo_options.show()
	default_options.hide()

func burnout():
	title.text = "Burned out!"
	desc.text = "You quit your work."
	set_fields()

func fired():
	title.text = "Fired!"
	desc.text = "You didn't finish your\ntasks on time."
	set_fields()
	
func set_fields():
	level.text = "%s" % GameManager.get_level_text()
	days.text = "%s" % GameManager.day
	speed.text = "%.0f" % GameManager.get_wpm()
	acc.text = "%.0f%%" % GameManager.get_accuracy()

	if GameManager.finished_game:
		desc.text = "You are the ceo.\nDo you really want to quit?"
		_show_ceo_options()
	else:
		GameManager.reset_values()
		_show_default_options()
	
	_do_show()
	audio_stream_player.play()

func _do_show():
	gameover_effect.do_effect()
	burnout_paper.open()
	show()

func _unhandled_input(event: InputEvent) -> void:
	delegator.handle_event(event)
