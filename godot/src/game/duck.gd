class_name Duck
extends GameDeskItem

@export var sound: AudioStreamPlayer

func play():
	if not visible or GameManager.is_crunch_mode(): return
	
	sound.play()
	frame = 1
	await get_tree().create_timer(1.0).timeout
	frame = 0
