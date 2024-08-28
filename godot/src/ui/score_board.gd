class_name ScoreBoard
extends Control

const TEXT_OUTLINE = preload("res://theme/text_outline.tres")

@export var keys: Array[String] = []
@export var container: Control

func show_data(data: Array[Dictionary]):
	for d in data:
		for k in keys:
			var label = Label.new()
			label.text = "%s" % d.get(k, "")

			if "name" in d and d["name"] == "You":
				label.label_settings = TEXT_OUTLINE

			if k == "time":
				label.text += "s"

			container.add_child(label)
