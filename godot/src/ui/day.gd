extends Control

signal finished()

@export var display_time := 1.5

@onready var effect_root = $EffectRoot
@onready var label = $Day/Label

func _ready():
	label.text = "Day %s" % GameManager.day
	effect_root.do_effect()
	await get_tree().create_timer(display_time).timeout
	effect_root.reverse_effect()
	await effect_root.finished
	hide()
	finished.emit()
