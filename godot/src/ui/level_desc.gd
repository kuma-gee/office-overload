class_name LevelDesc
extends Control

signal finished()

@export var feature_title: Label
@export var feature_text: Label
@export var shift_tex: Control
@export var effect: EffectRoot
@export var feature_container: Control

var feature_open := false

func show_for_level(lvl: DifficultyResource.Level, once = false):
	shift_tex.hide()
	feature_container.hide()

	if once:
		if (GameManager.is_junior() and not GameManager.shown_stress_tutorial) or \
			(GameManager.is_senior() and not GameManager.shown_distraction_tutorial) or \
			(GameManager.is_manager() and not GameManager.shown_discard_tutorial) or \
			(GameManager.is_ceo() and not GameManager.shown_ceo_tutorial):
				_show_feature()
		else:
			finished.emit()
	else:
		_show_feature()
	
	match lvl:
		DifficultyResource.Level.JUNIOR:
			feature_title.text = "Stress Level"
			feature_text.text = "As a junior, you have a stress level\nKeep it low to prevent a burnout!"
			GameManager.shown_stress_tutorial = true
		DifficultyResource.Level.SENIOR:
			feature_title.text = "Distractions"
			feature_text.text = "As a senior, you will be distracted by others\nHandle them while keep doing your work!"
			GameManager.shown_distraction_tutorial = true
		DifficultyResource.Level.MANAGER:
			feature_title.text = "Invalid Words"
			feature_text.text = "As a manager, you need to sort out invalid documents\nDiscard them by holding"
			shift_tex.show()
			GameManager.shown_discard_tutorial = true
		DifficultyResource.Level.CEO:
			feature_title.text = "Challenge"
			feature_text.text = "You challenge your boss for the position\nFinish more documents within the time!"
			GameManager.shown_ceo_tutorial = true

	await get_tree().physics_frame
	feature_container.size.y = feature_container.custom_minimum_size.y

func close_feature():
	feature_open = false
	effect.reverse_effect()
	await get_tree().create_timer(0.5).timeout
	finished.emit()

func _show_feature():
	feature_container.show()
	effect.do_effect()
	feature_open = true
	
	# For some reason the container size increases
	#feature_container.size.y = feature_container.custom_minimum_size.y
	#await get_tree().create_timer(0.1).timeout
	#feature_container.size.y = feature_container.custom_minimum_size.y
