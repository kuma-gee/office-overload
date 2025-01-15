extends DocumentUI

@export_category("Job")
@export var job_container: Control
@export var day: Label
@export var level: Label
@export var documents: Label

@export_category("Skill")
@export var skill_container: Control
@export var wpm: Label
@export var accuracy: Label

@export_category("Score")
@export var score_points: Label

func _ready():
	visibility_changed.connect(func(): _update())
	GameManager.job_quited.connect(func(): close())
	_update()
	
	visible = GameManager.has_current_job()

func _update():
	job_container.visible = GameManager.has_current_job()
	day.text = "Day: %s" % GameManager.day
	level.text = "Level: %s" % GameManager.get_level_text()
	#documents.text = "Finished Documents: %s" % GameManager.completed_documents

	skill_container.visible = GameManager.get_wpm() > 0
	wpm.text = "%.0f speed" % GameManager.get_wpm()
	accuracy.text = "%.0f%% accuracy" % GameManager.get_accuracy()
	score_points.text = "%.0f Score" % GameManager.calculate_score()
