extends Control

@export var start: TypingButton
@export var setting: TypingButton
@export var exit: TypingButton

func _ready():
	get_tree().paused = false
	start.finished.connect(func(): _on_start_pressed())
	exit.finished.connect(func(): _on_exit_pressed())

func _on_start_pressed():
	GameManager.start()

func _on_exit_pressed():
	SceneManager.fade_out()
	await SceneManager.fade_complete
	get_tree().quit()
