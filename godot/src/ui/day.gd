class_name Day
extends Control

signal finished()

@export var display_time := 1.5
@export var day_label: Label
@export var level_label: Label

@onready var effect_root = $EffectRoot

func _ready():
	level_label.hide()
	
	if GameManager.is_work_mode():
		day_label.text = "Day %s" % (GameManager.day + 1)
		level_label.text = "%s" % GameManager.get_level_text()
		level_label.show()
	else:
		day_label.text = GameManager.get_mode_title(GameManager.current_mode)

	_show_animation()

func _show_animation():
	effect_root.do_effect()
	await get_tree().create_timer(display_time).timeout
	effect_root.reverse_effect()
	await effect_root.finished
	hide()
	finished.emit()
