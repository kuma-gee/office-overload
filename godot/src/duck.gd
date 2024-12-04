class_name Duck
extends Sprite2D

func play():
	if not visible: return
	
	frame = 1
	await get_tree().create_timer(1.0).timeout
	frame = 0
