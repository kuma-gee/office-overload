extends Control

@onready var start = $MarginContainer3/VBoxContainer/Start
@onready var exit = $MarginContainer3/VBoxContainer/Exit

func _ready():
	start.grab_focus()
	
	if not Env.is_web():
		exit.disabled = false

func _on_start_pressed():
	GameManager.start()


func _on_exit_pressed():
	SceneManager.fade_out()
	await SceneManager.fade_complete
	get_tree().quit()
