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

@export_category("Score")
@export var score_container: Control
@export var score: Label

func _ready():
	visibility_changed.connect(func(): _update())
	GameManager.job_quited.connect(func(): _update())
	_update()

func _update():
	if not visible: return
	
	job_container.visible = GameManager.has_current_job()
	day.text = "Day: %s" % GameManager.day
	level.text = "Level: %s" % GameManager.get_level_text()
	documents.text = "Finished Tasks: %s" % GameManager.completed_documents

	skill_container.visible = GameManager.get_wpm() > 0
	wpm.text = "%.0f words/m" % GameManager.get_wpm()
	accuracy.text = "%.0f%% accuracy" % GameManager.get_accuracy()

	score_container.visible = false #GameManager.has_current_job() # disable for now
	score.text = "%.0f" % GameManager.calculate_score()
	
			##var wpm_str = "%.0f/%.0f%%" % [GameManager.average_wpm, GameManager.average_accuracy * 100]
			##var score_str = "%.0f" % GameManager.calculate_score()
			##
			##local_score_label.text = "[center]Current Score: %s with WPM %s, %s %s as %s[/center]" % [
				##_bbcode_outline(score_str),
				##_bbcode_outline(wpm_str),
				##board.get_day_title(),
				##GameManager.day,
				##GameManager.get_level_text(GameManager.difficulty_level)
			##]
