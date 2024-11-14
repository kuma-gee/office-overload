class_name Papers
extends Control

func _ready() -> void:
	for c in get_children():
		c.show()

func close():
	for c in get_children():
		c.close()
		
func open():
	for c in get_children():
		c.open()
