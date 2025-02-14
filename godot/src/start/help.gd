extends FocusedDocument

@export var junior_button: TypingButton
@export var senior_button: TypingButton
@export var manager_button: TypingButton
@export var ceo_button: TypingButton
@export var level_desc: LevelDesc

func _ready() -> void:
	super._ready()
	junior_button.visible = GameManager.shown_stress_tutorial
	junior_button.finished.connect(func(): level_desc.show_for_level(DifficultyResource.Level.JUNIOR))

	senior_button.visible = GameManager.shown_distraction_tutorial
	senior_button.finished.connect(func(): level_desc.show_for_level(DifficultyResource.Level.JUNIOR))

	manager_button.visible = GameManager.shown_discard_tutorial
	manager_button.finished.connect(func(): level_desc.show_for_level(DifficultyResource.Level.JUNIOR))

	ceo_button.visible = GameManager.shown_ceo_tutorial
	ceo_button.finished.connect(func(): level_desc.show_for_level(DifficultyResource.Level.JUNIOR))

	hide()
	for c in [junior_button, senior_button, manager_button, ceo_button]:
		if c.visible:
			show()
			break
