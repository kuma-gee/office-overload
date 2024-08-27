extends Control

signal finished()

@export var display_time := 1.5

@onready var effect_root = $EffectRoot
@onready var label = $Day/Label

func _ready():
	if GameManager.is_work_mode():
		label.text = "Day %s" % GameManager.day
	elif GameManager.is_crunch_mode():
		label.text = "Crunch Time"
	elif GameManager.is_interview_mode():
		label.text = "Job Interview"

	_show_animation()

func _show_animation():
	effect_root.do_effect()
	await get_tree().create_timer(display_time).timeout
	effect_root.reverse_effect()
	await effect_root.finished
	hide()
	finished.emit()
