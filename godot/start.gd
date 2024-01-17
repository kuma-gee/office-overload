extends Control

@onready var start = $MarginContainer3/VBoxContainer/Start
@onready var exit = $MarginContainer3/VBoxContainer/Exit
@onready var day = $MarginContainer4/Day

func _ready():
	day.visible = GameManager.day > 0
	day.text = "Day %s" % GameManager.day
	
	start.text = "Start Work" if GameManager.day <= 0 else "Start next day"
	start.grab_focus()
	
	if not Env.is_web():
		exit.disabled = false

func _on_start_pressed():
	GameManager.start()


func _on_exit_pressed():
	SceneManager.fade_out()
	await SceneManager.fade_complete
	get_tree().quit()
