extends Control

@export_category("Job")
@export var job_container: Control
@export var day: Label
@export var level: Label
@export var documents: Label

@export_category("Skill")
@export var skill_container: Control
@export var wpm: Label
@export var accuracy: Label

func _ready():
	visibility_changed.connect(func(): _update())
	_update()

func _update():
	if not visible: return
	
	job_container.visible = GameManager.day > 0
	day.text = "Day: %s" % GameManager.day
	level.text = "Level: %s" % DifficultyResource.Level.keys()[GameManager.difficulty_level]
	documents.text = "Finished: %s" % GameManager.completed_documents

	skill_container.visible = GameManager.get_wpm() > 0
	wpm.text = "%.0f words/m" % GameManager.get_wpm()
	accuracy.text = "%s accuracy"
