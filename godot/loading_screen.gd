extends Control

func _ready() -> void:
	if GameManager.init:
		start_game()
	else:
		GameManager.initialized.connect(func(): start_game())

func start_game():
	SceneManager.change_scene("res://start.tscn")
