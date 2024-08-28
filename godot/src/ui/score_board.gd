class_name ScoreBoard
extends Control

@export var keys: Array[String] = []
@export var container: Control

func show_data(data: Array[Dictionary]):
	for d in data:
		for k in keys:
			var label = Label.new()
			label.text = "%s" % d.get(k, "")

			if k == "time":
				label.text += "s"

			container.add_child(label)
