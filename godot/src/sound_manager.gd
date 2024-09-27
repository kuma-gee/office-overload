extends Node

@onready var button_sound = $ButtonSound
@onready var press_sound = $PressSound
@onready var type_sound = $TypeSound
@onready var type_mistake_sound: DebounceAudio = $TypeMistakeSound


func play_button_sound():
	button_sound.play()
	
func play_press_sound():
	press_sound.play()

func play_type_sound():
	type_sound.play_random_pitched()

func play_type_mistake():
	type_mistake_sound.play_debounce()
