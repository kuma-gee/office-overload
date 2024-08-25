extends Node

@onready var button_sound = $ButtonSound
@onready var press_sound = $PressSound
@onready var type_sound = $TypeSound


func play_button_sound():
	button_sound.play()
	
func play_press_sound():
	press_sound.play()

func play_type_sound():
	type_sound.play()
