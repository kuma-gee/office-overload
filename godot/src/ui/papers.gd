class_name Papers
extends Control

func close():
	for c in get_children():
		c.close()
		
func open():
	for c in get_children():
		c.open()
