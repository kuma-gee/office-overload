class_name Day
extends Control

signal finished()

@export var display_time := 1.5
@export var day_label: Label
@export var level_label: Label

@export var feature_container: Control
@export var feature_title: Label
@export var feature_text: Label
@export var shift_tex: TextureRect

@onready var effect_root = $EffectRoot
@onready var feature_effect: EffectRoot = $FeatureEffect

var tw: Tween

func _ready():
	level_label.hide()
	shift_tex.hide()
	feature_container.hide()
	
	if not GameManager.is_work_mode():
		_start_day()
		return
	
	if GameManager.is_junior() and not GameManager.shown_stress_tutorial:
		feature_title.text = "Stress Level"
		feature_text.text = "As a junior, you have a stress level\nKeep it low to prevent a burnout!"
		GameManager.shown_stress_tutorial = true
		_show_feature()
	elif GameManager.is_senior() and not GameManager.shown_distraction_tutorial:
		feature_title.text = "Distractions"
		feature_text.text = "As a senior, you will be distracted by others\nHandle them while keep doing your work!"
		GameManager.shown_distraction_tutorial = true
		_show_feature()
	elif GameManager.is_manager() and not GameManager.shown_discard_tutorial:
		feature_title.text = "Invalid Words"
		feature_text.text = "As a manager, you need to sort out invalid documents\nDiscard them by holding"
		shift_tex.show()
		GameManager.shown_discard_tutorial = true
		_show_feature()
	elif GameManager.is_ceo() and not GameManager.shown_ceo_tutorial:
		feature_title.text = "Challenge"
		feature_text.text = "You challenge your boss for the position\nFinish more documents within the time!"
		GameManager.shown_ceo_tutorial = true
		_show_feature()
	else:
		_start_day()

func close_feature():
	feature_effect.reverse_effect()
	await get_tree().create_timer(0.5).timeout
	_start_day()

func is_feature_open():
	return feature_container.visible

func _process(delta: float) -> void:
	feature_container.size.y = 180 # the size gets a weird value when running the game

func _show_feature():
	feature_container.show()
	feature_effect.do_effect()

func _start_day():
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
