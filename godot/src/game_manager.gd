extends Node

var day = 1

func next_day():
	day += 1
	SceneManager.reload_scene()

func restart():
	day = 1
	SceneManager.reload_scene()
