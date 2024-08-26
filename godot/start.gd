extends Control

@export var start: TypingButton
@export var setting: TypingButton
@export var exit: TypingButton
@export var settings_panel: FocusedDialog
@export var mode_panel: FocusedDialog

func _ready():
	get_tree().paused = false
	start.finished.connect(func(): mode_panel.grab_focus())
	setting.finished.connect(func(): settings_panel.grab_focus())
	exit.finished.connect(func(): _on_exit_pressed())

func _on_exit_pressed():
	SceneManager.fade_out()
	await SceneManager.fade_complete
	get_tree().quit()
